import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class History extends PageEnforcedAuth {
	protected getExecution() {
        
		this.database.getProfile(this.token.mail).then(role => {
			const sql = role === "driver" ? "SELECT departure, arrival, `start` FROM travel WHERE mail=? AND over=?" : "SELECT driver, departure, arrival, `start` FROM travel INNER JOIN travel.id = passenger.travel_id WHERE passenger.mail=? AND travel.over=?";
			this.database.get(
				sql,
				[this.posted.mail, true]
			).then(http => {
				if (!http.body) {
					this.transaction.sendStatus(http.code, http.message);
				}
				else this.transaction.response.end(JSON.stringify(http.body[0]));
			});
		});
	}
	protected postExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
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