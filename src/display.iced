
[CHECK,BAD_X,BTC] = if (process.platform is 'win32') then [ "ok", "BAD", "$" ] 
else ["\u2714", "\u2716", "\u0e3f" ]

exports.CHECK = CHECK
exports.BAD_X = BAD_X
exports.BTC = BTC
