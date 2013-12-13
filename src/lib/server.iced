
rpc = require 'framed-msgpack-rpc'
fs = require 'fs'
{ExitHandler} = require './exit'
{constants} = require './constants'
log = require './log'
{JobStatus,Downloader} = require './downloader'
aws = require './aws'
{E} = require './err'

#=========================================================================

rpc.pack.use_byte_arrays()

#=========================================================================

exports.Server = class Server extends rpc.SimpleServer

  constructor : ({@cmd}) ->
    super { path : @cmd.config.sockfile() }
    @launcher = new JobLauncher { @cmd, server : @ }

  get_program_name : () -> constants.PROT

  listen : (cb) ->
    await super defer err
    unless err?
      @eh = new ExitHandler { config : @cmd.config } 
      @launcher.start()
    cb err

  h_ping : (arg, res) -> res.result { rc : E.OK }

  h_download : (arg, res) ->
    await @launcher.incoming_job arg, defer rc
    res.result { rc }

  run : (cb) ->
    @eh.call_on_exit cb

#=========================================================================

class Queue 

  constructor : ({@launcher, @lim}) ->
    @n = 0
    @_q = []

  enqueue : (obj) ->
    if @n < @lim then @_launch_one obj
    else 
      log.info "|> Queueing job, since #{@n}>=#{@lim} outstanding: #{obj.toString()}"
      @_q.push obj

  _launch_one : (obj, out) ->
    @n++
    log.info "+> Launching download job: #{obj.toString()}"
    await obj.run defer()
    log.info "-> Completed download job: #{obj.toString()}"
    @launcher.completed obj
    @n--
    @done()

  _done : () ->
    room = @lim - @n
    if room and @_q.length
      objs = @_q[0...room]
      @_q = @_q[room...]
      for o in objs
        @_launch_one o

#=========================================================================

class JobLauncher

  #-------------

  constructor : ({@cmd, @server}) ->
    @filenames = {}
    @jobids = {}
    @n_waiting_jobs = 0
    @q = new Queue { lim : 3, launcher : @ }

  #-------------

  polling_loop : () ->
    loop
      which = if (@n_waiting_jobs > 0) then "active" else "passive"
      iv = constants.poll_intervals[which]
      await setTimeout defer(), iv*1000 
      log.info "+> polling SQS (after #{iv}s sleep)"
      await @poll defer()
      log.info "-> polled SQS"

  #-------------

  process_message : (m, cb) ->
    try
      body = JSON.parse m.Body
      msg = JSON.parse body.Message
      if msg.Action isnt "ArchiveRetrieval"
        err = "not a retrieval"
      else if not (jid = msg.JobId)?
        err = "missing job ID"
      else if (sc = JobStatus.from_string(msg.StatusCode)) isnt JobStatus.SUCCEEDED
        err = "job failed"
      else if not (dl = @jobids[jid])?
        err = "Job not found"
    catch e
      err = "mangled JSON"

    if err?
      log.error "Skipping job: #{err}: #{JSON.stringify m}"
    else if dl?
      dl.job.status = sc
      log.info "|> Job is now ready: #{dl.toString()}"
      @start_download dl

    if (rh = m.ReceiptHandle)?
      arg = 
        QueueUrl : @sqs.url
        ReceiptHandle : rh
      await @cmd.aws.sqs.deleteMessage arg, defer err
      if err?
        log.error "Error in deleting receipt handle #{rh}: #{err}"
    else
      log.error "No receipt handle found in message: #{JSON.stringify m}"

    cb()

  #-------------

  poll : (cb) ->
    arg = 
      QueueUrl : @sqs.url
      MaxNumberOfMessages : 5
      WaitTimeSeconds : 1
    await @cmd.aws.sqs.receiveMessage arg, defer err, res
    if err
      log.error "Error in polling SQS: #{err}"
    else if res?.Messages?
      for m in res.Messages
        await @process_message m, defer()
    cb()

  #-------------

  start : () ->
    @sqs = new aws.Resource { arn : @cmd.config.sqs() }
    @polling_loop()

  #-------------

  incoming_job : (arg, cb) ->
    filename = arg.md.path
    if (job = @filenames[filename])?
      rc = E.DUPLICATE
      log.info "|> skipping duplicated job: #{filename}"
    else
      rc = E.OK
      arg.cmd = @cmd
      dl = Downloader.import_from_obj arg
      @filenames[filename] = dl
      log.info "|> incoming job: #{dl.toString()}"

    cb rc

    if dl?
      await dl.launch defer ok
      if not ok
        log.warn "job kickoff failed for #{dl.toString()}"
      else if dl.is_ready()
        @start_download dl
      else
        @jobids[dl.job.id] = dl
        @n_waiting_jobs++

  #-------------

  completed : (dl) ->
    if (@jobids[dl.jobs.id]) 
      @n_waiting_jobs--
      delete @jobids[dl.jobs.id]

  #-------------

  start_download : (dl) ->
    @q.enqueue dl

  #-------------

#=========================================================================
