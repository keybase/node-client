
log = require './log'
ie = require 'iced-error'

#================================================

exports.E = ie.make_errors
  GENERIC : "Generic error"
  INVAL : "Invalid value"
  NOT_FOUND : "Not found"
  BAD_QUERY : "Bad query"
  DUPLICATE : "Duplicated value"
  BAD_MAC : "Message authentication failure"
  BAD_SIZE : "Wrong size"
  BAD_PREAMBLE : "Premable mismatch or bad file magic"
  BAD_IO : "bad input/output operation"
  BAD_HEADER : "Bad metadata in file"
  INTERNAL : "internal assertion failed"
  MSGPACK : "Message pack format failure"
  BAD_PW_OR_MAC : "Bad password or file was corrupted"
  INIT : "Initialization error"
  AWS : "AWS failure"
  INDEX : "Error commit index to AWS"
  DAEMON : "Error in connecting to or launching daemon"
