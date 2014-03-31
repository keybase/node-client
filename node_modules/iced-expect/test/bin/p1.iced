#!/usr/bin/env iced

read = require 'read'

await read { prompt : "What is your name, Droote?" }, defer err, r1
await setTimeout defer(), 10
await read {prompt : "Have you seen Jabbers?", silent : true }, defer err, r2
await setTimeout defer(), 20
await read { prompt: "Love those dogs" }, defer err, r3
await setTimeout defer(), 30
if r3 is 'yes'
  for i in [0..4]
    await read { prompt : "You good?" }, defer err, good
    await setTimeout defer(), 2
console.log [ r1, r2, r3 ].join (":")
process.exit 0