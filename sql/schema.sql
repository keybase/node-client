
CREATE TABLE IF NOT EXISTS `kvstore` (
  `type` CHAR(2) NOT NULL,
  `key` VARCHAR(100) NOT NULL,
  `value` BLOB,
  CONSTRAINT `kvstore_primary_key` PRIMARY KEY (`type`, `key`)
);

CREATE TABLE IF NOT EXISTS `lookup` (
  `type` CHAR(2) NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  `key`  VARCHAR(100) NOT NULL,
  CONSTRAINT `lookup_primary_key` PRIMARY KEY (`type`, `key`),
  CONSTRAINT `lookup_foreign_key_1` FOREIGN KEY (`key`) REFERENCES `kvstore` (`key`)
);

CREATE INDEX IF NOT EXISTS `lookup_index_1` ON `lookup`(`key`);