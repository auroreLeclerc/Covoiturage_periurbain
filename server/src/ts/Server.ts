import fs from "node:fs";
import https from "node:https";
import http from "node:http";
import { Certificates } from "../../main.js";
import { Page } from "./model/Page.js";
import { DataBaseHelper } from "./DataBaseHelper.js";
import { HttpTransaction, httpCodes } from "./HttpTransaction.js";

export class Server {
	/**
	 * @description Without extension file
	 */
	private pageFileNames: string[];
	private database: DataBaseHelper;
	private server: http.Server;
	private certificates: Certificates;
	private secure: boolean;

	constructor(database: DataBaseHelper, certificates: Certificates, secure = false) {
		this.database = database;
		const files = fs.readdirSync("./src/ts/model/page/");
		this.pageFileNames = files.map(file => file.slice(0, -3));
		this.server = secure ? https.createServer(certificates) : http.createServer();
		this.certificates = certificates;
		this.secure = secure;
		this.onRequest();
	}

	private onRequest() {
		this.server.on("request", (request, response) => {
			console.log(request.method, request.url);
			response.setHeader("Access-Control-Allow-Origin", "*");
			response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
			response.setHeader("Access-Control-Allow-Methods","HEAD, PUT, POST, GET, DELETE, OPTIONS, PATCH"); // https://www.reddit.com/r/node/comments/i5u4m3/comment/g0rpn67/?utm_source=share&utm_medium=web2x&context=3
			let body = "";

			request.on("data", (data) => {
				body += data;
			});
			request.on("end", () => {
				const transaction = new HttpTransaction(request, response);
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
					transaction.sendStatus(httpCodes["No Content"]);
				}
				else if (request.url && this.pageFileNames.indexOf(request.url.slice(1)) > -1) {
					import(`./model/page/${request.url.slice(1)}.js`).then(pageClass => {
						const page: Page = new pageClass.default(transaction, this.certificates, this.database, posted);
						switch (request.method) {
						case "POST":
							page.post();
							break;
						case "PUT":
							page.put();
							break;
						case "GET":
							page.get();
							break;
						case "DELETE":
							page.delete();
							break;
						case "PATCH":
							page.patch();
							break;
						default:
							transaction.sendStatus(httpCodes["Method Not Allowed"]);
							break;
						}
					});
				}
				else transaction.sendStatus(httpCodes["Not Found"]);
			});
		});
	}

	public start(hostname: string, port: number) {
		this.server.listen(port, hostname, () => {
			console.log(`🧑‍💻 Listening on ${this.secure ? "https" : "http"}://${hostname}:${port}`);
		});
	}
}