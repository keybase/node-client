
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
    db_file : "keybase.sqlite3"
  security:
    pwh : derived_key_bytes : 32
    openpgp : derived_key_bytes : 12
    triplesec : version : 3
  permissions :
    dir : 0o700
    file : 0o600
  lookups :
    username : 1
  ids :
    sig_chain_link : "e0"
  import_state : 
    NONE : 0
    TEMPORARY : 1
    FINAL : 2
  signature_types :
    NONE : 0
    SELF_SIG : 1
    REMOTE_PROOF : 2
    TRACK : 3
    UNTRACK : 4
    REVOKE : 5

constants.server.api_uri_prefix = "/_/api/" + constants.api_version

