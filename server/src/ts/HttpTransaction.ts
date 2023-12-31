import http from "node:http";

export class HttpTransaction {
	public request: http.IncomingMessage;
	public response: http.ServerResponse;

	constructor(request: http.IncomingMessage, response: http.ServerResponse) {
		this.request = request;
		this.response = response;
	}

	public sendStatus(statusMessage: httpCodes, additionalMessage?: string) {
		this.response.writeHead(statusMessage, { "Content-Type": "text/plain" });
		this.response.end(`${httpCodes[statusMessage]}${additionalMessage ? ` ; ${additionalMessage}` : ""}`);
	}
}

export enum httpCodes {
	"Continue" = 100,
	"Switching Protocols" = 101,
	"Processing (WebDAV)" = 102,
	"Early Hints" = 103,
	"OK" = 200,
	"Created" = 201,
	"Accepted" = 202,
	"Non-Authoritative Information" = 203,
	"No Content" = 204,
	"Reset Content" = 205,
	"Partial Content" = 206,
	"Multi-Status (WebDAV)" = 207,
	"Already Reported (WebDAV)" = 208,
	"IM Used (HTTP Delta encoding)" = 226,
	"Multiple Choices" = 300,
	"Moved Permanently" = 301,
	"Found" = 302,
	"See Other" = 303,
	"Not Modified" = 304,
	"Use Proxy Deprecated" = 305,
	"Unused" = 306,
	"Temporary Redirect" = 307,
	"Permanent Redirect" = 308,
	"Bad Request" = 400,
	"Unauthorized" = 401,
	"Payment Required Experimental" = 402,
	"Forbidden" = 403,
	"Not Found" = 404,
	"Method Not Allowed" = 405,
	"Not Acceptable" = 406,
	"Proxy Authentication Required" = 407,
	"Request Timeout" = 408,
	"Conflict" = 409,
	"Gone" = 410,
	"Length Required" = 411,
	"Precondition Failed" = 412,
	"Payload Too Large" = 413,
	"URI Too Long" = 414,
	"Unsupported Media Type" = 415,
	"Range Not Satisfiable" = 416,
	"Expectation Failed" = 417,
	"I'm a teapot" = 418,
	"Misdirected Request" = 421,
	"Unprocessable Content (WebDAV)" = 422,
	"Locked (WebDAV)" = 423,
	"Failed Dependency (WebDAV)" = 424,
	"Too Early Experimental" = 425,
	"Upgrade Required" = 426,
	"Precondition Required" = 428,
	"Too Many Requests" = 429,
	"Request Header Fields Too Large" = 431,
	"Unavailable For Legal Reasons" = 451,
	"Internal Server Error" = 500,
	"Not Implemented" = 501,
	"Bad Gateway" = 502,
	"Service Unavailable" = 503,
	"Gateway Timeout" = 504,
	"HTTP Version Not Supported" = 505,
	"Variant Also Negotiates" = 506,
	"Insufficient Storage (WebDAV)" = 507,
	"Loop Detected (WebDAV)" = 508,
	"Not Extended" = 510,
	"Network Authentication Required" = 511,
	"Web Server Is Down" = 521,
	"Connection Timed Out" = 522,
	"Origin Is Unreachable" = 523,
	"SSL Handshake Failed" = 525,
	"Site Frozen" = 530,
	"Network Connect Timeout Error" = 599,
}