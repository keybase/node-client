{createHash} = require 'crypto'

#=======================================================================

exports.SHA256 = SHA256 = (x) -> createHash('SHA256').update(x).digest()
exports.SHA512 = SHA512 = (x) -> createHash('SHA512').update(x).digest()

#=======================================================================
