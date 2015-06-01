{bufeq_secure} = require './util'
{b2u,u2b,Base} = require './base'

#================================================================

# 
# @class TweetNaCl
#
#  A pure-JS implemenation using the TweetNaCl library.
#
exports.TweetNaCl = class TweetNaCl extends Base

  #
  # @method verify
  #
  # Verify a signature, given a public key, the signature, and the payload
  # (if it's not alread attached).
  #
  # @param {Bool} detached If this is a detached signature or not.
  # @param {Buffer} payload The payload to verify. Optional, might be attached.
  # @param {Buffer} sig The signature to verify.
  # @return {List<Error,Buffer>} error on a failure, or nil on success. On sucess,
  #   also return the payload from the buffer.
  #
  verify : ({payload, sig, detached}) ->
    # "Attached" signatures in NaCl are just a concatenation of the signature
    # in front of the message.
    err = null
    if detached
      payload = new Buffer [] if not payload?
      if not @lib.js.sign.detached.verify b2u(payload), b2u(sig), b2u(@publicKey)
        err = new Error "signature didn't verify"
    else if not (r_payload = @lib.js.sign.open b2u(sig), b2u(@publicKey))?
      err = new Error "signature didn't verify"
    else if not (r_payload = u2b r_payload)?
      err = new Error "failed to convert from a Uint8Array to a buffer"
    else if payload? and not bufeq_secure(r_payload, payload)
      err = new Error "got unexpected payload"
    else
      payload = r_payload
    if err? then payload = null
    return [ err, payload ]
  
  #
  # @method sign
  #
  # Generate a signature for the given payload, either attached or 
  # unattached
  #
  # @param {Bool} detached If this is a detached signature or not.
  # @param {Buffer} payload The payload to sign
  # @return {Butter} The signature
  #
  sign : ({payload, detached}) ->
    f = if detached then @lib.js.sign.detached else @lib.js.sign
    u2b(f(b2u(payload), b2u(@secretKey)))

#================================================================
