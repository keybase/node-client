
[CHECK,BAD_X] = if (process.platform is 'win32') then [ "ok", "BAD" ] else ["\u2714", "\u2716" ]
exports.CHECK = CHECK
exports.BAD_X = BAD_X
