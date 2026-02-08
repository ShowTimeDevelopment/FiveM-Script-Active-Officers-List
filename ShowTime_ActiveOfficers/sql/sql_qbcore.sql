-- QBCore / QBox Database Schema
-- This table stores officer settings (callsign, UI position, visibility, opacity, scale)

CREATE TABLE IF NOT EXISTS `officer_settings` (
    `citizenid` varchar(50) NOT NULL,
    `callsign` varchar(10) DEFAULT 'N/A',
    `pos_x` float DEFAULT NULL,
    `pos_y` float DEFAULT NULL,
    `is_visible` tinyint(1) DEFAULT 0,
    `opacity` float DEFAULT 1.0,
    `scale` float DEFAULT 1.0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
