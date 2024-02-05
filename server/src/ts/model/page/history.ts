import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class History extends PageEnforcedAuth {
	protected getExecution() {
		this.database.getProfile(this.token.mail).then(role => {
			const sql = role === "driver" ? "FROM travel WHERE mail=? AND `over`=?" : "FROM travel_history WHERE mail=?";
			this.database.get(
				"SELECT departure, arrival, `start` " + sql,
				[this.token.mail, true]
			).then(http => {
				if (!http.body) {
					this.transaction.sendStatus(http.code, http.message);
				}
				else this.transaction.response.end(JSON.stringify(http.body));
			});
		});
	}
	protected postExecution() {
		this.database.getProfile(this.posted.mail).then(role => {
			switch (role) {
			case "driver":
				this.database.get(
					"SELECT departure, arrival, `start` FROM travel WHERE driver=? AND `over`=?",
					[this.posted.mail, true]
				).then(http => {
					if (!http.body) {
						this.transaction.sendStatus(http.code, http.message);
					}
					else this.transaction.response.end(JSON.stringify(http.body));
				});
				break;
			case "passenger":
				this.database.get(
					"SELECT departure, arrival, `start` FROM travel_history WHERE mail=?",
					[this.posted.mail]
				).then(http => {
					if (!http.body) {
						this.transaction.sendStatus(http.code, http.message);
					}
					else this.transaction.response.end(JSON.stringify(http.body));
				});
				break;
			}
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