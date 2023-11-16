import jwt from "jsonwebtoken";
import { Page } from "./Page.js";
import { Token } from "../../../main.js";
import { httpCodes, sendStatus } from "../httpCodes.mjs";

export abstract class PageAuth extends Page {
	protected token: Token | Record<string, never> = {};

	protected authenticate() {
		let authenticated = false;
		const token = this.request.headers.authorization?.split(" ")[1];
		if (token) {
			jwt.verify(token, this.certificates.key, (err, decoded) => {
				if (err || !decoded || typeof decoded === "string") {
					sendStatus(this.response, httpCodes["Not Acceptable"], "Authorization Header is mush mush");
				}
				else {
					this.token = decoded as Token;
					if (new Date(this.token.creation).getFullYear() - new Date().getFullYear() != 0) {
						this.token = {};
						sendStatus(this.response, httpCodes["Not Acceptable"], "Authorization Header Expired");
					}
					else {
						authenticated = true;
					}
				}
			});
		}
		else if (this.request.headers.authorization) sendStatus(this.response, httpCodes["Precondition Failed"], "Bearer Corrupted");
		else sendStatus(this.response, httpCodes["Precondition Failed"], "Authorization Header Missing");
		return authenticated;
	}
}