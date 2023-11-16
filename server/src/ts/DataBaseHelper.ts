import mariadb from "mariadb";
import { httpCodes } from "./httpCodes.mjs";

interface HttpResponseStatusCodes {
	code: httpCodes;
	message: string;
}

interface HttpResponseStatusCodesWithArrayBody extends HttpResponseStatusCodes {
	body?: {[key: string]: unknown}[]
}

export class DataBaseHelper {
	private host: string;
	private user: string;
	private password: string;
	#connection: mariadb.Connection|null = null;

	private get connection() {
		if (this.#connection) return this.#connection;
		else throw new Error("DataBaseHelper has not been started");
	}

	private set connection(connection) {
		this.#connection = connection;
	}

	constructor(host: string, user: string, password: string){
		this.host = host;
		this.user = user;
		this.password = password;
	}

	/**
	 * @throws {mariadb.SqlError} Check if the mariadb service is started or if the connection credentials are correct
	 */
	start(): Promise<string> {
		return mariadb.createConnection({
			host: this.host,
			user: this.user,
			password: this.password
		}).then(connection => {
			this.connection = connection;
			return connection.constructor.name;
		});
	}

	set(request: string, values: unknown[]): Promise<HttpResponseStatusCodes> {
		for (let i = 0; i < values.length; i++) {
			values[i] = values[i] ?? null;
		}
		return this.connection.query(request, values).then(result => {
			console.log(result);
			return {
				code: httpCodes.Created,
				message: "Created"
			};
		}).catch(error => {
			console.error(error.sqlMessage);
			switch (error.code) {
			case "ER_BAD_NULL_ERROR":
				return {
					code: httpCodes["Bad Request"],
					message: error.sqlMessage
				};

			case "ER_DUP_ENTRY":
				return {
					code: httpCodes.Conflict,
					message: error.sqlMessage
				};
				
			default:
				return {
					code: httpCodes["Not Acceptable"],
					message: error.sqlMessage
				};
			}
		});
	}

	get(request: string, values: unknown[]): Promise<HttpResponseStatusCodesWithArrayBody> {
		return this.connection.query(request, values).then(rows => {
			if (Array.isArray(rows)) {
				return {
					code: httpCodes.OK,
					message: "Success",
					body: rows
				};
			}
			else {
				return {
					code: httpCodes["Site Frozen"],
					message: "FIXME: Database mishap"
				};
			}
		}).catch(error => {
			console.error(error.sqlMessage);
			switch (error.code) {
			case "ER_BAD_NULL_ERROR":
				return {
					code: httpCodes["Bad Request"],
					message: error.sqlMessage
				};

			default:
				return {
					code: httpCodes["Not Acceptable"],
					message: error.sqlMessage
				};
			}
		});
	}
}