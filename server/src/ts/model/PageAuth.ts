import jwt from "jsonwebtoken";
import { Page } from "./Page.js";
import { Token } from "../../../main.js";
import { httpCodes } from "../HttpTransaction.js";

export abstract class PageAuth extends Page {
	protected token: Token | Record<string, never> = {};

	protected authenticate() {
		let authenticated = false;
		const token = this.transaction.request.headers.authorization?.split(" ")[1];
		if (token) {
			jwt.verify(token, this.certificates.key, (err, decoded) => {
				if (err || !decoded || typeof decoded === "string") {
					this.transaction.sendStatus(httpCodes["Not Acceptable"], "Authorization Header is mush mush");
				}
				else {
					this.token = decoded as Token;
					if (new Date(this.token.creation).getFullYear() - new Date().getFullYear() != 0) {
						this.token = {};
						this.transaction.sendStatus(httpCodes["Not Acceptable"], "Authorization Header Expired");
					}
					else {
						authenticated = true;
					}
				}
			});
		}
		else if (this.transaction.request.headers.authorization) this.transaction.sendStatus(httpCodes["Precondition Failed"], "Bearer Corrupted");
		else this.transaction.sendStatus(httpCodes["Precondition Failed"], "Authorization Header Missing");
		return authenticated;
	}
}