
## v1.7.1-c (2014-06-03)

Features:

  - Factor out runtime, which is now available via `iced-runtime`
  - Build the browser package via browserify, not via ad-hoc mechanism
  - Build both coffee-script.js and coffee-script-min.js, now renamed
    to iced-coffee-script-#{VERSION}.js and iced-coffee-script-#{VERSION}-min.js
  - Remove other build packages, since now the main library is sucked in with
    browserify.

Warnings:

  - Danger ahead! There's a chance that this release is going to break
    existing software, but it's worth it for the long-haul.  Factoring
    out the runtime means software built with iced has way fewer
    dependencies.
