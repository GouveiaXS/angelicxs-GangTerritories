
CREATE TABLE IF NOT EXISTS `angelicxs_gangterritory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang` varchar(60) DEFAULT NULL,
  `boss` varchar(60) DEFAULT NULL,
  `size` float NOT NULL DEFAULT 0,
  `value` int(11) NOT NULL DEFAULT 0,
  `locationx` float DEFAULT NULL,
  `locationy` float DEFAULT NULL,
  `locationz` float DEFAULT NULL,
  `locationw` float DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=289 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

-- ONLY REQUIRED IF Config.UseAddOnGang = true
CREATE TABLE IF NOT EXISTS `angelicxs_gangterritorylist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) DEFAULT NULL,
  `gang` varchar(60) DEFAULT NULL,
  `name` varchar(60) DEFAULT NULL,
  `boss` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=289 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;