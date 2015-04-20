
##=======================================================================

exports.List = class List

  #-----------------------------------------

  constructor: ->
    @_head = null
    @_tail = null

  #-----------------------------------------

  head : () -> @_head
  tail : () -> @_tail

  #-----------------------------------------

  push : (o) ->
    o.__list_prev = @_tail
    o.__list_next = null
    @_tail.__list_next = o if @_tail
    @_tail = o
    @_head = o unless @_head

  #-----------------------------------------

  # fn() is a function that's called once with each
  # element in the list. Keep walking the list so long
  # as fn() returns true; otherwise, break out.
  walk : (fn) ->
    p = @_head
    while p
      next = p.__list_next
      break unless fn p
      p = next
    true

  #-----------------------------------------

  remove : (w) ->
    next = w.__list_next
    prev = w.__list_prev
    
    if prev then prev.__list_next = next
    else         @_head = next
    
    if next then next.__list_prev = prev
    else         @_tail = prev

    w.__list_next = null
    w.__list_prev = null
    
##=======================================================================     
