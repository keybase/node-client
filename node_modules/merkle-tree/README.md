# node-merkle-tree

A JS Merkle Tree implementation, as used by keybase.

## Install

```
npm install merkle-tree
```

And then

```javascript
var Base = require('merkle-tree').Base;
```

## Testing

```
make test
```

All tests should pass.

## API

This module is just a library, and for it to do anything useful, you'll have to subclass
the `Base` class required above. As an example, we provide a subclass of a Merkle-Tree
that lives in memory, which can be accessed as follows:

```javascript
var merkle_mod = require('merkle-tree');

// M = the number of children per interior node.
// N = the maximum number of leaves before a resplit.
var config = new merkle_mod.Config({ N : 4, M : 16 });
var myTree = new merkle_mod.MemTree(config);

// Keys are hashes expressed as hex strings.
var key = "961b6dd3ede3cb8ecbaacbd68de040cd78eb2ed5889130cceb4c49268ea4d506";
var value = { "foo" : 10 };

// We're just inserting one, but you can insert as many as you'd like.
myTree.upsert({'key' : key, 'value' : value}, function(err, new_root_hash) {
	// Finding by default checks the hashes on all interior nodes down the tree.
	// If you want to speed up your 'finds', then you can pass `skip_verify : true`
	// to your find.
	myTree.find({'key' : key, 'skip_verify' : false}, function(err, val2) {
		assert.equal(value, val2);
	});
});


// You can either build a tree one key/value pair at a time, as above, or
// you can build the whole thing at once.
var data = new merkle_mod.SortedMap({
  "list": [
     ["aabbcc", "dog" ],
     ["ddccee", "cat" ],
     ["00aa33", "bird" ]
  ]
});
myTree.build({"sorted_map" : data }, function (err) {
	console.log("done!");
});
```

To review, the Merkle Tree module provides the following classes:

  - `Config` -- A configuration object that controls the shape of the tree.
  - `SortedMap` -- A sorted map of key/value pairs that used for inputting a whole bunch of data at a time,
     and is also used internally.
  - `Base` -- A base, abstract tree implementation that needs to specialized.
  - `MemTree` -- A speciailization of `Base`; all data lives in memory and disappears when the process ends.

The `Base` class has the following method calls:

  - `build({sortedMap}, cb)` --- Build a tree from scratch using the given sorted map of data, and callback
     when done.
  - `upsert({key,value,[txinfo]}, cb)` --- Update or insert the given value at the given key.  Provide optional
     `txinfo` that is passed to the storage engine.
  - `find({key}, cb)` --- Find the given key in the Merkle tree, starting from the root and going down.

## How to Make an On-Disk Tree

The [keybase server](https://keybase.io) stores its Merkle tree on disk.  It
implements the following methods of the `Base` class to do so:

  - `hash_fn(s)` -- A function to hash an interior node into a key.  Return the hex-string hash of the
    given string.  I'd just use SHA512: `require('crypto').createHash('SHA512').update(s).digest('hex')`.
  - `store_node({key, obj, obj_s}, cb)`  --- Store the node value `obj` under the key `key`.  For convenience,
    you are also passed `obj_s`, the stringification of the object.
  - `lookup_node({key},cb)` --- Read from disk the node whose key is key.  Callback with the parsed
    (not stringified) object
  - `lookup_root(cb)` --- Should callback with the hash of the most recent tree root.
  - `commit_root({key,txinfo}, cb)` --- Store the root hash to disk, optionally with the `txinfo`
    transaction info annotation.

For an example of how to do this, see the simple [MemTree](https://github.com/keybase/node-merkle-tree/blob/master/src/mem.iced) class.
