
# Keybase Satelite Services

- Server/persistent JSON-RPC interface
  - Unix Domain sockets 
  - Named pipes on Windows
  - And localhost loopback with some credentials
- Command-line
  - pty when possible, stdin when not
  - prompting in general
  - calls out to pinentry
  - streams for stdin/stdout (data)
  - environment variables
  - command-line args
  - stderr for error display
  - stdout or some sort of status updates
- configuration and state
  - config.json (or something like it)
  - session.json (or something like it)
  - depends on Command-line flags and environemnt
- local DB
  - put/get/lookup/remove/unlink
- request / HTTPs/HTTP client
  - proxy support
  - CA support
  - Tor
- keychain access
  - either via GPG or direct
  - put/get/search functionality needed
  - trustdb manipulations? maybe
  - maybe shared with GPG or maybe distinct
- checker proofs
  - HTML-parsing service
  - DOM-awareness for chosen sites
  - DNS resolver 
- software update?
  - actually replace all of the above with newer versions;
  - maybe this is best left for a different version

Everything else is in the core.  The core will have access to these optional objects
and potentially pass them to one another as they require it. 
