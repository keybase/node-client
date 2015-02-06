# node-lookup-tty

Get the TTY device (e.g., /dev/pts/3) of the current node process

## Usage

```javascript
// A clone of the `tty` command
var tty = require('spotty');
tty(function(err, res) {
	if (err) {
		console.error("Error found: " + err.toString())
	} else {
		console.log(res)
	}
})
```

## Approach

It's an ugly hack, but it should work.  The idea is to call `fstat` on
file descriptor 0, and then to call `stat` on all `tty`-like files in dev.
Stop when we find one that matches `fstat(0)`.

## Limitations

Doesn't work on Windows.  Should work on OSX and Linux, but needs some
testing.  Won't work if fd=0 isn't standard input connected to a TTY.

## Author

Max Krohn for Keybase, Inc.