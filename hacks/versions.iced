pkg = require '../package.json'
fs = require 'fs'
semver = require 'semver'

for mod,vers of pkg.dependencies
  pkg2 = require "../node_modules/#{mod}/package.json"
  unless semver.satisfies pkg2.version, vers
    console.log "X #{mod}: #{pkg2.version} | #{vers}"
