purepack
========

A pure CoffeeScript implementation of Msgpack.

## Install

    npm install purepack

## Where To Use it

Tested and works with [browserify](https://github.com/substack/node-browserify), so
it's useful for packing and unpacking structures on the browser-side.  It also works
server-side in `node` processes.  In either case, it finds the fastest buffer
objects at its disposal to give you the best performance possible.

## API

### purepack.pack(obj,opts)

Pack an object `obj`. Return a `Buffer` object.

##### opts

Options currently supported, off by default:

* `floats` — Use floats rather than doubles when encoding.  Useful when saving space
* `sort_keys` - Sort the keys of maps on outputs, so that purepack output can be compared in hashes.
* `ext` - An 'extensible-type' function.
* `no_str8` - Don't use 8-bit string encodings, to maintain compatibility with older msgpacks.

### purepack.unpack(buf,opts)

Unpack a packed `Buffer buf`. Throws errors if there were underruns, or bad encodings.
 
##### opts

Currently support options are:

* `ext` - An `extensible-type` function that given a `[type,buf]` tuple, returns
an object. Can throw an error if needs be.
* `no_ext` - If no `ext` option is given, we plug in a default, stupid-ish
`ext` function. Supply this flag if you don't want that.

## Building

    make setup
    make

## Testing

    make setup
    make
    make test

Testing will run a series of scripts on your machine using `node`.  It also will
ask you to visit a URL with whichever browsers you please to test `purepack` 
use via `browserify` and with your browser's buffer objects.     
