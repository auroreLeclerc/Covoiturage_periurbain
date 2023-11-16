import { PageAuth } from "./PageAuth.js";

export abstract class PageEnforcedAuth extends PageAuth {
	public get() {
		if (this.authenticate()) this.getExecution();
	}
	public post() {
		if (this.authenticate()) this.postExecution();
	}
	public put() {
		if (this.authenticate()) this.putExecution();
	}
	public delete() {
		if (this.authenticate()) this.deleteExecution();
	}
	public patch() {
		if (this.authenticate()) this.patchExecution();
	}

	protected abstract getExecution(): void;
    protected abstract postExecution(): void;
	protected abstract putExecution(): void;
	protected abstract deleteExecution(): void;
	protected abstract patchExecution(): void;
}