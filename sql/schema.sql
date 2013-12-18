
CREATE TABLE IF NOT EXISTS `users` (
	`uid` CHAR(32) NOT NULL PRIMARY KEY,
	`username` VARCHAR(128) NOT NULL,
	`ctime` DATETIME NOT NULL,
	`mtime` DATETIME NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS users_username_index_1 ON users (`username`);

CREATE TABLE IF NOT EXISTS `key_bundles` (
  `ukbid` char(32) NOT NULL DEFAULT '' PRIMARY KEY,
  `kid` char(70) NOT NULL DEFAULT '',
  `key_type` int(11) NOT NULL DEFAULT '0',
  `key_fingerprint` char(128) NOT NULL DEFAULT '',
  `uid` char(32) NOT NULL,
  `bundle` text NOT NULL,
  `comment` text,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `status` int(11) NOT NULL DEFAULT '0',
  `self_signed` tinyint(1) NOT NULL DEFAULT '0',
  `mtime` datetime NOT NULL,
  `ctime` datetime NOT NULL,
  FOREIGN KEY (`uid`) REFERENCES `users` (`uid`) 
);

CREATE INDEX IF NOT EXISTS key_bundles_index_1 ON key_bundles (`kid`, `key_type`);
CREATE INDEX IF NOT EXISTS key_bundles_index_2 ON key_bundles (`uid`);
