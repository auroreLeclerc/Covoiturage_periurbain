import express from "express";
import { Certificates } from "../../../main.js";

export abstract class Page {
	protected request: express.Request;
	protected response: express.Response;
	protected certificates: Certificates;

	constructor(request: express.Request, response: express.Response, certificates: Certificates) {
		this.request = request;
		this.response = response;
		this.certificates = certificates;
	}

	public abstract get(): void;
    public abstract post(): void;
	public abstract put(): void;
	public abstract delete(): void;
	public abstract patch(): void;
}