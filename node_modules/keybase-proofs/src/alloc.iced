
web_service = require './web_service'
base = require './base'
{Untrack,Track} = require './track'
{Auth} = require './auth'
{Revoke} = require './revoke'
{Cryptocurrency} = require './cryptocurrency'
{Announcement} = require './announcement'
{Subkey} = require './subkey'
{Sibkey} = require './sibkey'
{Device} = require './device'
{Eldest} = require './eldest'
{PGPUpdate} = require './pgp_update'
{UpdatePassphraseHash} = require './update_passphrase_hash'

#=======================================================

lookup_tab = {
  "web_service_binding.twitter"    : web_service.TwitterBinding,
  "web_service_binding.github"     : web_service.GithubBinding,
  "web_service_binding.reddit"     : web_service.RedditBinding,
  "web_service_binding.keybase"    : web_service.KeybaseBinding,
  "web_service_binding.generic"    : web_service.GenericWebSiteBinding,
  "web_service_binding.dns"        : web_service.DnsBinding,
  "web_service_binding.coinbase"   : web_service.CoinbaseBinding,
  "web_service_binding.hackernews" : web_service.HackerNewsBinding,
  "web_service_binding.bitbucket"  : web_service.BitbucketBinding,
  "generic_binding"                : base.GenericBinding,
  "track"                          : Track,
  "untrack"                        : Untrack,
  "auth"                           : Auth,
  "revoke"                         : Revoke,
  "cryptocurrency"                 : Cryptocurrency,
  "announcement"                   : Announcement,
  "subkey"                         : Subkey,
  "sibkey"                         : Sibkey
  "device"                         : Device
  "eldest"                         : Eldest
  "pgp_update"                     : PGPUpdate
  "update_passphrase_hash"         : UpdatePassphraseHash
}

#--------------------------------------------

get_klass = (type, extra_lookup_tab) ->
  err = klass = null
  unless (klass = extra_lookup_tab?[type])? or (klass = lookup_tab[type])?
    err = new Error "Unknown proof class: #{type}"
  [err, klass]

#=======================================================

alloc = (type, args, extra_lookup_tab) ->
  ret = null
  [err, klass] = get_klass type, extra_lookup_tab
  if klass?
    ret = new klass args
  ret

#=======================================================

exports.get_klass = get_klass
exports.alloc = alloc

#=======================================================
