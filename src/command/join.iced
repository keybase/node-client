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
      password : 
        prompt : "Your passphrase"
        password : true
        checker: checkers.password
        confirm : 
          prompt : "confirm passphrase"
      email :
        prompt : "Your email"
        checker : checkers.email

    p = new Prompter seq
    await p.run defer err
    @data = p.data() unless err?
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Join::run"
    await @prompt esc defer()
    console.log @data
    cb null

##=======================================================================

