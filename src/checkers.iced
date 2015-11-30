
exports.checkers = checkers =
  username :
    hint : "between 2 and 16 letters long"
    f : (x) -> x.length >= 2 and x.length <= 16
  remote_username :
    hint : "between 1 and 40 letters long"
    f : (x) -> x.length >= 1 and x.length <= 40
  passphrase:
    hint : "must be at least 12 letters long"
    f : (x) -> x.length >= 12
  passphrase_short:
    hint : "password cannot be empty"
    f : (x) -> x.length >= 1
  passphrase_nls:
    hint : "must be at least 12 letters long and can't have a leading space"
    f : (x) -> x.length >= 12 and not (x.match /^\s/)
  email :
    hint : "must be a valid email address"
    f : (x) -> (x.length > 3) and x.match /^\S+@\S+\.\S+$/
  email_or_username :
    hint : "valid usernames are 4-12 letters long"
  intcheck : (lo, hi, defint) ->
    hint : "#{lo}-#{hi}"
    f : (x) ->
      if (defint? and x is "") then true
      else not(isNaN(i = parseInt(x))) and i >= lo and i <= hi

checkers.email_or_username.f = (x) -> (checkers.email.f(x) or checkers.username.f(x))



