
CREATE TABLE IF NOT EXISTS `kvstore` (
  `type` CHAR(2) NOT NULL,
  `key` VARCHAR(100) NOT NULL,
  `value` BLOB,
  CONSTRAINT `kvstore_primary_key` PRIMARY KEY (`type`, `key`)
);

CREATE TABLE IF NOT EXISTS `lookup` (
  `name_type` INTEGER(4) NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  `key_type` CHAR(2) NOT NULL,
  `key`  VARCHAR(100) NOT NULL,
  CONSTRAINT `lookup_primary_key` PRIMARY KEY (`name_type`, `name`),
  CONSTRAINT `lookup_foreign_key_1` FOREIGN KEY (`key_type`,`key`) REFERENCES `kvstore` (`type`, `key`)
);

CREATE INDEX IF NOT EXISTS `lookup_index_1` ON `lookup`(`key_type`, `key`);

CREATE TABLE IF NOT EXISTS `key_import_log` (
  `fingerprint` CHAR(40) NOT NULL PRIMARY KEY,
  `uid` CHAR(32) NOT NULL,
  `ctime` INTEGER(8) NOT NULL,
  `mtime` INTEGER(8) NOT NULL,
  `state` INTEGER(4) NOT NULL
);

CREATE INDEX IF NOT EXISTS `key_import_log_index_1` ON `key_import_log` (`uid`);
CREATE INDEX IF NOT EXISTS `key_import_log_index_2` ON `key_import_log` (`state`, `mtime`);