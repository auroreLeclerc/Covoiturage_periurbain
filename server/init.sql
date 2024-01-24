DELIMITER ";"
DROP DATABASE IF EXISTS cvp;

CREATE DATABASE cvp;
USE "cvp";

CREATE TABLE stops (
	`town` VARCHAR(100) NOT NULL PRIMARY KEY,
	`code` int DEFAULT NULL
);

CREATE TABLE profile (
	`role` ENUM("driver", "passenger") DEFAULT NULL,
	`name` text DEFAULT NULL,
	`mail` VARCHAR(320) NOT NULL PRIMARY KEY,
	`password` text NOT NULL,
	`town` VARCHAR(100) DEFAULT NULL REFERENCES stops(town),
	`phone` text DEFAULT NULL,
	`registration` datetime DEFAULT CURRENT_TIMESTAMP,
	`banned` boolean DEFAULT false
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
	`departure` VARCHAR(100) DEFAULT NULL REFERENCES stops(town),
	`arrival` VARCHAR(100) DEFAULT NULL REFERENCES stops(town),
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

INSERT INTO stops (`town`, `code`) VALUES
('Amiens', 80000),
('Abbeville', 80100),
('Albert', 80300),
('Montdidier', 80500),
('Péronne', 80200),
('Roye', 80700),
('Doullens', 80600),
('Corbie', 80800),
('Flixecourt', 80420),
('Moreuil', 80110),
('Ailly-sur-Somme', 80470),
('Ham', 80400),
('Rosières-en-Santerre', 80170),
('Villers-Bretonneux', 80800),
('Nesle', 80190),
('Bapaume', 62450),
('Lassigny', 60310),
('Friville-Escarbotin', 80130),
('Longueau', 80330),
('Acheux-en-Amiénois', 80560),
('Saleux', 80480),
('Boves', 80440),
('Poix-de-Picardie', 80290),
('Gamaches', 80220),
('Mers-les-Bains', 80350),
('Ailly-le-Haut-Clocher', 80690),
('Saint-Riquier', 80135),
('Querrieu', 80115),
('Cayeux-sur-Mer', 80410),
('Naours', 80260);
