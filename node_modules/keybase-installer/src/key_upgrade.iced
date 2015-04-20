
{make_esc} = require 'iced-error'
{keyring} = require 'gpg-wrapper'
{fpeq} = require('pgp-utils').util
{chain} = require('iced-utils').util
{KeyInstall} = require './key_install'
log = require './log'

##========================================================================

exports.KeyUpgrade = class KeyUpgrade

  #-----------------

  constructor : (@config) ->
    @_v = {}
  
  #-----------------

  fetch : (cb) ->
    await @config.request "/sig/files/#{@_v.old}/keyset-#{@_v.new}.asc", defer err, res, @_sig
    cb err

  #-----------------

  verify : (cb) ->
    await @config.oneshot_verify {which :'code', sig : @_sig}, defer err, @_keyset
    cb err

  #-----------------

  install : (cb) -> 
    ki = new KeyInstall @config, @_keyset
    await ki.run defer err
    unless err?
      keys = ki.keys()
      keys.version = @_v.new
      @config.set_keys keys
    cb err

  #-----------------

  run : (cb) ->
    esc = make_esc cb, "KeyUpgrade::run"
    if (@_v.new = @config.index().keys.latest) > (@_v.old = @config.key_version())
      log.info "Key upgrade suggested; new version is #{@_v.new}, but we have #{@_v.old}"
      await @fetch defer()
      await @verify esc defer() 
      await @install esc defer()
    cb null

##========================================================================
