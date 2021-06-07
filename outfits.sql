CREATE TABLE IF NOT EXISTS `player_outfits` (
  `owner` varchar(60) NOT NULL,
  `slot` tinyint NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `clothes` mediumtext,
  PRIMARY KEY (`owner`,`slot`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;