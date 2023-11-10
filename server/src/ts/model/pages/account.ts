import { PageAuth } from "../PageAuth.js";

export class Account extends PageAuth {
	protected getExecution(): void {
		this.response.sendStatus(501);
	}
	public put(): void {
		this.response.sendStatus(501);
	}
	public delete(): void {
		this.response.sendStatus(501);
	}
	public patch(): void {
		this.response.sendStatus(501);
	}
	public post(): void {
		this.response.sendStatus(501);
	}
    
}