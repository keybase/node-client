
{dict_union,dict_merge} = require('../../lib/main').util

exports.test_1 = (T,cb) ->
  d1 = 
    ant : 1
    bar : 
      bam : 2
      baz : [3...8]
      beep : [5..9]
    cow : 9
  d2 =
    ant : 5
    bar :
      baz :
        donkey : 12
      cudgle : 10
    eel : 
      fish :
        goat : 11
  d3 = dict_merge d1, d2
  d4 = 
    ant : 5
    bar :
      bam : 2
      baz :
        donkey : 12
      cudgle : 10
      beep : [5..9]
    cow : 9
    eel :
      fish :
        goat : 11
  T.equal d3, d4, "first merge came back"
  d5 = 
    ant : bear : 30
    bar : baz : ass : 31
  d6 = dict_merge d1, d2, d5
  d7 =
    ant : bear : 30
    bar :
      bam : 2
      baz :
        ass : 31
        donkey : 12
      cudgle : 10
      beep : [5..9]
    cow : 9
    eel :
      fish :
        goat : 11
  T.equal d6, d7, "second merge came back"
  d8 = dict_union d1, d2
  d9 = 
    ant : 5
    bar :
      baz :
        donkey : 12
      cudgle : 10
    cow : 9
    eel : 
      fish :
        goat : 11
  T.equal d8, d9, "dict union came back"
  cb()


