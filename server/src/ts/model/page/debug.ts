import fs from "node:fs";
import { PageAuth } from "../PageAuth.js";
import { httpCodes } from "../../HttpTransaction.js";

export default class Debug extends PageAuth {
	public get() {
		fs.readFile("./src/debug.html", "binary", (err, file) => {
			if (err) {
				console.error(err);
				this.transaction.sendStatus(httpCodes["Service Unavailable"]);
			}
			else {
				this.transaction.response.writeHead(200);
				this.transaction.response.write(file, "binary");
				this.transaction.response.end();
			}
		});
	}
	public post() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
	public put() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
	public delete() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
	public patch() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}    
}