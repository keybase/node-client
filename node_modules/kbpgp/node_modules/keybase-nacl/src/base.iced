
#================================================================

exports.b2u = b2u = (b) -> new Uint8Array(b)
exports.u2b = u2b = (u) -> new Buffer u

#================================================================

#
# @class Base
#
# Base class for Sodium and TweetNaCl implementations.
#
exports.Base = class Base

  #---------------
  #
  # 
  # @param {Buffer} publicKey The public key for this instance.
  # @param {Buffer} secretKey The secret key for this instance.
  # @param {Object} lib The library implementations to use
  #
  constructor : ({@publicKey, @secretKey, @lib}) ->

  #---------------
  #
  # @method genFromSeed
  #
  # Generate an EdDSA keypair from a deterministic seed.
  #
  # @param {Buffer} seed The seed
  # @return {Object} Contained `publicKey`, `secretKey` buffers
  # 
  # 
  genFromSeed : ({seed}) ->
  
    # As of sodium@1.0.13, there is no wrapper for crypto_sign_seed_keypair,
    # so use TweetNaCl's for all.
    tmp = @lib.js.sign.keyPair.fromSeed b2u seed

    # Note that the tweetnacl library deals with Uint8Arrays,
    # and internally, we like node-style Buffers.
    @secretKey = u2b tmp.secretKey
    @publicKey = u2b tmp.publicKey

    return { @secretKey, @publicKey }

  #---------------------------

  get_secret_key : () -> @secretKey
  get_public_key : () -> @publicKey

#================================================================
