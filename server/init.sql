DELIMITER ";"
DROP DATABASE IF EXISTS cvp;

CREATE DATABASE cvp;
USE "cvp"; 

CREATE TABLE travel (
	`id` int NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
	`departure` text NOT NULL DEFAULT "N/A",
	`arrival` text NOT NULL DEFAULT "N/A",
	`start` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`over` boolean DEFAULT false
);

CREATE TABLE profile (
	`role` ENUM("driver", "passenger") NOT NULL,
	`surname` text NOT NULL DEFAULT "N/A",
	`name` text NOT NULL DEFAULT "N/A",
	`mail` VARCHAR(320) NOT NULL PRIMARY KEY,
	`password` text NOT NULL,
	`travel_id` int DEFAULT NULL REFERENCES travel(id),
	`town` text NOT NULL DEFAULT "N/A",
	`phone` text DEFAULT NULL,
	`registration` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`banned` boolean NOT NULL DEFAULT false
);

CREATE TABLE driver (
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`passengers` int DEFAULT 0,
	`numberplate` text NOT NULL DEFAULT "XX-000-XX"
);

CREATE TABLE passenger (
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`travelling`boolean DEFAULT false
);
