import fs from "fs";
import config from "./config.json" assert {type: "json"};
import https from "https";
import mariadb from "mariadb";
process.title = "covoiturage_periurbain_server";
const certificates = {
	key: fs.readFileSync("./ssl/key.pem"),
	cert: fs.readFileSync("./ssl/cert.pem")
};
import bcrypt from "bcrypt";

const pool = mariadb.createPool({
	host: config.main.database.host, 
	user: config.main.database.user, 
	password: config.main.database.user,
});

pool.getConnection().then(connection => {
	console.log("🧑‍💻 mariadb", connection.constructor.name);
	const server = https.createServer(certificates, (request, response) => {
		response.setHeader("Access-Control-Allow-Origin", "*");
		response.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
		response.setHeader("Access-Control-Allow-Headers", "Content-Type");
		let body = "";

		request.on("data", (data) => {
			body += data;
		});
		request.on("end", () => {
			const posted = {};
			for (const element of body.split("&")) {
				const splited = element.split("=");
				posted[splited[0]] = splited[1];
			}

			switch (request.method) {
			case "PUT":
				switch (request.url) {
				case "/account":
					bcrypt.hash(posted.password, 10).then(hash => {
						connection.batch(
							"INSERT INTO cvp.profile(surname, name, mail, password, role, town) VALUES(?, ?, ?, ?, ?, ?)",
							[posted.surname, posted.name, posted.mail, hash, posted.role, posted.town]
						).then(result => {
							console.log(result);
							response.writeHead(201, { "Content-Type": "text/plain" }).end("Created");
						}).catch(error => {
							console.error(error);
							switch (error?.code) {
							case "ER_BAD_NULL_ERROR":
								response.writeHead(400, { "Content-Type": "text/plain" }).end(error.sqlMessage);
								break;

							case "ER_DUP_ENTRY":
								response.writeHead(409, { "Content-Type": "text/plain" }).end(error.sqlMessage);
								break;
								
							default:
								response.writeHead(406, { "Content-Type": "text/plain" }).end(error.sqlMessage);
								break;
							}
						});
					}).catch(error => {
						console.error(error);
						response.writeHead(400, { "Content-Type": "text/plain" }).end(error.toString());
					});
					break;
						
				default:
					response.writeHead(404, { "Content-Type": "text/plain" }).end("Not Found");
					break;
				}
				break;

			case "POST":
				connection.query("SELECT password, banned FROM cvp.profile WHERE mail = ?", [posted.mail]).then(rows => {
					if (rows.lenght === 0) {
						response.writeHead(401, { "Content-Type": "text/plain" }).end("Unauthenticated");
					}
					else if (rows[0].banned) {
						response.writeHead(403, { "Content-Type": "text/plain" }).end("Forbidden");
					}
					else {
						bcrypt.compare(posted.password, rows[0].password).then(result => {
							if (result) {
								switch (request.url) {								
								case "/account":
									connection.query("SELECT role, surname, name, town, phone FROM cvp.profile WHERE mail = ?", [posted.mail]).then(rows => {
										response.writeHead(200, { "Content-Type": "text/plain" }).end(JSON.stringify(rows[0]));
									});

									
									break;
										
								default:
									response.writeHead(404, { "Content-Type": "text/plain" }).end("Not Found");
									break;
								}
							}
							else {
								response.writeHead(401, { "Content-Type": "text/plain" }).end("Unauthenticated");
							}
						}).catch(error => {
							console.log(error);
							response.writeHead(400, { "Content-Type": "text/plain" }).end("Bad Request");
						});
					}
				});
				break;

			case "OPTIONS":
				response.writeHead(204, { "Content-Type": "text/plain" }).end("No Content");
				break;

			default:
				response.writeHead(405, { "Content-Type": "text/plain" }).end("Method Not Allowed");
				break;
			}
		});
	});

	server.listen(config.main.server.port, config.main.server.hostname, () => {
		console.log(`🧑‍💻 Listening on https://${config.main.server.hostname}:${config.main.server.port}`);
	});
});