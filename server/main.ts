import fs from "fs";
import config = require( "./config.json");
import https from "https";
import jwt from "jsonwebtoken";
process.title = "covoiturage_periurbain_server";
const certificates = {
	key: fs.readFileSync("./src/ssl/key.pem"),
	cert: fs.readFileSync("./src/ssl/cert.pem")
};
import bcrypt from "bcrypt";
import { DataBaseHelper } from "./src/ts/DataBaseHelper.js";

import express from "express";
import cors from "cors";
const app = express();
  
const httpsServer = https.createServer(certificates, app);

const database = new DataBaseHelper(
	config.main.database.host, 
	config.main.database.user, 
	config.main.database.password,
);

declare module "jsonwebtoken" {
    export interface JwtPayload {
		user: string,
		expiration: Date
    }
}

database.start().then(name => {
	console.log("🧑‍💻 mariadb", name);

	// eslint-disable-next-line @typescript-eslint/no-unused-vars
	app.use(cors(), (request, response, _next) => {
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

			console.log(request.method, request.url);
			switch (request.method) {
			case "POST":
				switch (request.url) {
				case "/account":
					database.select("SELECT password, banned FROM cvp.profile WHERE mail = ?", [posted.mail]).then(http => {
						if (!http.body) {
							response.status(http.code).send(http.message);
						}
						else if (http.body.length === 0) {
							response.sendStatus(406);
						}
						else if (http.body[0].banned) {
							response.sendStatus(403);
						}
						else {
							bcrypt.compare(posted.password, http.body[0].password).then(result => {
								if (result) {
									const token = jwt.sign({
										user: posted.mail,
										expiration: new Date()
									} as jwt.JwtPayload, certificates.key, { algorithm: "RS256" });
									response.send(`Bearer ${token}`);
								}
								else {
									response.sendStatus(406);
								}
							});
						}
					});
					break;
							
				default:
					response.sendStatus(404);
					break;
				}
				break;

			case "PUT":
				switch (request.url) {
				case "/account":
					bcrypt.hash(posted.password, 10).then(hash => {
						database.insert(
							"INSERT INTO cvp.profile(surname, name, mail, password, role, town) VALUES(?, ?, ?, ?, ?, ?)",
							[posted.surname, posted.name, posted.mail, hash, posted.role, posted.town]
						).then(http => {
							response.status(http.code).send(http.message);
						});
					}).catch(error => {
						console.error(error);
						response.status(400).send(posted);
					});
					break;
						
				default:
					response.sendStatus(404);
					break;
				}
				break;

			case "GET": {
				const token = request.get("Authorization")?.split(" ")[1];
				if (token) {
					jwt.verify(token, certificates.key, (err, decoded) => {
						if (err || !decoded || typeof decoded === "string") response.status(406).send("Authorization Header Corrupted");
						else if (new Date(decoded.expiration).getFullYear() - new Date().getFullYear() != 0) response.status(406).send("Authorization Header Expired");
						else {
							switch (request.url) {								
							case "/account":
								database.select("SELECT role, surname, name, town, phone FROM cvp.profile WHERE mail = ?", [decoded.user]).then(http => {
									if (!http.body) {
										response.status(http.code).send(http.message);
									}
									else response.json(http.body[0]);
								});
								break;
									
							default:
								response.sendStatus(404);
								break;
							}
						}
					});
				}
				else if (request.get("Authorization")) response.status(412).send("Bearer Syntax Error");
				else response.status(412).send("Authorization Header Missing");
			}
				break;

			case "OPTIONS":
				response.sendStatus(204);
				break;

			default:
				response.sendStatus(405);
				break;
			}
		});
	});

	httpsServer.listen(config.main.server.port, config.main.server.hostname, () => {
		console.log(`🧑‍💻 Listening on https://${config.main.server.hostname}:${config.main.server.port}`);
	});
});