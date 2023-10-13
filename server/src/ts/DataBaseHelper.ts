import mariadb, { SqlError } from "mariadb";

interface HttpResponseStatusCodes {
	code: number;
	message: string;
}

interface HttpResponseStatusCodesWithArrayBody extends HttpResponseStatusCodes {
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	body?: any[]
}

export class DataBaseHelper {
	private pool: mariadb.Pool;
	#connection: mariadb.PoolConnection|null = null;

	private get connection() {
		if (this.#connection) return this.#connection;
		else throw new SqlError;
	}

	private set connection(value: mariadb.PoolConnection) {
		this.#connection = value;
	}

	constructor(host: string, user: string, password: string){
		this.pool = mariadb.createPool({
			host: host, 
			user: user, 
			password: password,
		});
	}

	/**
	 * @throws {mariadb.SqlError} Check if the mariadb service is started or if the connection credentials are correct
	 */
	start(): Promise<string> {
		return this.pool.getConnection().then(connection => {
			this.connection = connection;
			return connection.constructor.name;
		});
	}

	/**
	 * @example insert("INSERT INTO dataBase.table(value1, value2, value3, value4) VALUES(?, ?, ?, ?)", [true, "value", 123, false])
	 */
	insert(request: string, values: unknown[]): Promise<HttpResponseStatusCodes> {
		for (let i = 0; i < values.length; i++) {
			if (!values[i]) {
				values[i] = null;
			}
		}
		return this.pool.batch(request, values).then(result => {
			console.log(result);
			return {
				code: 201,
				message: "Created"
			};
		}).catch(error => {
			console.error(error);
			switch (error.code) {
			case "ER_BAD_NULL_ERROR":
				return {
					code: 400,
					message: error.sqlMessage
				};

			case "ER_DUP_ENTRY":
				return {
					code: 409,
					message: error.sqlMessage
				};
				
			default:
				return {
					code: 406,
					message: error.sqlMessage
				};
			}
		});
	}

	select(request: string, values: unknown[]): Promise<HttpResponseStatusCodesWithArrayBody> {
		return this.connection.query(request, values).then(rows => {
			if (Array.isArray(rows)) {
				return {
					code: 200,
					message: "Success",
					body: rows
				};
			}
			else {
				return {
					code: 530,
					message: "FIXME: Database mishap"
				};
			}
		}).catch(error => {
			console.error(error);
			switch (error.code) {
			case "ER_BAD_NULL_ERROR":
				return {
					code: 400,
					message: error.sqlMessage
				};

			default:
				return {
					code: 406,
					message: error.sqlMessage
				};
			}
		});
	}
}