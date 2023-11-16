import http from "node:http";
import { Certificates } from "../../../main.js";
import { DataBaseHelper } from "../DataBaseHelper.js";

export abstract class Page {
	protected request: http.IncomingMessage;
	protected response: http.ServerResponse;
	protected certificates: Certificates;
	protected database: DataBaseHelper;
	protected posted: {[key: string]: string};

	constructor(request: http.IncomingMessage, response: http.ServerResponse, certificates: Certificates, database: DataBaseHelper, posted: {[key: string]: string}) {
		this.request = request;
		this.response = response;
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