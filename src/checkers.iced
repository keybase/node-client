
exports.checkers = checkers = 
  username :
    hint : "between 4 and 12 letters long"
    f : (x) -> x.length >= 4 and x.length <= 12
  passphrase: 
    hint : "must be at least 12 letters long"
    f : (x) -> x.length >= 12
  email : 
    hint : "must be a valid email address"
    f : (x) -> (x.length > 3) and x.match /^\S+@\S+\.\S+$/ 
  invite_code :
    hint : "invite codes are 24 digits long"
    f : (x) -> x.length is 24
  email_or_username :
    hint : "valid usernames are 4-12 letters long"
  intcheck : (lo, hi) ->
    hint : "#{lo}-#{hi}"
    f : (x) -> not(isNaN(i = parseInt(x))) and i >= lo and i <= hi

checkers.email_or_username.f = (x) -> (checkers.email.f(x) or checkers.username.f(x))



