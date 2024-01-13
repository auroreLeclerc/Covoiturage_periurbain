DELIMITER ";"
DROP DATABASE IF EXISTS cvp;

CREATE DATABASE cvp;
USE "cvp"; 

CREATE TABLE profile (
	`role` ENUM("driver", "passenger") NOT NULL,
	`name` text NOT NULL DEFAULT "N/A",
	`mail` VARCHAR(320) NOT NULL PRIMARY KEY,
	`password` text NOT NULL,
	`town` text DEFAULT NULL,
	`phone` text DEFAULT NULL,
	`registration` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`banned` boolean NOT NULL DEFAULT false
);

CREATE TABLE driver (
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`passengers` int DEFAULT 0,
	`numberplate` text NOT NULL DEFAULT "XX-000-XX",
	`mac` text NOT NULL DEFAULT "00:00:00:00:00:00"
);

CREATE TABLE travel (
	`id` int NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
	`driver` VARCHAR(320) REFERENCES driver(mail) ON DELETE CASCADE,
	`departure` text NOT NULL DEFAULT "N/A",
	`arrival` text NOT NULL DEFAULT "N/A",
	`seats` int NOT NULL,
	`registered` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`start` datetime DEFAULT NULL,
	`over` boolean DEFAULT false
);

CREATE TABLE passenger (
	`travel_id` int DEFAULT NULL REFERENCES travel(id),
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`travelling`boolean DEFAULT false
);