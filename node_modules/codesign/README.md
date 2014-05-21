codesign
=============

directory contents codesign - will be used for code signing feature

### TODO

  - performance considerations:
    - alt_hash calculation creating unnecessary buffers and strings; switch to pipes entirely
  - pretty output on file not found errors, read-permission problems
  - handle poorly-parsing SIGNED.md file
  - test tilde and pound signs in names
  - automatic unit tests