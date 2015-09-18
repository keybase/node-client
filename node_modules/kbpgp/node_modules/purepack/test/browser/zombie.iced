zombie = require 'zombie'
await zombie.visit "file:///Users/max/src/purepack/test/browser/index.html", { debug : true }, defer e, browser
if e? then console.log e
await setTimeout defer(), 1000
console.log browser.window.document.innerHTML;
console.log browser.window.document.getElementById("log").innerHTML
