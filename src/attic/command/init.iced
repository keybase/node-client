
{Base} = require './base'
{add_option_dict} = require './argparse'
read = require 'read'
log = require '../log'

#=========================================================================

exports.Command = class Command extends Base

  #------------------------------

  OPTS : 
    o :
      alias : 'output'
      help : 'the output config file to write (defaults to ~/.keybase.conf)'
    A :
      alias : 'access-key-id'
      help : 'the accessKeyId for an admin AWS user'
    r : 
      alias : 'region'
      help : 'the AWS region to work in'
    S : 
      alias : 'secret-access-key'
      help : 'the secreteAccessKey for an admin AWS user'
    v :
      alias : 'vault'
      help : 'the vault name to create'

  #------------------------------

  get_opt_or_prompt : ({name, desc}, cb) ->
    desc = name unless desc?
    val = @argv[name]
    err = null
    until val? or err?
      await read { prompt: "#{desc}> " }, defer err, val
      if err?
        log.error "Error in getting #{desc}: #{err}"
    cb err, val

  #------------------------------

  load_config_value : ({name, desc, key, val_prefix}, cb) ->
    await @get_opt_or_prompt {name, desc}, defer err, val
    if val?
      val = [ val_prefix, val ].join '' if val_prefix?
      @config.set key, val
    cb not err?

  #------------------------------

  load_config : (cb) ->
    ok = true
    fields = [{
      name : 'email'
      desc : 'your primary email address'
      key : 'email'
    },{
      name : 'region'
      desc : 'AWS region (like "us-west-2")'
      key : 'aws.region'
    },{
      name : 'vault'
      desc : 'vault name'
      key : 'vault'
      val_prefix : "mkb-"
    },{
      name : 'access_key_id'
      desc : 'access key id'
      key : 'aws.accessKeyId'
    },{
      name : 'secret_access_key'
      desc : 'secret access key'
      key : 'aws.secretAccessKey'
    }]

    for d in fields
      await @load_config_value d, defer ok 

    @config.loaded = ok

    cb ok

  #------------------------------

  add_subcommand_parser : (scp) ->
    opts = 
      help : 'initialize AWS for this user'
    name = 'init'
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ]

  #------------------------------

  check_config : (cb) ->
    await @config.find @argv.output, defer found
    if found
      log.error "Config file #{@config.filename} exists; refusing to overwrite"
    cb (not found)

  #------------------------------

  init : (cb) ->
    ok = true
    await @check_config defer ok
    await @load_config defer ok if ok
    await super defer ok if ok
    if ok
      @vault = @config.vault()
      @name = @vault
    cb ok

  #--------------

  make_iam_user : (cb) ->
    arg = { UserName : @name }
    await @aws.iam.createUser arg, defer err
    ok = true
    if err?
      ok = false
      log.error "Error in making user '#{@name}': #{err}"
    if ok
      await @aws.iam.createAccessKey arg, defer err, res
      if err?
        ok = false
        log.error "Error in creating access key: #{err}"
      else if (not res?.AccessKey?) or (res?.AccessKey.Status isnt 'Active')
        ok = false
        log.error "Didn't get expected fields back from IAM; got #{JSON.stringify res}"
      else
        # Now we update the config obj, so that we're using
        # the new, lower-privleged IAM.  We'll then write this version
        # out to the FS.
        @config.set "aws.accessKeyId", res.AccessKey.AccessKeyId
        @config.set "aws.secretAccessKey", res.AccessKey.SecretAccessKey
    cb ok

  #--------------

  make_sns : (cb) -> 
    await @aws.sns.createTopic { Name : @name }, defer err, res
    ok = true
    if err?
      log.error "Error making notification queue: #{err}"
      ok = false
    else
      @sns = @aws.new_resource { arn : res.TopicArn }
      log.info "+> Created SNS topic #{@sns.toString()}"
    cb ok

  #--------------

  make_sqs : (cb) ->

    # First make the queue
    await @aws.sqs.createQueue { QueueName : @name }, defer err, res
    ok = true
    if err?
      ok = false
      log.error "Error creating queue #{@name}: #{err}"
    else
      @sqs = @aws.new_resource { url : res.QueueUrl }
      log.info "+> Created SQS queue #{@sqs.toString()}"

    # Allow the SNS service to write to this...
    if ok
      policy = 
        Version : "2008-10-17"
        Id : "@{sqs.arn}/SQSDefaultPolicy"
        Statement: [{
          Sid : "Stmt#{Date.now()}"
          Effect : "Allow"
          Principal : AWS : "*"
          Action : "SQS:SendMessage"
          Resource : @sqs.arn
          Condition : ArnEquals : "aws:SourceArn" : @sns.arn
        }]
      arg = 
        QueueUrl : @sqs.url
        Attributes:
          Policy : JSON.stringify policy
      await @aws.sqs.setQueueAttributes arg, defer err, res
      if err?
        log.error "Error setting Queue attributes with #{JSON.stringify arg}: #{err}"
        ok = false

    if ok
      arg = 
        TopicArn : @sns.arn
        Protocol : 'sqs'
        Endpoint : @sqs.arn
      await @aws.sns.subscribe arg, defer err, res
      if err?
        log.error "Failed to establish subscription from #{@sqs.toString()} to #{@sns.toString()}: #{err}"
        ok = false

    cb ok

  #------------------------------

  grant_permissions : (cb) ->
    svcs = [ 'sqs', 'glacier', 'sdb' ]
    ok = true
    for v in svcs when ok
      await @grant v, defer ok
    if ok
      log.info "+> Granted permissions to IAM #{@config.aws().accessKeyId}"
    cb ok 

  #------------------------------

  grant : (svc, cb) ->
    policy =
      Statement : [{
        Sid : "Stmt#{Date.now()}#{svc}"
        Action : [ "#{svc}:*" ]
        Effect : "Allow"
        Resource : [ @[svc].arn ]
      }]
    policy_name = "#{@name}-#{svc}-access-policy"
    arg =
      UserName : @name
      PolicyName : policy_name
      PolicyDocument : JSON.stringify policy
    await @aws.iam.putUserPolicy arg, defer err, data
    if err?
      log.error "Error setting policy #{JSON.stringify arg}: #{err}"
      ok = false
    else
      ok = true
    cb ok

  #------------------------------

  make_glacier : (cb) ->
    arg = 
      vaultName : @name
    await @aws.glacier.createVault arg, defer err, res
    if err?
      log.error "Error creating vault #{JSON.stringify arg}: #{err}"
      ok = false
    else
      ok = true
      lparts = res.location.split '/'
      @account_id = lparts[1]
      aparts = [ 'arn', 'aws', 'glacier', @config.aws().region, lparts[1] ]
      aparts.push lparts[2...].join '/'
      arn = aparts.join ":"
      @glacier = @aws.new_resource { arn }
      log.info "+> Created Glacier Vault #{@glacier.toString()}"
    cb ok

  #------------------------------

  make_simpledb : (cb) ->
    arg = 
      DomainName : @name
    await @aws.sdb.createDomain arg, defer err, res
    if err?
      log.error "Error creatingDomain #{JSON.stringify arg}: #{err}"
      ok = false
    else
      ok = true
      aparts = [ 'arn', 'aws', 'sdb', @config.aws().region, @account_id,
                 "domain/#{@name}" ]
      arn = aparts.join ":"
      @sdb = @aws.new_resource { arn }
      log.info "+> Created SimpleDB domain #{@sdb.toString()}"
    cb ok

  #------------------------------

  write_config : (cb) ->
    await @config.write defer ok
    if not ok
      log.error "Bailing out, since can't write out config file"
    else
      log.info "+> Writing out config file: #{@config.filename}"
    cb ok

  #------------------------------

  update_config : (cb) ->
    for svc in [ "sns", "sqs", "glacier", "sdb" ]
      @config.set "arns.#{svc}", @[svc].arn.toString()
    @config.set "account_id" , @account_id
    cb true

  #------------------------------

  run : (cb) ->
    await @init defer ok
    await @make_iam_user defer ok   if ok
    await @write_config  defer ok if ok
    await @make_sns      defer ok   if ok
    await @make_sqs      defer ok   if ok
    await @make_glacier  defer ok   if ok
    await @make_simpledb defer ok   if ok
    await @grant_permissions defer ok if ok
    await @update_config defer ok if ok
    await @write_config  defer ok if ok
    cb ok

  #------------------------------

#=========================================================================

