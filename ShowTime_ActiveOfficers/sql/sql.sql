CREATE TABLE IF NOT EXISTS `officer_settings` (
    `citizenid` VARCHAR(50) NOT NULL,
    `callsign` VARCHAR(10) DEFAULT 'N/A',
    `pos_x` FLOAT DEFAULT NULL,
    `pos_y` FLOAT DEFAULT NULL,
    `is_visible` TINYINT(1) DEFAULT 0,
    `opacity` FLOAT DEFAULT 1.0,
    `scale` FLOAT DEFAULT 1.0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
