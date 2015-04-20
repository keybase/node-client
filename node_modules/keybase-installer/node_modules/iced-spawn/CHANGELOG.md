## v1.0.0 (2014-09-21)

Features:

  - First real release
  - Don't be picky at all with semver

## v0.0.10 (2014-06-09)

Bugfixes:
  
  - Comment out spammy warning...

## v0.0.9 (2014-06-04)

Bugfixes:

  - Another recompile for ICS v1.7.1-e

## v0.0.8 (2014-06-04)

Bugfixes:

  - Force args into string on windows
  - Upgrade to new ICS runtime
  - signed.md 

## v0.0.7 (2014-04-23)

Bugfix:

  - Small bugfix to default standard out

Features:

  - Open other FDs in the child other than standard 0,1,2. Sadly, doesn't work in Windows.

## v0.0.6 (2014-3-3)

Bugfixes:

  - When quiet mode is off, no extra newline on each warning

## v0.0.5 (2014-02-27)

Bugfixes:
	
  - Workaround bugs in v0.10.x in which stdin was closed on EOF, and then future calls to spawn failed
    because they were closing 0 due to a bug in libuv.  I submitted a PR to libuv, but they'd rather
    workaround that bug in node, so the PR was rejected:

       https://github.com/joyent/libuv/pull/1162

    We're working around the issue by opening a dummy fd=0

## v0.0.4 (2014-02-17)

Features:

	- Can specify a log function with your engine.

## v0.0.3

Bugfixes:

	- Escape spaces within arguments when constructing win32 command lines

Features:

	- Inaugural CHANGELOG.md
