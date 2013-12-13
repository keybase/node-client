
{spawn} = require 'child_process'
stream = require './stream'
log = require './log'

##=======================================================================

class Engine

  constructor : ({@args, @stdin, @stdout, @stderr}) ->

    # XXX make this configurable
    @name = "gpg"

    @stderr or= new stream.FnOutStream(log.warn)
    @stdin or= new stream.NullInStream()
    @stdout or= new stream.NullOutStream()

    @_exit_code = null
    @_exit_cb = null

  run : () ->
    @proc = spawn @name, @args
    @stdin.pipe @proc.stdin
    @proc.stdout.pipe @stdout
    @proc.stderr.pipe @stderr
    @pid = @proc.pid
    @proc.on 'exit', (status) => @_got_exit status
    @

  _got_exit : (status) ->
    @_exit_code = status
    @proc = null
    if (ecb = @_exit_cb)?
      @_exit_cb = null
      ecb status
    @pid = -1

  wait : (cb) ->
    if @_exit_code then cb @_exit_code
    else @_exit_cb = cb

##=======================================================================

exports.gpg = gpg = ({args, stdin, stdout, stderr}, cb) ->
  await (new Engine { args, stdin, stdout, stderr }).run().wait defer rc
  cb rc

##=======================================================================
