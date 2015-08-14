
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
{Engine} = require 'iced-expect'
{tweet_api} = require './twitter'
{gist_api} = require './github'
fs = require 'fs'
{Rendezvous} = require('iced-coffee-script').iced
kbpgp = require 'kbpgp'
{base32} = require '../../lib/basex'

#==================================================================

strip = (x) -> if (m = x.match /^(\s*)([\S\s]*?)(\s*)$/) then m[2] else x

#==================================================================

randhex = (len) -> prng(len).toString('hex')
rand_b32 = (len) -> base32.encode prng len

#==================================================================

assert_kb_ok = (rc) ->
  if rc is 0 then null
  else new Error "Non-ok result from keybase: #{rc}"

#==================================================================

exports.User = User = class User

  constructor : ({@username, @email, @password, @homedir}) ->
    @keyring = null
    @_state = { proved : {} }
    @_proofs = {}
    users().push @

  #---------------

  @homedir : (x) -> path.join(config().scratch_dir(), "home_#{x}")

  #---------------

  @generate : (base) ->
    suffix = rand_b32 4
    base or= randhex(3)
    username = base + "_" + suffix
    opts =
      username : username
      password : randhex(6)
      email    : "test+#{username}@test.keybase.io"
      homedir  : User.homedir base
    new User opts

  #-----------------

  @load_many : ( {names, res}, cb) ->
    err = null
    for name in names
      await User.load name, defer err, user
      if err?
        err = new Error "Cannot load user #{name}: #{err.toString()}"
        break
      res[name] = user
    cb err

  #-----------------

  @load : (base, cb) ->
    u = new User { homedir : User.homedir(base) }
    await u.load_user defer err
    if err? then u = null
    else
      await u.load_status defer err
      u = null if err?
    cb err, u

  #-----------------

  @load_or_gen : (base, cb) ->
    await User.load base, defer err, u
    u = User.generate base if err?
    cb u, err?

  #-----------------

  load_user : (cb) ->
    err = null
    esc = make_esc cb, "User::check_if_exists"
    await fs.stat @homedir, esc defer()
    await fs.stat @keyring_dir(), esc defer()
    await fs.readFile path.join(@homedir, ".config", "keybase", "config.json"), esc defer file
    await a_json_parse file, esc defer @config
    unless (@username = @config?.user?.name)?
      err = new Error "half-baked user; no valid name in configuration file"
    cb err

  #-----------------

  init : (cb) ->
    esc = make_esc cb, "User::init"
    await @make_homedir esc defer()
    await @make_keyring esc defer()
    await @gen_key esc defer()
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

  gen_key : (cb) ->
    esc = make_esc cb, "User::gen_key"
    F = kbpgp.const.openpgp.key_flags
    nbits = 1024
    args = {
      primary : {
        flags : F.certify_keys | F.sign_data | F.auth
        nbits : nbits
      }
      subkeys : [{
        flags : F.encrypt_comm | F.encrypt_stroage
        nbits : nbits
      }]
      userid : "#{@username} <#{@email}>"
    }
    await kbpgp.KeyManager.generate args, esc defer km
    await km.sign {}, esc defer()
    await km.export_pgp_private {}, esc defer key_data
    @key = @keyring.make_key { key_data, secret : true, fingerprint : km.get_pgp_fingerprint_str() }
    await @key.save esc defer()
    cb null

  #-----------------

  push_key : (cb) ->
    await @keybase { args : [ "push", "--skip-add-email", @key.fingerprint() ], quiet : true }, defer err
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
        { expect : "Your login passphrase: " }
        { sendline : @password }
        { expect : "Repeat to confirm: " }
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
    out.push "--assert"
    out.push ( [k,v].join("://") for k,v of d ).join(" && ")
    return out

  #-----------------

  prove_twitter : (cb) ->
    opts =
      which : "twitter"
      search_regex : /Please.*tweet.*the following:\s+(\S.*?)\n/
      http_action : tweet_api
    await @prove opts, defer err
    cb err

  #-----------------

  prove_github : (cb) ->
    opts =
      which : "github"
      search_regex : /Please.*?post the following Gist, and name it.*?:\s+(\S[\s\S]*?)\n\nCheck GitHub now\?/i
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
    await @list_signatures esc('list_signatures', defer())
    await @prove_github esc('prove_github', defer()) if github
    await @prove_twitter esc('prove_twitter', defer()) if twitter
    await @list_signatures esc('list_signatures', defer())
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

  id : (followee, cb) ->
    esc = make_esc cb, "User::id"
    un = followee.username
    eng = @keybase_expect [ "id", un ]
    await eng.wait defer rc
    err = assert_kb_ok rc
    await athrow err, esc defer() if err?
    stderr = eng.stderr().toString('utf8')
    await followee.check_proofs stderr, defer err
    if err?
      log.warn "Failed to find the correct proofs; got: "
      log.warn stderr
    cb err

  #-----------------

  list_signatures : (cb) ->
    esc = make_esc cb, "User::list_signatures"
    eng = @keybase_expect [ "list-signatures" ]
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
      await @keybase { args : [ "remove-key", "--force" ], quiet : true }, defer err
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

  lookup_or_gen : (u) ->
    unless (ret = @_lookup[u])?
      @_lookup[u] = ret = User.generate u
    return ret

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

exports.signup = (T, name, args, cb) ->
  await User.load_or_gen name, defer u, is_new
  T.assert u, "#{name} was generated"
  if not is_new
    log.info "#{name} found; not remaking them"
    await u.login defer err
    T.no_error err
    await u.load_status defer err
    T.no_error err
  else
    log.info "#{name} not found; remaking them "
    await u.full_monty T, args, defer err
    T.no_error err
  cb u
