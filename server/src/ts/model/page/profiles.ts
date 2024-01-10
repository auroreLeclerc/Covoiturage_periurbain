import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class Profiles extends PageEnforcedAuth {
	protected getExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	protected postExecution() {
		this.database.getProfile(this.token.mail).then(role => {
			const select = role === "driver" ? ", numberplate, mac" : "";
			this.database.get(`SELECT name, ${select} FROM profile INNER JOIN ${role} ON profile.mail = ${role}.mail WHERE ${role}.mail = ?`, [this.posted.mail]).then(http => {
				if (!http.body) {
					this.transaction.sendStatus(http.code, http.message);
				}
				else this.transaction.response.end(JSON.stringify(http.body[0]));
			});
		});
	}
	protected putExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	protected deleteExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	protected patchExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
}