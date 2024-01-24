import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class Travel extends PageEnforcedAuth {
	protected getExecution() { //FIXME: Not Working
		this.database.getProfile(this.token.mail).then(role => {
			switch (role) {
			case "driver":
				this.database.get(
					"SELECT `passenger.mail`, `travel.departure`, `travel.arrival`, `travel.registered`, `travel.start`, `travel.seats`, `travel.over` FROM travel INNER JOIN passenger ON travel.id=passenger.travel_id WHERE travel.driver=?",
					[this.token.mail]
				).then(http => {
					if (!http.body) {
						this.transaction.sendStatus(http.code, http.message);
					}
					else this.transaction.response.end(JSON.stringify(http.body));
				});
				break;
			case "passenger":
				this.database.get(
					"SELECT `driver`, `departure`, `arrival`, `registered`, `start`, `over`, `seats` FROM travel INNER JOIN passenger ON travel.id=passenger.travel_id WHERE passenger.mail=?",
					[this.token.mail]
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
	protected postExecution() {
		this.database.get(
			"SELECT id, driver, registered, start, seats FROM travel WHERE departure=? AND arrival=?",
			[this.posted.departure, this.posted.arrival]
		).then(http => {
			if (!http.body) {
				this.transaction.sendStatus(http.code, http.message);
			}
			else this.transaction.response.end(JSON.stringify(http.body));
		});
	}
	protected putExecution() {
		this.database.set(
			"INSERT INTO travel(driver, departure, arrival, seats) VALUES(?, ?, ?, ?)",
			[this.token.mail, this.posted.departure, this.posted.arrival, this.posted.seats]
		).then(http => {
			this.transaction.sendStatus(http.code, http.message);
		});
	}
	protected deleteExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]); //TODO: passager voyage terminé
	}
	protected patchExecution() {
		this.database.get(
			"SELECT COUNT(passenger.travelling), travel.seats FROM travel INNER JOIN passenger ON travel.id=passenger.travel_id WHERE travel.id=?",
			[this.posted.travel_id]
		).then(http => {
			if (http.body && (Number(http.body[0]["COUNT(passenger.travelling)"]) < Number(http.body[0].seats) || Number(http.body[0]["COUNT(passenger.travelling)"]) === 0)) {
				this.database.set(
					"UPDATE passenger SET travel_id=?, travelling=? WHERE mail=?",
					[this.posted.travel_id, true, this.token.mail]
				).then(http => {
					this.transaction.sendStatus(http.code, http.message);
				});
			}
			else this.transaction.sendStatus(httpCodes.Gone);
		});
	}
}