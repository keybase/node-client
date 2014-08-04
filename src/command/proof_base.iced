{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn,prompt_remote_name} = require '../prompter'
{User} = require '../user'
{req} = require '../req'
assert = require 'assert'
session = require '../session'
S = require '../services'

##=======================================================================

exports.ProofBase = class Command extends Base

  #----------

  constructor : (args...) ->
    super args...
    @supersede = false

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  @OPTS :
    f : 
      alias : 'force'
      action : 'storeTrue'
      help : "don't stop for any prompts"

  #----------

  add_subcommand_parser : (scp) ->
    {name,config,OPTS} = @command_name_and_opts()
    sub = scp.addParser name, config
    add_option_dict sub, OPTS
    sub.addArgument [ "service" ], { nargs : 1, help: "the name of service; can be one of: {twitter,github,web,dns,reddit,coinbase,hackernews}" }
    sub.addArgument [ "remote_name"], { nargs : "?", help : "username or hostname at that service" }
    return config.aliases.concat [ name ]

  #----------

  prompt_remote_name : (cb) ->
    svc = @argv.service[0]
    err = null
    ret = null
    if not @remote_name?
      await prompt_remote_name @stub.prompter(), defer err, ret
      @remote_name = ret unless err?
    cb err, ret

  #----------

  normalize_remote_name : (cb) -> 
    await @stub.normalize_name @remote_name, defer err, @remote_name_normalized
    cb err

  #----------

  allocate_proof_gen : (cb) ->
    klass = S.classes[@service_name]
    assert.ok klass?
    await @me.gen_remote_proof_gen { @klass, @remote_name_normalized, @supersede }, defer err, @gen
    cb err

  #----------

  parse_args : (cb) ->
    err = null
    if (s = S.aliases[@argv.service[0].toLowerCase()])?
      @service_name = s
      @klass = S.classes[s]
      assert.ok @klass?
      @stub = new @klass {}
    else
      err = new E.UnknownServiceError "Unknown service: #{@argv.service[0]}"

    if not err? and (@remote_name = @argv.remote_name)? and not @stub.check_name_input(@remote_name)
      err = new E.ArgsError "Bad name #{@argv.service[0]} given: #{@remote_name}"
    cb err

##=======================================================================

