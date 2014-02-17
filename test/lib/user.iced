
#
# A file that wraps the creation and management of test
# users, potentially with features to access test twitter 
# and github accounts. As such, it might need access to
# a configuration file, since we don't want to push our
# test twitter/github credentials to github.
#

{prng} = require 'crypto'
{init,config} = require './config'
path = require 'path'
iutils = require 'iced-utils'
{rm_r,mkdir_p} = iutils.fs
{a_json_parse,athrow} = iutils.util
{make_esc} = require 'iced-error'
log = require '../../lib/log'
gpgw = require 'gpg-wrapper'
{AltKeyRing} = gpgw.keyring
{run} = require 'iced-spawn'
keypool = require './keypool'
{Engine} = require 'iced-expect'
{tweet_api} = require './twitter'
{gist_api} = require './github'
fs = require 'fs'
{Rendezvous} = require('iced-coffee-script').iced

#==================================================================

strip = (x) -> if (m = x.match /^(\s*)([\S\s]*?)(\s*)$/) then m[2] else x

#==================================================================

randhex = (len) -> prng(len).toString('hex')

#==================================================================

assert_kb_ok = (rc) ->
  if rc is 0 then null
  else new Error "Non-ok result from keybase: #{rc}"

#==================================================================

exports.User = class User

  constructor : ({@username, @email, @password, @homedir}) ->
    @keyring = null
    @_state = { proved : {} }
    @_proofs = {}
    users().push @

  #---------------

  @generate : (base) -> 
    base or= randhex(3)
    opts =
      username : "test_#{base}"
      password : randhex(6)
      email    : "test+#{base}@test.keybase.io"
      homedir  : path.join(config().scratch_dir(), "home_#{base}")
    new User opts

  #-----------------

  check_if_exists : (cb) ->
    tmpcb = (err) -> cb false
    esc = make_esc tmpcb, "User::check_if_exists"
    await fs.stat @homedir, esc defer()
    await fs.stat @keyring_dir(), esc defer()
    await fs.stat path.join(@homedir, ".keybase", "config.json"), esc defer()
    cb true

  #-----------------

  init : (cb) ->
    esc = make_esc cb, "User::init"
    await @make_homedir esc defer()
    await @make_keyring esc defer()
    await @grab_key esc defer()
    await @write_config esc defer()
    @_state.init = true
    cb null

  #-----------------

  write_config : (cb) ->
    esc = make_esc cb, "User::write_config"
    await @keybase { args : [ "config" ], quiet : true }, esc defer()  
    args = [
      "config"
      "--json"
      "server"
      JSON.stringify(config().server_obj())
    ]
    await @keybase { args, quiet : true }, esc defer()
    cb null

  #-----------------

  make_homedir : (cb) ->
    await mkdir_p @homedir, null, defer err
    cb err

  #-----------------

  keyring_dir : () -> path.join(@homedir, ".gnupg")

  #-----------------

  _keybase_cmd : (inargs) -> 
    inargs.args = [ "--homedir", @homedir ].concat inargs.args
    config().keybase_cmd inargs
    log.debug "Running keybase: " + JSON.stringify(inargs)
    return inargs

  #-----------------

  keybase : (inargs, cb) ->
    @_keybase_cmd inargs
    await run inargs, defer err, out
    cb err, out

  #-----------------

  keybase_expect : (args) ->
    inargs = { args, opts : {} }
    if config().debug
      inargs.opts = 
        debug : { stdout : true } 
        passthrough : { stderr : true }
    @_keybase_cmd inargs
    eng = new Engine inargs
    eng.run()
    return eng

  #-----------------

  make_keyring : (cb) ->
    await AltKeyRing.make @keyring_dir(), defer err, @keyring
    cb err

  #-----------------

  gpg : (args, cb) -> @keyring.gpg args, cb

  #-----------------

  grab_key : (cb) ->
    esc = make_esc cb, "User::grab_key"
    await keypool.grab esc defer tmp
    await tmp.load esc defer()
    @key = tmp.copy_to_keyring @keyring
    await @key.save esc defer()
    cb null

  #-----------------

  push_key : (cb) ->
    await @keybase { args : [ "push", @key.fingerprint() ], quiet : true }, defer err
    @_state.pushed = true unless err?
    cb err

  #-----------------

  signup : (cb) ->
    eng = @keybase_expect [ "signup" ]
    await eng.conversation [
        { expect : "Your email: "}
        { sendline : @email }
        { expect : "Invitation code \\(leave blank if you don't have one\\): " }
        { sendline : "202020202020202020202020" }
        { expect : "Your desired username: " }
        { sendline : @username }
        { expect : "Your passphrase: " }
        { sendline : @password }
        { expect : "confirm passphrase: " }
        { sendline : @password },
      ], defer err
    unless err?
      await eng.wait defer rc
      if rc isnt 0
        err = new Error "Command-line client failed with code #{rc}"
      else
        @_state.signedup = true
    cb err

  #-----------------

  prove : ({which, search_regex, http_action}, cb) ->
    esc = make_esc cb, "User::prove"
    eng = @keybase_expect [ "prove", which ]
    @twitter = {}
    unless (acct = config().get_dummy_account which)?
      await athrow (new Error "No dummy accounts available for '#{which}'"), esc defer()
    await eng.expect { pattern : (new RegExp "Your username on #{which}: ", "i") }, esc defer()
    await eng.sendline acct.username, esc defer()
    await eng.expect { pattern : (new RegExp "Check #{which} now\\? \\[Y/n\\] ", "i") }, esc defer data
    if (m = data.toString('utf8').match search_regex)?
      proof = m[1]
    else
      await athrow (new Error "Didn't get a #{which} text from the CLI"), esc defer()
    log.debug "+ Doing HTTP action #{acct.username}@#{which}"
    await http_action acct, proof, esc defer proof_id
    log.debug "- Did HTTP action, completed w/ proof_id=#{proof_id}"
    await eng.sendline "y", esc defer()

    eng.expect { 
      repeat : true,
      pattern : (new RegExp "Check #{which} again now\\? \\[Y/n\\] ", "i") 
    }, (err, data, source) =>
      log.info "Trying #{which} again, maybe they're slow to update?"
      await setTimeout defer(), 1000
      await eng.sendline "y", defer err
      log.warn "Failed to send a yes: #{err.message}" if err?

    await eng.wait defer rc
    if rc isnt 0
      err = new Error "Error from keybase prove: #{rc}"
    else 
      @_proofs[which] = { proof, proof_id, acct }
      @_state.proved[which] = true
    cb err

  #-----------------

  accounts : () ->
    unless (out = @_status?.user?.proofs)?
      out = {}
      for k,v of @_proofs
        out[k] = v.acct.username
    return out

  #-----------------

  # Load proofs in from the output of `keybase status`
  _load_proofs : (obj) ->
    if (d = obj?.user?.proofs)?
      for k,v of d
        @_proofs[k] = { acct : { username : v } }

  #-----------------

  assertions : () ->
    d = @accounts()
    out = []
    for k,v of d
      out.push("--assert", [k, v].join(":") )
    return out

  #-----------------

  prove_twitter : (cb) ->
    opts = 
      which : "twitter"
      search_regex : /Please tweet the following:\s+(\S.*?)\n/
      http_action : tweet_api
    await @prove opts, defer err
    cb err

  #-----------------

  prove_github : (cb) ->
    opts = 
      which : "github"
      search_regex : /Please post a Gist with the following:\s+(\S[\s\S]*?)\n\nCheck GitHub now\?/i
      http_action : gist_api
    await @prove opts, defer err
    cb err

  #-----------------

  has_live_key : () -> @_state.pushed and @_state.signedup and not(@_state.revoked)

  #-----------------

  full_monty : (T, {twitter, github, save_pw}, gcb) ->
    un = @username
    esc = (which, lcb) -> (err, args...) ->
      T.waypoint "fully_monty #{un}: #{which}"
      T.no_error err
      if err? then gcb err
      else lcb args...
    await @init esc('init', defer())
    await @signup esc('signup', defer())
    await @push_key esc('push_key', defer())
    await @prove_github esc('prove_github', defer()) if twitter
    await @prove_twitter esc('prove_twitter', defer()) if github
    await @write_pw esc('write_pw', defer()) if save_pw
    gcb null

  #-----------------

  check_proofs : (output, cb) ->
    err = null
    for k,v of @_proofs
      x = new RegExp "#{v.acct.username}.*#{k}.*https://.*#{k}\\.com/.*#{v.proof_id}"
      unless output.match x
        err = new Error "Failed to find proof for #{k} for user: #{v.acct.username}"
        break
    cb err

  #-----------------

  follow : (followee, {remote}, cb) ->
    esc = make_esc cb, "User::follow"
    un = followee.username
    eng = @keybase_expect [ "track", un ]

    eng.expect { pattern : new RegExp("Is this the #{un} you wanted\\? \\[y\\/N\\] ") }, (err, data, src) ->
      unless err?
        await followee.check_proofs eng.stderr().toString('utf8'), defer err
        if err?
          log.warn "Failed to find the correct proofs"
          await eng.sendline "n", defer err
        else
          await eng.sendline "y", defer err

    eng.expect { pattern : /Permanently track this user, and write proof to server\? \[Y\/n\] / }, (err, data, src) ->
      unless err?
        await eng.sendline (if remote then "y" else "n"), esc defer()

    await eng.wait defer rc
    err = assert_kb_ok rc
    cb err

  #-----------------

  unfollow : (followee, cb) ->
    esc = make_esc cb, "User::follow"
    eng = @keybase_expect [ "untrack", "--remove-key", followee.username ]
    await eng.wait defer rc
    err = assert_kb_ok rc
    cb err

  #-----------------

  write_pw : (cb) ->
    esc = make_esc cb, "User::write_pw"
    await @keybase { args : [ "config" ], quiet : true }, esc defer()  
    args = [
      "config"
      "user.passphrase"
      @password
    ]
    await @keybase { args, quiet : true }, esc defer()
    cb null

  #-----------------

  logout : (cb) ->
    await @keybase { args : [ "logout"], quiet : true }, defer err
    cb err

  #-----------------

  login : (cb) ->
    await @keybase { args : [ "login"], quiet : true }, defer err
    cb err

  #----------

  cleanup : (cb) ->
    await @revoke_key defer e1
    await @rm_homedir defer e2
    err = e1 or e2
    cb err

  #----------

  rm_homedir : (cb) ->
    await rm_r @homedir, defer err
    cb err

  #-----------------

  revoke_key : (cb) ->
    err = null
    if config().preserve
      log.warn "Not deleting key / preserving due to command-line flag"
    else
      await @keybase { args : [ "revoke", "--force" ], quiet : true }, defer err
      @_state.revoked = true unless err?
    cb err

  #-----------------

  load_status : (cb) ->
    esc = make_esc cb, "User::load_status"
    await @keybase { args : [ "status"] }, esc defer out 
    await a_json_parse out, esc defer json
    @_status = json
    cb null

#==================================================================

class Users

  constructor : () -> 
    @_list = [] 
    @_lookup = {}

  push : (u) ->
    @_list.push u
    @_lookup[u.username] = u
  
  lookup : (u) -> @_lookup[u]

  get : (i) -> @_list[i]

  cleanup : (cb) ->
    err = null
    for u in @_list when u.has_live_key()
      await u.cleanup defer tmp
      if tmp?
        log.error "Error cleaning up user #{u.username}: #{tmp.message}"
        err = tmp
    cb err

#==================================================================

_users = new Users
exports.users = users = () -> _users

#==================================================================
