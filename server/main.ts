export interface Certificates {
	key: Buffer,
	cert: Buffer
}
export type Token = {
	name: string,
	mail: string,
	creation: Date
}

import fs from "node:fs";
import config = require( "./config.json");
import { DataBaseHelper } from "./src/ts/DataBaseHelper.js";
import { Server } from "./src/ts/Server.js";

process.title = "covoiturage_periurbain_server";
if (config.main.server.hostname === "localhost") console.warn("Localhost does not equal 127.0.0.1 and I don't know why. But you can see the consequences of that in AVD where 10.0.2.2 won't work.");

const
	certificates: Certificates = {
		key: fs.readFileSync("./src/ssl/key.pem"),
		cert: fs.readFileSync("./src/ssl/cert.pem")
	},
	database = new DataBaseHelper(
		config.main.database.host, 
		config.main.database.user, 
		config.main.database.password,
	)
;

database.start().then(name => {
	console.log("🧑‍💻 mariadb", name);
	const server = new Server(database, certificates, config.main.server.secure);
	server.start(config.main.server.hostname, config.main.server.port);
	
}).catch(error => {
	console.error("🧑‍💻🧑‍🔧 Is mariadb service started ?");
	throw error;
});
