import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class Match extends PageEnforcedAuth {
	protected getExecution() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
	protected postExecution() {
		this.database.get(
			"SELECT travel.driver, travel.id, travel.seats, driver.mac, driver.numberplate, profile.name FROM travel INNER JOIN driver ON travel.driver=driver.mail INNER JOIN profile ON driver.mail=profile.mail WHERE travel.departure=? AND travel.arrival=?",
			[this.posted.departure, this.posted.arrival]
		).then(http => {
			if (http.body?.length) {
				this.database.get(
					"SELECT COUNT(passenger.travelling), travel.seats FROM travel INNER JOIN passenger ON travel.id=passenger.travel_id WHERE travel.id=?",
					[http.body[0].id]
				).then(http2 => {
					if (http2.body && (Number(http2.body[0]["COUNT(passenger.travelling)"]) < Number(http2.body[0].seats) || Number(http2.body[0]["COUNT(passenger.travelling)"]) === 0)) {
						this.database.set(
							"UPDATE passenger SET travel_id=?, travelling=? WHERE mail=?",
							[this.posted.travel_id, true, this.token.mail]
						).then(http3 => {
							this.transaction.sendStatus(http3.code, JSON.stringify(http));
						});
					}
					else this.transaction.sendStatus(httpCodes.Gone);
				});
			}
			else this.transaction.sendStatus(httpCodes["No Content"]);
		});
	}
	protected putExecution() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
	protected deleteExecution() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
	protected patchExecution() {
		this.transaction.sendStatus(httpCodes["Method Not Allowed"]);
	}
}