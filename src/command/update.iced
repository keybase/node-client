{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{version_info} = require '../version'
{run} = require 'iced-spawn'
path = require 'path'
{env} = require '../env'
{make_esc} = require 'iced-error'

##=======================================================================

rewrite = (s) -> s.replace(/-/g, "_")

#----------

path_eq = (a,b) ->
  return false unless a.length is b.length
  for e,i in a
    return false unless e is b[i]
  return true

#----------

path_join = (arr) ->
  res = path.join arr...
  if arr[0]?.length is 0
    res = path.sep + res
  return res

#----------

strip = (s) -> if (m = s.match /(\S+)/) then m[1] else s

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    n:
      alias : "npm"
      help : "an alternate path for NPM"
    u :
      alias : "url"
      help : "specify a URL prefix for fetching"
    C :
      alias : "skip-cleanup"
      action : "storeTrue"
      help : "Don't cleanup temporary stuff after install"
    c : 
      alias : "cmd"
      help : "the command to run"
    p : 
      alias : "prefix"
      help : "the prefix to install to"
    g :
      alias : 'global'
      help : "install globally; don't try to guess prefix"
      action : "storeTrue"

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ ]
      help : "update the keybase client software"
    name = "update"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    log.debug "+ Command::run"
    await @tweak_path esc defer()
    await @probe_npm esc defer()
    await @probe_installer esc defer()
    await @compute_prefix esc defer()
    await @run_install esc defer()
    log.debug "- Command::run"
    cb null

  #----------

  npm : (args, cb) ->
    name = @argv.npm or "npm"
    if (p = @argv.prefix)?
      args = [ "--prefix", p].concat args
    await run { name, args }, defer err, out
    cb err, out 

  #----------

  kbi : ({args, verbose}, cb) ->
    name = @argv.cmd or "keybase-installer"
    log.info "Running `#{name} #{args.join(' ')}`" if verbose
    await run { name, args }, defer err, out
    cb err, out, name

  #----------

  probe_installer : (cb) ->
    await @kbi {args : ["--version"]}, defer err, vers, name
    if err?
      err = new Error "Can't find `#{name}` in your path: #{err.message}"
    else
      log.info "Found keybase-installer: #{vers}"
    cb err

  #----------

  probe_npm : (cb) -> 
    # Make sure we can access npm and if so, get the effective install
    # prefix
    await @npm [ "config", "get", "prefix" ], defer err, ret
    if err?
      err = new Error "Can't launch `npm`: #{err.message}"
    else
      @npm_install_prefix = strip ret.toString('utf8')
      log.info "Computed npm install prefix: #{@npm_install_prefix}"
    cb err



  #----------

  compute_prefix : (cb) ->

    if @argv.prefix then @prefix = @argv.prefix
    else if (process.env.PREFIX?.length) then # noop
    else if (((implicit_path = @my_bindir.split(path.sep)).pop() is 'bin') and
         not (path_eq @npm_install_prefix.split(path.sep), implicit_path)) and
         not @argv.global
      # In this case, we're going to install to where we were installed
      @prefix = path_join implicit_path
      log.info "Detected custom path '#{@prefix}'; preserving it!"
    else
      log.info "Using default npm install prefix"
    cb null

  #----------

  tweak_path : (cb) ->
    @my_bindir = path.dirname(process.argv[1])
    # Add our current location onto the front of the page
    process.env.path = [ @my_bindir , process.env.path  ].join(":")
    cb null

  #----------

  run_install : (cb) ->

    log.info "Attempting software upgrade....."


    args = []
    args.push("-g", g) if (g = env().get_gpg_cmd())?
    args.push("-O") if env().get_no_gpg_options()
    args.push("-d") if env().get_debug()

    args.push("--prefix", @prefix) if @prefix?

    for a in [ "npm", "url" ]
      args.push("--#{a}", v) if (v = @argv[rewrite(a)])?
    for a in [ "skip-cleanup" ]
      args.push("--#{a}") if (v = @argv[rewrite(a)])

    await @kbi {args, verbose : true }, defer err, out
    cb err

##=======================================================================

