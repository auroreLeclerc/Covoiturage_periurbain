import fs from "fs";
import config from "./config.json" assert {type: "json"};
import https from "https";
import mariadb from "mariadb";
process.title = "covoiturage_periurbain_server";
const certificates = {
	key: fs.readFileSync("./ssl/key.pem"),
	cert: fs.readFileSync("./ssl/cert.pem")
};

const server = https.createServer(certificates, (request, response) => {
	if (request.method === "POST") {
		switch (request.url) {
		case "/": {
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

				const pool = mariadb.createPool({
					host: config.main.database.host, 
					user: config.main.database.user, 
					password: config.main.database.user,
				});

				pool.getConnection().then(connection => {
					connection.batch(
						"INSERT INTO cvp.profile(surname, name, role, town) VALUES(?, ?, ?, ?)",
						[posted.surname, posted.name, posted.role, posted.town]
					).then(result => {
						console.log(result);
  
						fetch("https://http.cat/201.jpg").then(fetched => 
							fetched.arrayBuffer().then(buffer => {
								response.writeHead(201, { "Content-Type": "image/jpeg" }).end(new Uint8Array(buffer), "binary");
							})
						);
					});
				});


				// console.log(posted);
			});	
		} break;
		
		default:
			fetch("https://http.cat/404.jpg").then(fetched => 
				fetched.arrayBuffer().then(buffer => {
					response.writeHead(404, { "Content-Type": "image/jpeg" }).end(new Uint8Array(buffer), "binary");
				})
			);
			break;
		}
	}
	else {
		fetch("https://http.cat/405.jpg").then(fetched => 
			fetched.arrayBuffer().then(buffer => {
				response.writeHead(405, { "Content-Type": "image/jpeg" }).end(new Uint8Array(buffer), "binary");
			})
		);
	}
});

server.listen(config.main.server.port, config.main.server.hostname, () => {
	console.log(`Listening on ${config.main.server.hostname}:${config.main.server.port}`);
});
  