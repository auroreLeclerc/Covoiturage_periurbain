import { Token } from "../../../../main.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { PageAuth } from "../PageAuth.js";
import { httpCodes, sendStatus } from "../../httpCodes.mjs";

export class Account extends PageAuth {
	public get() {
		if (this.authenticate()) this.getExecution();
	}
	private getExecution() {
		this.database.get("SELECT role, name, town, phone FROM cvp.profile WHERE mail = ?", [this.token.mail]).then(http => {
			if (!http.body) {
				sendStatus(this.response, http.code, http.message);
			}
			else this.response.end(JSON.stringify(http.body[0]));
		});
	}
	/**
	 * @note connection
	 */
	public post() {
		this.database.get("SELECT password, banned FROM cvp.profile WHERE mail = ?", [this.posted.mail]).then(http => {
			if (!http.body) {
				sendStatus(this.response, http.code, http.message);
			}
			else if (http.body.length === 0) {
				sendStatus(this.response, httpCodes["Not Acceptable"]);
			}
			else if (http.body[0].banned) {
				sendStatus(this.response, httpCodes["Forbidden"]);
			}
			else {
				bcrypt.compare(this.posted.password, String(http.body[0].password)).then(result => {
					if (result) {
						const token = jwt.sign({
							name: this.posted.name,
							mail: this.posted.mail,
							creation: new Date()
						} as Token, this.certificates.key, { algorithm: "RS256" });
						this.response.end(`Bearer ${token}`);
					}
					else {
						sendStatus(this.response, httpCodes["Not Acceptable"]);
					}
				});
			}
		});
	}
	public put() {
		bcrypt.hash(this.posted.password, 10).then(hash => {
			this.database.set(
				"INSERT INTO cvp.profile(name, mail, password) VALUES(?, ?, ?)",
				[this.posted.name, this.posted.mail, hash]
			).then(http => {
				sendStatus(this.response, http.code, http.message);
			});
		}).catch(error => {
			console.error(error);
			sendStatus(this.response, httpCodes["Bad Request"], JSON.stringify(this.posted));
		});
	}
	public delete() {
		sendStatus(this.response, httpCodes["Not Implemented"]);
	}
	public patch() {
		if (this.authenticate()) this.patchExecution();
	}
	private patchExecution() {
		this.database.set(
			"UPDATE cvp.profile SET role=?, town=? WHERE mail=?",
			[this.posted.role, this.posted.town, this.token.mail]
		).then(http => {
			sendStatus(this.response, http.code, http.message);
		});
	}
    
}