
exports.constants = constants = 
  version : 1
  api_version : "1.0"
  canonical_host : "keybase.io"
  server : 
    host : "keybase.io"
    port : 443
    no_tls : false
  filenames : 
    config_dir : ".keybase"
    config_file : "config.json"
    session_file : "session.json"
  security:
    pwh : derived_key_bytes : 32
    openpgp : derived_key_bytes : 12
    triplesec : version : 3

constants.server.api_uri_prefix = "/_/api/" + constants.api_version

