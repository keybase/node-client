fs      = require 'fs'
path    = require 'path'
{users} = require '../lib/user'
{prng}  = require 'crypto'

alice = bob = charlie = null

exports.init = (T,cb) ->
  bob     = users().lookup_or_gen 'bob'
  alice   = users().lookup_or_gen 'alice'
  charlie = users().lookup_or_gen 'charlie'
  cb()

ctext = null

# -----------------------------------------------------------------------------------------

test =
  sign_home_dir: (T, who, cb) ->
    args = ["dir", "sign", who.homedir]
    await who.keybase {args, quiet: true}, defer err, out
    T.no_error err, "failed to sign home dir"
    T.assert   out, "failed to sign home dir"
    cb()

  __verify_home_dir: (T, who, expect_success, strict, cb) ->
    if strict
      args = ["dir", "verify", "--strict", who.homedir]
    else
      args = ["dir", "verify", who.homedir]    
    await who.keybase {args, quiet: true}, defer err, out
    if expect_success
      T.no_error err, "failed to verify good home dir signing"
      T.assert out, "failed to verify good home dir signing"
    else
      T.assert err?, "expected an error in home dir signature"
    cb()

  verify_home_dir: (T, who, expect_success, cb) -> test.__verify_home_dir T, who, expect_success, false, cb
  strict_verify_home_dir: (T, who, expect_success, cb) -> test.__verify_home_dir T, who, expect_success, true, cb

  rfile: -> "file_#{prng(12).toString('hex')}.txt"
  rdir:  -> "dir_#{prng(12).toString('hex')}.txt"

  unlink: (T, who, fname, cb) ->
    await fs.unlink path.join(who.homedir, fname), defer err
    T.no_error err, "failed to unlink file"
    cb()

  symlink: (T, who, src, dest, cb) ->    
    p_src  = path.join who.homedir, src
    p_dest = path.join who.homedir, dest 
    await fs.symlink p_src, p_dest, defer err
    T.no_error err, "failed to symlink file"
    cb()

  write_random_file: (T, who, cb) ->
    await fs.writeFile (path.join who.homedir, test.rfile()), 'fake', defer err
    T.no_error err, "error writing random file"
    cb()

  mk_random_dir: (T, who, cb) ->
    await fs.mkdir (path.join who.homedir, test.rdir()), defer err
    T.no_error err, "error creating random directory"
    cb()


  append_junk: (T, who, fname, cb) ->
    await fs.appendFile (path.join who.homedir, fname), prng(100).toString('hex'), defer err
    T.no_error err, "error writing/appending to file"
    cb()

# -----------------------------------------------------------------------------------------


exports.alice_sign_and_verify_homedir = (T, cb) ->
  await test.sign_home_dir   T, alice, defer()
  await test.verify_home_dir T, alice, true, defer()
  cb()

exports.alice_bad_signatures = (T, cb) ->
  await test.sign_home_dir   T,   alice,        defer()
  await test.verify_home_dir T,   alice, true,  defer()
  await test.write_random_file T, alice,        defer()
  await test.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_bad_file_contents = (T, cb) ->
  fname   = test.rfile()
  await test.append_junk T,       alice, fname, defer()
  await test.sign_home_dir   T,   alice,        defer()
  await test.verify_home_dir T,   alice, true,  defer()
  await test.append_junk T,       alice, fname, defer()
  await test.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_file_missing = (T, cb) ->
  fname   = test.rfile()
  await test.append_junk     T,   alice, fname, defer()
  await test.sign_home_dir   T,   alice,        defer()
  await test.verify_home_dir T,   alice, true,  defer()
  await test.unlink T,            alice, fname, defer()
  await test.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_extra_file = (T, cb) ->
  await test.sign_home_dir   T,   alice,        defer()
  await test.write_random_file T, alice,        defer()
  await test.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_extra_dir = (T, cb) ->
  await test.sign_home_dir          T,   alice,        defer()
  await test.mk_random_dir          T,   alice,        defer()
  await test.verify_home_dir        T,   alice, true,  defer()
  await test.strict_verify_home_dir T,   alice, false,  defer()
  cb()


exports.alice_bad_symlinks = (T, cb) ->
  src   = test.rfile()
  dest1 = test.rfile()
  dest2 = test.rfile()

  await test.append_junk T,       alice, dest1,       defer()  
  await test.append_junk T,       alice, dest2,       defer()  
  await test.symlink T,           alice, dest1, src,  defer()
  await test.sign_home_dir T,     alice,              defer()
  await test.verify_home_dir T,   alice, true,        defer()
  await test.unlink T,            alice, src,         defer()
  await test.symlink T,           alice, dest2, src,  defer()
  await test.verify_home_dir T,   alice, false,        defer()
  cb()
