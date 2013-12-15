
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

