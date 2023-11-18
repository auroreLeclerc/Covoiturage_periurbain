import { Certificates } from "../../../main.js";
import { DataBaseHelper } from "../DataBaseHelper.js";
import { HttpTransaction } from "../HttpTransaction.js";

export abstract class Page {
	protected transaction: HttpTransaction;
	protected certificates: Certificates;
	protected database: DataBaseHelper;
	protected posted: {[key: string]: string};

	constructor(transaction: HttpTransaction, certificates: Certificates, database: DataBaseHelper, posted: {[key: string]: string}) {
		this.transaction = transaction;
		this.certificates = certificates;
		this.database = database;
		this.posted = posted;
	}

	public abstract get(): void;
    public abstract post(): void;
	public abstract put(): void;
	public abstract delete(): void;
	public abstract patch(): void;
}