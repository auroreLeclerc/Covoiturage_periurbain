import jwt from "jsonwebtoken";
import { Page } from "./Page.js";

export abstract class PageAuth extends Page {
	public get(): void {
		const token = this.request.get("Authorization")?.split(" ")[1];
		if (token) {
			jwt.verify(token, this.certificates.key, (err, decoded) => {
				if (err || !decoded || typeof decoded === "string") this.response.status(406).send("Authorization Header Corrupted");
				else if (new Date(decoded.expiration).getFullYear() - new Date().getFullYear() != 0) this.response.status(406).send("Authorization Header Expired");
				else {
					this.getExecution();
				}
			});
		}
		else if (this.request.get("Authorization")) this.response.status(412).send("Bearer Syntax Error");
		else this.response.status(412).send("Authorization Header Missing");
	}

	protected abstract getExecution(): void;
}