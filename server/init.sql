DELIMITER ";"
DROP DATABASE IF EXISTS cvp;

CREATE DATABASE cvp;
USE "cvp";

CREATE TABLE towns (
	`name` VARCHAR(100) NOT NULL PRIMARY KEY,
	`code` int NOT NULL
);

CREATE TABLE stops (
	`id` int PRIMARY KEY,
	`departure` VARCHAR(100) REFERENCES towns(`name`),
	`arrival` VARCHAR(100) REFERENCES towns(`name`),
	`mac` VARCHAR(17) NOT NULL
);

CREATE TABLE profile (
	`role` ENUM("driver", "passenger") DEFAULT NULL,
	`name` text DEFAULT NULL,
	`mail` VARCHAR(320) NOT NULL PRIMARY KEY,
	`password` text NOT NULL,
	`town` VARCHAR(100) REFERENCES towns(`name`),
	`phone` text DEFAULT NULL,
	`registration` datetime DEFAULT CURRENT_TIMESTAMP,
	`banned` boolean DEFAULT false
);

CREATE TABLE driver (
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`passengers` int DEFAULT 0,
	`numberplate` text NOT NULL,
	`mac` VARCHAR(17) NOT NULL
);

CREATE TABLE travel (
	`id` int PRIMARY KEY AUTO_INCREMENT,
	`driver` VARCHAR(320) REFERENCES driver(mail) ON DELETE CASCADE,
	`departure` VARCHAR(100) REFERENCES towns(`name`),
	`arrival` VARCHAR(100) REFERENCES towns(`name`),
	`seats` int NOT NULL,
	`registered` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`start` datetime DEFAULT NULL,
	`over` boolean DEFAULT false
);

CREATE TABLE travel_history (
	`id` int PRIMARY KEY AUTO_INCREMENT,
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`departure` VARCHAR(100) REFERENCES towns(`name`),
	`arrival` VARCHAR(100) REFERENCES towns(`name`),
	`start` datetime DEFAULT NULL
);

CREATE TABLE passenger (
	`travel_id` int DEFAULT NULL REFERENCES travel(id),
	`mail` VARCHAR(320) REFERENCES profile(mail) ON DELETE CASCADE,
	`travelling`boolean DEFAULT false
);

INSERT INTO towns (`name`, `code`) VALUES
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
('Naours', 80260),
('Longueau', 80330),
('Dury', 80480),
('Rivery', 80136),
('Camon', 80450),
('Cagny', 80330),
('Flesselles', 80260),
('Bouzincourt', 80300),
('Pont-de-Metz', 80480),
('Daours', 80800),
('Glisy', 80440),
('Saveuse', 80470),
('Bacouel-sur-Selle', 80480),
('Poulainville', 80320),
('Saint-Fuscien', 80680),
('Vers-sur-Selles', 80480),
('Cachy', 80800),
('Dreuil-lès-Amiens', 80470);


INSERT INTO stops (`id`, `departure`, `arrival`, `mac`) VALUES
(496, 'Rivery', 'Amiens', 'FB:86:61:5A:84:6B'),
(497, 'Camon', 'Amiens', 'D7:07:FC:B6:E4:E7'),
(498, 'Dury', 'Amiens', 'CA:0B:99:7B:2B:F7');