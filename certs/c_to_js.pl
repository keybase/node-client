#!/usr/bin/env perl

while (<>) {
	if (m#/\*\s+(.*)\s+\*/#) { print "\t\"$1\":\n" } 
	elsif (m#^(.*)\"$#) { print "$1\" +\n"; } 
	else  { print $_; } 
}
