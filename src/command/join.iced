{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{Prompter} = require '../prompter'
{checkers} = require '../checkers'
{make_esc} = require 'iced-error'
triplesec = require 'triplesec'
{rng} = require 'crypto'
{constants} = require '../constants'
SC = constants.security
ProgressBar = require 'progress'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "signup" ]
    name = "join"
    sub = scp.addParser name, opts
    opts.aliases.concat [ name ]

  #----------

  prompt : (cb) ->
    seq =
      username : 
        prompt : "Your desired username"
        checker : checkers.username
      passphrase: 
        prompt : "Your passphrase"
        passphrase: true
        checker: checkers.passphrase
        confirm : 
          prompt : "confirm passphrase"
      email :
        prompt : "Your email"
        checker : checkers.email
      invite:
        prompt : "Invitation code"
        checker : checkers.invite_code

    p = new Prompter seq
    await p.run defer err
    @data = p.data() unless err?
    cb err

  #----------

  gen_pwh : (cb) ->
    console.log @data
    @enc = new triplesec.Encryptor { 
      key : new Buffer(@data.passphrase, 'utf8')
      verion : SC.triplesec.version
    }

    bar = null
    prev = 0
    progress_hook = (obj) ->
      if obj.what isnt "scrypt" then #noop
      else 
        bar or= new ProgressBar "Scrypt [:bar] :percent", { width : 35, total : obj.total }
        bar.tick(obj.i - prev)
        prev = obj.i

    extra_keymaterial = SC.pwh.derived_key_bytes + SC.openpgp.derived_key_bytes
    await @enc.resalt { extra_keymaterial, progress_hook }, defer err, km
    unless err?
      @salt = @enc.salt
      @pwh = km.extra[0...SC.pwh.derived_key_bytes]
      console.log @salt
      console.log @pwh
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Join::run"
    await @prompt esc defer()
    await @gen_pwh esc defer()
    console.log @data
    cb null

##=======================================================================

