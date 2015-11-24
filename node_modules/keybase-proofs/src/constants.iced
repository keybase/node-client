
exports.constants = constants =
  tags :
    sig : "signature"
  versions :
    sig : 1
  sig_types :
    generic_binding : "generic_binding"
    web_service_binding : "web_service_binding"
    track : "track"
    auth : "auth"
    untrack : "untrack"
    revoke : "revoke"
    pgp_update : "pgp_update"
    update_passphrase_hash : "update_passphrase_hash"
    cryptocurrency : "cryptocurrency"
    announcement : "announcement"
    subkey : "subkey"
    sibkey : "sibkey"
    device : "device"
    eldest : "eldest"
  proof_types :
    none : 0
    keybase : 1
    twitter : 2
    github : 3
    reddit : 4
    coinbase : 5
    hackernews : 6
    bitbucket : 7
    generic_web_site : 1000
    dns              : 1001
  expire_in : 60*60*24*365*5 # 5 years....
  http_timeout : 15*1000 # give up after 15 seconds....
  short_id_bytes : 27
  shortest_pgp_signature : 100 # can't have a PGP signature shorter than this...

  # Copy-pasted from Keybase for now, but they should live here...
  seq_types :
    NONE : 0
    PUBLIC : 1
    PRIVATE : 2
    SEMIPRIVATE : 3

  v_codes : # verification codes for hosted proofs
    NONE:              0
    OK:                1
    LOCAL:             2
    FOUND:             3 # It's been found in the hunt, but not proven yet

    # Retryable soft errors
    BASE_ERROR:        100
    HOST_UNREACHABLE:  101
    PERMISSION_DENIED: 103 # Since the user might fix it
    FAILED_PARSE:      106
    DNS_ERROR :        107
    AUTH_FAILED:       108
    HTTP_500:          150
    TIMEOUT:           160

    # Likely will result in a hard error, if repeated enough
    BASE_HARD_ERROR:   200
    NOT_FOUND:         201
    CONTENT_FAILURE:   202
    BAD_USERNAME:      203
    BAD_REMOTE_ID:     204
    TEXT_NOT_FOUND:    205
    BAD_ARGS:          206
    CONTENT_MISSING:   207
    TITLE_NOT_FOUND:   208
    SERVICE_ERROR:     209
    TOR_SKIPPED:       210
    TOR_INCOMPATIBLE:  211
    HTTP_300:          230
    HTTP_400:          240
    HTTP_OTHER:        260
    EMPTY_JSON:        270

    # Hard final errors
    DELETED:           301
    SERVICE_DEAD:      302
    BAD_SIGNATURE:     303

  user_agent : "keybase-proofs/"

d = {}
(d[v] = k for k,v of constants.proof_types)
exports.proof_type_to_string = d
