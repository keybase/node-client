
exports.constants =
  VERSION : 1
  PROT : "mkb.1"
  Header :
    FILE_VERSION : 1
    FILE_MAGIC   : [ 0x25, 0xb4, 0x84, 0xb8, 0x58, 0x36, 0x39, 0x9f ]
  poll_intervals:
    active : 30
    passive : 300
  crypto_mode :
    NONE : 0
    ENC : 1
    DEC : 1
  enc_version : 1
