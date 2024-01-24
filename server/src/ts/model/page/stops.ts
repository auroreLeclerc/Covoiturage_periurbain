import { httpCodes } from "../../HttpTransaction.js";
import { Page } from "../Page.js";

export default class Account extends Page {
	public get() {
		this.database.get(
			"SELECT * FROM stops",
			[]
		).then(http => {
			if (!http.body) {
				this.transaction.sendStatus(http.code, http.message);
			}
			else this.transaction.response.end(JSON.stringify(http.body));
		});
	}
	public post() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	public put() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	public delete() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}
	public patch() {
		this.transaction.sendStatus(httpCodes["Not Implemented"]);
	}

}