import fs from "fs";
import config = require( "./config.json");
if (config.main.server.hostname === "localhost") console.warn("Localhost does not equal 127.0.0.1 and I don't know why. But you can see the consequences of that in AVD where 10.0.2.2 won't work.");
import https from "node:https";
import http from "node:http";
process.title = "covoiturage_periurbain_server";
export interface Certificates {
	key: Buffer,
	cert: Buffer
}
const certificates: Certificates = {
	key: fs.readFileSync("./src/ssl/key.pem"),
	cert: fs.readFileSync("./src/ssl/cert.pem")
};
import { DataBaseHelper } from "./src/ts/DataBaseHelper.js";
import { Account } from "./src/ts/model/pages/account.js";
import { httpCodes, sendStatus } from "./src/ts/httpCodes.mjs";

const database = new DataBaseHelper(
	config.main.database.host, 
	config.main.database.user, 
	config.main.database.password,
);

export type Token = {
	name: string,
	mail: string,
	creation: Date
}

const server = config.main.server.secure ? https.createServer(certificates) : http.createServer();

database.start().then(name => {
	console.log("🧑‍💻 mariadb", name);
	server.on("request", (request, response) => {
		console.log(request.method, request.url);
		response.setHeader("Access-Control-Allow-Origin", "*");
		response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
		response.setHeader("Access-Control-Allow-Methods","HEAD, PUT, POST, GET, DELETE, OPTIONS, PATCH"); // https://www.reddit.com/r/node/comments/i5u4m3/comment/g0rpn67/?utm_source=share&utm_medium=web2x&context=3
		let body = "";

		request.on("data", (data) => {
			body += data;
		});
		request.on("end", () => {

			let posted: {[key: string]: string} = {};
			try {
				posted = JSON.parse(body);
			} catch (error) {
				for (const element of body.split("&")) {
					const splited = element.split("=");
					posted[splited[0]] = splited[1];
				}
			}

			if (request.method === "OPTIONS") {
				sendStatus(response, httpCodes.OK);
			}
			else {
				if (request.url === "/account") {
					const account = new Account(request, response, certificates, database, posted);
					switch (request.method) {
					case "POST":
						account.post();
						break;
					case "PUT":
						account.put();
						break;
					case "GET":
						account.get();
						break;
					case "DELETE":
						account.delete();
						break;
					case "PATCH":
						account.patch();
						break;
					default:
						sendStatus(response, httpCodes["Method Not Allowed"]);
						break;
					}
				}
				else if (request.url === "/debug") {
					fs.readFile("./debugTester.html", "binary", (err, file) => {
						response.writeHead(200);
						response.write(err ?? file, "binary");
						response.end();
					});
				}
				else {
					sendStatus(response, httpCodes["Not Implemented"]);
				}
			}
		});
	});
}).catch(error => {
	console.error("🧑‍💻🧑‍🔧 Is mariadb service started ?");
	throw error;
});

server.listen(config.main.server.port, config.main.server.hostname, () => {
	console.log(`🧑‍💻 Listening on ${config.main.server.secure ? "https" : "http"}://${config.main.server.hostname}:${config.main.server.port}`);
});