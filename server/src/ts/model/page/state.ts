import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class State extends PageEnforcedAuth {
	protected getExecution() {
		this.database.getProfile(this.token.mail).then(role => {
			const where = role === "driver" ? "WHERE driver=?" : "INNER JOIN passenger ON travel.id=passenger.travel_id WHERE passenger.mail=?";
			this.database.get(
				"SELECT travel.start FROM travel " + where,
				[this.token.mail]
			).then(http => {
				if (!http.body) {
					this.transaction.sendStatus(http.code, http.message);
				}
				else this.transaction.response.end(JSON.stringify(http.body));
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
		this.database.getProfile(this.token.mail).then(role => {
			const join = role === "driver" ? "" : "INNER JOIN passenger ON travel.id=passenger.travel_id";
			const where = role === "driver" ? "driver=?" : "passenger.mail=?";
			this.database.set(
				"UPDATE travel " + join + " SET over=? WHERE " + where,
				[true, this.token.mail]
			).then(http => {
				this.transaction.sendStatus(http.code, http.message);
			});
		});
	}
	protected patchExecution() {
		this.database.getProfile(this.token.mail).then(role => {
			const join = role === "driver" ? "" : "INNER JOIN passenger ON travel.id=passenger.travel_id";
			const where = role === "driver" ? "driver=?" : "passenger.mail=?";
			this.database.set(
				"UPDATE travel " + join + " SET start=NOW() WHERE " + where,
				[this.token.mail]
			).then(http => {
				this.transaction.sendStatus(http.code, http.message);
			});
		});
	}
}