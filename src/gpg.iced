
{spawn} = require 'child_process'
stream = require './stream'
log = require './log'
{E} = require './err'

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
  if stdin and Buffer.isBuffer stdin
    stdin = new stream.BufferInStream stdin
  if not stdout?
    def_out = true
    stdout = new stream.BufferOutStream()
  else
    def_out = false
  await (new Engine { args, stdin, stdout, stderr }).run().wait defer rc
  err = if rc is 0 then null else new E.GpgError "exit code #{rc}"
  out = if def_out? then stdout.data() else null
  cb err, out

##=======================================================================
