
mods =
  merkle_leaf : require '../files/30_merkle_leaf.iced'
  sig_chain : require '../files/31_sigchain.iced'

{BrowserRunner} = require('iced-test')

window.onload = () ->
  br = new BrowserRunner { log : "log", rc : "rc" }
  await br.run mods, defer rc
