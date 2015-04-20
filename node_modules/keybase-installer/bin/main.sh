#!/bin/sh

if [ "$NODE" = "" ] ; then
	which node > /dev/null
	if [ $? -eq 0 ] ; then NODE=node; fi
fi

if [ "$NODE" = "" ] ; then
	which nodejs > /dev/null
	if [ $? -eq 0 ] ; then NODE=nodejs; fi
fi

if [ "$NODE" = "" ]; then
	echo "Error: cannot start keybase; no version of node or nodejs found"
	exit 2
fi

$NODE ./main.js $*
