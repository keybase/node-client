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

act =
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

  verify_with_assertions: (T, who, whom, assertions, expect_success, cb) ->
    args = ["dir", "verify", whom.homedir]
    for ass in assertions
      args.push "--assert"
      args.push ass    
    await who.keybase {args, quiet: true}, defer err, out
    if expect_success
      T.no_error err, "failed to verify good home dir signing"
      T.assert out, "failed to verify good home dir signing"
    else
      T.assert err?, "expected an error in home dir signature"
    cb()

  proof_ids: (T, who, cb) ->

    args = ["status"]
    await who.keybase {args}, defer err, out
    T.no_error err, "failed to status"
    T.assert out,   "failed to status"

    res = null
    if (not err) and out?.toString()
      res = JSON.parse(out.toString()).user.proofs
    cb res

  verify_home_dir: (T, who, expect_success, cb) -> act.__verify_home_dir T, who, expect_success, false, cb
  strict_verify_home_dir: (T, who, expect_success, cb) -> act.__verify_home_dir T, who, expect_success, true, cb

  rfile: -> "file_#{prng(12).toString('hex')}.txt"
  rdir:  -> "dir_#{prng(12).toString('hex')}"

  unlink: (T, who, fname, cb) ->
    await fs.unlink path.join(who.homedir, fname), defer err
    T.no_error err, "failed to unlink file"
    cb()

  rmdir: (T, who, dname, cb) ->
    await fs.rmdir path.join(who.homedir, dname), defer err
    T.no_error err, "failed to rmdir"
    cb()

  symlink: (T, who, src, dest, cb) ->    
    p_src  = path.join who.homedir, src
    p_dest = path.join who.homedir, dest 
    await fs.symlink p_src, p_dest, defer err
    T.no_error err, "failed to symlink file"
    cb()

  chmod: (T, who, fname, mode, cb) ->
    await fs.chmod (path.join who.homedir, fname), mode, defer err
    T.no_error err, "error chmod'ing"
    cb()

  write_random_file: (T, who, cb) ->
    await fs.writeFile (path.join who.homedir, act.rfile()), 'fake', defer err
    T.no_error err, "error writing random file"
    cb()

  mk_random_dir: (T, who, cb) ->
    await fs.mkdir (path.join who.homedir, act.rdir()), defer err
    T.no_error err, "error creating random directory"
    cb()

  mkdir: (T, who, dname, cb) ->
    await fs.mkdir (path.join who.homedir, dname), defer err
    T.no_error err, "error creating directory"
    cb()

  append_junk: (T, who, fname, cb) ->
    await fs.appendFile (path.join who.homedir, fname), prng(100).toString('hex'), defer err
    T.no_error err, "error writing/appending to file"
    cb()

# -----------------------------------------------------------------------------------------

exports.alice_sign_and_verify_homedir = (T, cb) ->
  await act.sign_home_dir   T, alice, defer()
  await act.verify_home_dir T, alice, true, defer()
  cb()

exports.assertions = (T, cb) ->
  await act.sign_home_dir          T, charlie,        defer()
  await act.proof_ids              T, charlie,        defer proof_ids
  await act.verify_with_assertions T, alice, charlie, ["twitter:#{proof_ids.twitter}", "github:#{proof_ids.github}"],   true, defer()
  await act.verify_with_assertions T, alice, charlie, ["twitter:evil_wrongdoer", "github:wrong_evildoer"],             false, defer()
  cb()

exports.alice_wrong_item_types = (T, cb) ->
  fname   = act.rfile()
  await act.append_junk            T,   alice, fname, defer()
  await act.sign_home_dir          T,   alice,        defer()
  await act.unlink                 T,   alice, fname, defer()
  await act.mkdir                  T,   alice, fname, defer()
  await act.verify_home_dir        T,   alice, false, defer()
  await act.sign_home_dir          T,   alice,        defer()
  await act.rmdir                  T,   alice, fname, defer()
  await act.append_junk            T,   alice, fname, defer()
  await act.verify_home_dir        T,   alice, false, defer()
  cb()

exports.alice_wrong_exec_privs = (T, cb) ->
  fname   = act.rfile()
  await act.append_junk            T,   alice, fname, defer()
  await act.sign_home_dir          T,   alice,        defer()
  await act.chmod                  T,   alice, fname, '0755', defer()
  await act.verify_home_dir        T,   alice, true,  defer()
  await act.strict_verify_home_dir T,   alice, false, defer()
  await act.chmod                  T,   alice, fname, '0666', defer()
  await act.strict_verify_home_dir T,   alice, true,  defer()
  cb()

exports.alice_bad_signatures = (T, cb) ->
  await act.sign_home_dir   T,   alice,        defer()
  await act.verify_home_dir T,   alice, true,  defer()
  await act.write_random_file T, alice,        defer()
  await act.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_bad_file_contents = (T, cb) ->
  fname   = act.rfile()
  await act.append_junk T,       alice, fname, defer()
  await act.sign_home_dir   T,   alice,        defer()
  await act.verify_home_dir T,   alice, true,  defer()
  await act.append_junk T,       alice, fname, defer()
  await act.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_file_missing = (T, cb) ->
  fname   = act.rfile()
  await act.append_junk     T,   alice, fname, defer()
  await act.sign_home_dir   T,   alice,        defer()
  await act.verify_home_dir T,   alice, true,  defer()
  await act.unlink T,            alice, fname, defer()
  await act.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_extra_file = (T, cb) ->
  await act.sign_home_dir   T,   alice,        defer()
  await act.write_random_file T, alice,        defer()
  await act.verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_extra_dir = (T, cb) ->
  await act.sign_home_dir          T,   alice,        defer()
  await act.mk_random_dir          T,   alice,        defer()
  await act.verify_home_dir        T,   alice, true,  defer()
  await act.strict_verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_dir_missing = (T, cb) ->
  d = act.rdir()
  await act.mkdir                  T,   alice, d,     defer()
  await act.sign_home_dir          T,   alice,        defer()
  await act.rmdir                  T,   alice, d,     defer()
  await act.verify_home_dir        T,   alice, true,  defer()
  await act.strict_verify_home_dir T,   alice, false, defer()
  cb()

exports.alice_bad_symlinks = (T, cb) ->
  src   = act.rfile()
  dest1 = act.rfile()
  dest2 = act.rfile()

  await act.append_junk T,       alice, dest1,       defer()  
  await act.append_junk T,       alice, dest2,       defer()  
  await act.symlink T,           alice, dest1, src,  defer()
  await act.sign_home_dir T,     alice,              defer()
  await act.verify_home_dir T,   alice, true,        defer()
  await act.unlink T,            alice, src,         defer()
  await act.symlink T,           alice, dest2, src,  defer()
  await act.verify_home_dir T,   alice, false,        defer()
  cb()
