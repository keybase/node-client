
semver = require 'semver'

known_bad_versions = [ "0.10.31" ]
old_versions = "<0.10.20"
good_versions = "0.10.20 - 0.10.30 || >=0.10.32"
suggest_versions = [ "0.10.32", "0.11.13" ]
suggest_version = "0.10.32"

is_good_version = (v) ->
  semver.satisfies(v, good_versions)

check_node = (v) ->
  v or= process.version
  v = semver.clean v
  problem = if is_good_version(v) then null
  else if v in known_bad_versions then problem = "known to crash"
  else if semver.satisfies(v, old_versions) then msg = "out of date"
  else if not is_good_version(v) then problem = "not recommended"

  if not problem? then null
  else new Error "Your version of node (#{v}) is #{problem}; please upgrade to #{suggest_version} or better"

check_node_async = (v, cb) ->
  cb check_node v

module.exports = { known_bad_versions, old_versions, good_versions, suggest_version,
  suggest_versions, check_node, check_node_async, is_good_version}
