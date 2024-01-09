import { httpCodes } from "../../HttpTransaction.js";
import { PageEnforcedAuth } from "../PageEnforcedAuth.js";

export default class Travel extends PageEnforcedAuth {
	protected getExecution() {
		this.database.getProfile(this.token.mail).then(role => {
			switch (role) {
			case "driver":
				this.database.get(
					"SELECT driver, departure, arrival, start, over FROM cvp.travel INNER JOIN cvp.driver ON cvp.travel.driver = cvp.driver.mail WHERE cvp.driver.mail = ?",
					[this.token.mail]
				).then(http => {
					this.transaction.sendStatus(http.code, http.message);
				});
				break;
			case "passenger":
				this.database.get(
					"SELECT driver, departure, arrival, start, over FROM cvp.travel INNER JOIN cvp.passenger ON cvp.travel.travel_id = cvp.passenger.mail WHERE cvp.passenger.mail = ?",
					[this.token.mail]
				).then(http => {
					this.transaction.sendStatus(http.code, http.message);
				});
				break;
			}
		});
	}
	protected postExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	protected putExecution() {
		this.database.set(
			"UPDATE cvp.passenger SET travel_id=?, travelling=true WHERE mail=? AND (SELECT COUNT(cvp.driver.travelling) WHERE ) <= cvp.travel.places",
			[this.posted.travelId, this.token.mail, this.posted.places, this.posted.arrival]
		).then(http => {
			this.transaction.sendStatus(http.code, http.message);
		});
	}
	protected deleteExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	protected patchExecution() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
}