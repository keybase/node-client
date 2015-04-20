
package_json = require '../package.json'

#===================================================

exports.version = version = () -> package_json.version

#----------

exports.bin = bin = ()-> 
  for k,v of package_json.bin
    return k
  return null

#----------

exports.fullname = () -> "#{bin()} v#{version()}"

#===================================================

