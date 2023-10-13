import fs from "fs";
import config = require( "./config.json");
import https from "https";
process.title = "covoiturage_periurbain_server";
const certificates = {
	key: fs.readFileSync("./src/ssl/key.pem"),
	cert: fs.readFileSync("./src/ssl/cert.pem")
};
import bcrypt from "bcrypt";
import { DataBaseHelper } from "./src/ts/DataBaseHelper.js";

import express from "express";
import session from "express-session";
const app = express();
app.use(session({
	secret: "keyboard cat",
	resave: false,
	saveUninitialized: true,
	cookie: { secure: true }
}));
  
const httpsServer = https.createServer(certificates, app);

const database = new DataBaseHelper(
	config.main.database.host, 
	config.main.database.user, 
	config.main.database.password,
);

database.start().then(name => {
	console.log("🧑‍💻 mariadb", name);

	app.use((request, response, next) => {
		if (config.main.debug) {
			response.setHeader("Access-Control-Allow-Origin", "*");
			response.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
			response.setHeader("Access-Control-Allow-Headers", "Content-Type");
		}
		let body = "";

		request.on("data", (data) => {
			body += data;
		});
		request.on("end", () => {
			const posted: {[key: string]: string} = {};
			for (const element of body.split("&")) {
				const splited = element.split("=");
				posted[splited[0]] = splited[1];
			}

			switch (request.method) {
			case "PUT":
				switch (request.url) {
				case "/account":
					bcrypt.hash(posted.password, 10).then(hash => {
						database.insert(
							"INSERT INTO cvp.profile(surname, name, mail, password, role, town) VALUES(?, ?, ?, ?, ?, ?)",
							[posted.surname, posted.name, posted.mail, hash, posted.role, posted.town]
						).then(http =>
							response.status(http.code).send(http.message)
						);
					}).catch(error => {
						console.error(error);
						response.status(400).send(error.toString());
					});
					break;
						
				default:
					response.status(404).send("Not Found");
					break;
				}
				break;

			case "POST":
				// request.session.user = "test";

				database.select("SELECT password, banned FROM cvp.profile WHERE mail = ?", [posted.mail]).then(http => {
					if (!http.body) {
						response.status(http.code).send(http.message);
					}
					else if (http.body.length === 0) {
						response.status(401).send("Unauthenticated");
					}
					else if (http.body[0].banned) {
						response.status(403).send("Forbidden");
					}
					else {
						bcrypt.compare(posted.password, http.body[0].password).then(result => {
							if (result) {
								switch (request.url) {								
								case "/account":
									database.select("SELECT role, surname, name, town, phone FROM cvp.profile WHERE mail = ?", [posted.mail]).then(http => {
										if (!http.body) {
											response.status(http.code).send(http.message);
										}
										else response.json(http.body[0]);
									});

									
									break;
										
								default:
									response.status(404).send("Not Found");
									break;
								}
							}
							else {
								response.status(401).send("Unauthenticated");
							}
						}).catch(error => {
							console.log(error);
							response.status(400).send("Bad Request");
						});
					}
				});
				break;

			case "OPTIONS":
				response.status(204).send("No Content");
				break;

			default:
				response.status(405).send("Method Not Allowed");
				break;
			}
		});
	});

	httpsServer.listen(config.main.server.port, config.main.server.hostname, () => {
		console.log(`🧑‍💻 Listening on https://${config.main.server.hostname}:${config.main.server.port}`);
	});
});