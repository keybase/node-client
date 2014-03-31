#!/bin/sh

echo "if (typeof(console.assert) !== 'function') { console.assert = function () {}; }" > ../main.js

for file in ../lib/*.js
do
	b=`basename $file`
	out=../outlib/$b
	iced runfile.iced $file $out
	stem=`basename -s .js $b`
	echo "exports.$stem = require('./outlib/$stem');" >> ../main2.js
done

