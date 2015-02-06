#!/bin/sh

D=`dirname $0`
T1=`$D/test.js`
T2=`tty`
if [ "$T1" = "$T2" ] ; then
  exit 0
else 
  echo "FAILURE; TTY mismatch: $T1 != $T2"
  exit 1
fi
