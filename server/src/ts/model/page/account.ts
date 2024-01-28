import { Token } from "../../../../main.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { PageAuth } from "../PageAuth.js";
import { httpCodes } from "../../HttpTransaction.js";

export default class Account extends PageAuth {
	public get() {
		if (this.authenticate()) this.getExecution();
	}
	private getExecution() {
		this.database.getProfile(this.token.mail).then(role => {
			const select = role === "driver" ? ", numberplate, mac" : ", travel_id";
			this.database.get(`SELECT ${role}.mail, role, name, town, phone ${select} FROM profile INNER JOIN ${role} ON profile.mail = ${role}.mail WHERE ${role}.mail = ?`, [this.token.mail]).then(http => {
				if (!http.body) {
					this.transaction.sendStatus(http.code, http.message);
				}
				else this.transaction.response.end(JSON.stringify(http.body[0]));
			});
		}).catch(error => {
			this.transaction.sendStatus(httpCodes["Upgrade Required"], error.toString());
		});
	}
	/**
	 * @note connection
	 */
	public post() {
		this.database.get("SELECT password, banned FROM profile WHERE mail = ?", [this.posted.mail]).then(http => {
			if (!http.body) {
				this.transaction.sendStatus(http.code, http.message);
			}
			else if (http.body.length === 0) {
				this.transaction.sendStatus(httpCodes["Not Acceptable"]);
			}
			else if (http.body[0].banned) {
				this.transaction.sendStatus(httpCodes["Forbidden"]);
			}
			else {
				bcrypt.compare(this.posted.password, String(http.body[0].password)).then(result => {
					if (result) {
						const token = jwt.sign({
							mail: this.posted.mail,
							creation: new Date()
						} as Token, this.certificates.key, { algorithm: "RS256" });
						this.transaction.response.end(`Bearer ${token}`);
					}
					else {
						this.transaction.sendStatus(httpCodes["Not Acceptable"]);
					}
				});
			}
		});
	}
	public put() {
		bcrypt.hash(this.posted.password, 10).then(hash => {
			this.database.set(
				"INSERT INTO profile(mail, password) VALUES(?, ?)",
				[this.posted.mail, hash]
			).then(http => {
				this.transaction.sendStatus(http.code, http.message);
			});
		}).catch(error => {
			console.error(error);
			this.transaction.sendStatus(httpCodes["Bad Request"], JSON.stringify(this.posted));
		});
	}
	public delete() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	public patch() {
		if (this.authenticate()) this.patchExecution();
	}
	private patchExecution() {
		this.database.set(
			"UPDATE profile SET role=?, name=?, town=?, phone=? WHERE mail=?",
			[this.posted.role, this.posted.name, this.posted.town, this.posted.phone, this.token.mail]
		).then(http => {
			if (http.code === 201) {
				this.database.getProfile(this.token.mail).then(role => {
					switch (role) {
					case "driver":
						this.database.set(
							"INSERT INTO driver(numberplate, mac, mail) VALUES(?, ?, ?)",
							[this.posted.numberplate, this.posted.mac, this.token.mail]
						).then(http2 => {
							this.transaction.sendStatus(http2.code, http2.message);
						});
						break;
					
					case "passenger":
						this.database.set(
							"INSERT INTO passenger(mail) VALUES(?)",
							[this.token.mail]
						).then(http2 => {
							this.transaction.sendStatus(http2.code, http2.message);
						});
						break;
					}
				}).catch(error => {
					this.transaction.sendStatus(httpCodes["Upgrade Required"], error.toString());
				});
			}
			else this.transaction.sendStatus(http.code, http.message);
		});
	}
}