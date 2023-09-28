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
	`id` int NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
	`role` ENUM("driver", "passenger") NOT NULL,
	`surname` text NOT NULL DEFAULT "N/A",
	`name` text NOT NULL DEFAULT "N/A",
	`travel_id` int DEFAULT NULL REFERENCES travel(id),
	`town` text NOT NULL DEFAULT "N/A",
	`phone` text DEFAULT NULL,
	`mail` text DEFAULT NULL,
	`registration` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`banned` boolean NOT NULL DEFAULT false
);

CREATE TABLE driver (
	`id` int REFERENCES profile(id) ON DELETE CASCADE,
	`passengers` int DEFAULT 0,
	`numberplate` text NOT NULL DEFAULT "XX-000-XX"
);

CREATE TABLE passenger (
	`id` int REFERENCES profile(id) ON DELETE CASCADE,
	`travelling`boolean DEFAULT false
);
