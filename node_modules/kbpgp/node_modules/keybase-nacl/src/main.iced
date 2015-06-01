
nacl_js = require 'tweetnacl/nacl-fast'
nacl_c = null 
{Sodium} = require './sodium'
{TweetNaCl} = require './tweetnacl'

nacl_c
mods = [ "sodium", "keybase-sodium" ]
for mod in mods
  try
    nacl_c = require(mod).api
    break
  catch e
  # noop

#================================================================

exports.sign =
  publicKeyLength : nacl_js.sign.publicKeyLength
  secretKeyLength : nacl_js.sign.secretKeyLength
  signatureLength : nacl_js.sign.signatureLength
  seedLength : nacl_js.sign.seedLength

#================================================================

#
# alloc
#
# Allocate a new NaCl key wrapper object for the given keys.
# Use compiled sodium code if possible, but if not, or if asked
# to use JS, fall back to TweetNaCl
#
# 
# @param {Buffer} publicKey The public key for this instance.
# @param {Buffer} secretKey The secret key for this instance.
# @return {Base} The key wrapper object, a subclass of type `Base`
#
exports.alloc = ({publicKey, secretKey, force_js}) ->
  ret = if force_js or not nacl_c? then new TweetNaCl { publicKey, secretKey }
  else new Sodium { publicKey, secretKey }

  # pass the libraries through with the code
  ret.lib = {c : nacl_c, js : nacl_js }

  return ret

#================================================================
