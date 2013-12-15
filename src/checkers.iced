
exports.checkers = checkers = 
  username :
    hint : "between 4 and 12 letters long"
    f : (x) -> x.length >= 4 and x.length <= 12
  password : 
    hint : "must be at least 12 letters long"
    f : (x) -> x.length >= 12
  email : 
    hint : "must be a valid email address"
    f : (x) -> (x.length > 3) and (a = x.indexOf('@')) > 0 and x.indexOf('.') > a

