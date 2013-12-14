
#================================================================

exports.home = home = () ->
  # Portable...
  process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

#================================================================

