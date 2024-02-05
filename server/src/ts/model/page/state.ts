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
			switch (role) {
			case "passenger":
				this.database.get(
					"SELECT travel_id FROM passenger WHERE mail=?",
					[this.token.mail]
				).then(httpTravelId => {
					if (!httpTravelId.body) this.transaction.sendStatus(httpTravelId.code, httpTravelId.message);
					else {
						this.database.set(
							"UPDATE passenger SET travel_id=? AND travelling=? WHERE travel_id=?",
							[null, false, httpTravelId.body[0].travel_id]
						).then(http =>{
							this.transaction.sendStatus(http.code, http.message);
						});
						this.database.set(
							"UPDATE travel SET `over`=? WHERE id=? AND `over`=?",
							[true, httpTravelId.body[0].travel_id, true]
						);
						this.database.get(
							"SELECT `departure`, `arrival`, `start` FROM travel WHERE id=?",
							[httpTravelId.body[0].travel_id]
						).then(http => {
							if (!http.body?.length) throw new Error(JSON.stringify(http));
							else {
								this.database.set(
									"INSERT INTO travel_history(`mail`, `departure`, `arrival`, `start`) VALUES(?, ?, ?, ?)",
									[this.token.mail, http.body[0].departure, http.body[0].arrival, http.body[0].start]
								);
							}
						});

					}
				});
				break;
			case "driver":
				this.database.set(
					"UPDATE travel SET `over`=? WHERE driver=? AND `over`=?",
					[true, this.token.mail, false]
				).then(http => {
					this.transaction.sendStatus(http.code, http.message);
				});
				break;
			}
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