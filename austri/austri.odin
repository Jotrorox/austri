//
// Austri - A lightweight HTTP server library for Odin
//
// License: BSD-2-Clause License
//
// Contributors:
// - Johannes (jotrorox) Müller <mail@jotrorox.com>
//

package austri

import fmt "core:fmt"
import log "core:log"
import net "core:net"
import strings "core:strings"
import thread "core:thread"

// Represents an incoming HTTP request.
//
// Fields:
// - conn: The underlying TCP socket connection for the client.
// - type: The HTTP method of the request (e.g., GET, POST).
// - path: The requested URI path.
// - params: Map of route parameters captured from templated routes,
//           e.g., for route "/user/:id" and path "/user/123", params["id"] = "123".
HTTP_Request_Handle :: struct {
	conn:    net.TCP_Socket,
	request: HTTP_Request,
}

HTTP_Request :: struct {
	type:    HTTP_Request_Type,
	path:    string,
	params:  map[string]string,
	version: string,
	headers: map[string]string,
}

// Defines a route for the HTTP server.
//
// Fields:
// - path: The route path, supporting templating with ":param_name" placeholders,
//         e.g., "/user/:id" captures the "id" segment into request.params.
// - handler: The procedure called to handle matching requests.
// - type: The HTTP method this route responds to (e.g., GET, POST).
HTTP_Route :: struct {
	path:    string,
	handler: proc(_: HTTP_Request_Handle),
	type:    HTTP_Request_Type,
}

// Configuration structure for the HTTP server.
//
// Fields:
// - routes: Slice of HTTP_Route entries defining the server's endpoints.
// - port: The TCP port to listen on.
// - address: The IP address to bind the server to.
// - multithread: If true, handle each client connection in a separate thread for concurrency.
// - maxRequestSize: Maximum bytes to read from incoming requests (default: 4096).
// - logger: The logger instance for server logs (info, warn, error).
HTTP_Server_Config :: struct {
	routes:         []HTTP_Route,
	port:           int,
	address:        net.Address,
	multithread:    bool,
	maxRequestSize: int,
	logger:         log.Logger,
}

// HTTP request methods as defined in the HTTP/1.1 specification.
HTTP_Request_Type :: enum {
	GET,
	POST,
	HEAD,
	PUT,
	DELETE,
	CONNECT,
	OPTIONS,
	TRACE,
	PATCH,
}

// Standard HTTP response status codes as defined in HTTP/1.1 and extensions.
HTTP_Response_Code :: enum {
	CONTINUE, // 100
	SWITCHING_PROTOCOLS, // 101
	PROCESSING, // 102
	EARLY_HINTS, // 103
	OK, // 200
	CREATED, // 201
	ACCEPTED, // 202
	NON_AUTHORITATIVE, // 203
	NO_CONTENT, // 204
	RESET_CONTENT, // 205
	PARTIAL_CONTENT, // 206
	MULTI_STATUS, // 207
	ALREADY_REPORTED, // 208
	IM_USED, // 226
	MULTIPLE_CHOICES, // 300
	MOVED_PERMANENTLY, // 301
	FOUND, // 302
	SEE_OTHER, // 303
	NOT_MODIFIED, // 304
	USE_PROXY, // 305
	TEMPORARY_REDIRECT, // 307
	PERMANENT_REDIRECT, // 308
	BAD_REQUEST, // 400
	UNAUTHORIZED, // 401
	PAYMENT_REQUIRED, // 402
	FORBIDDEN, // 403
	NOT_FOUND, // 404
	METHOD_NOT_ALLOWED, // 405
	NOT_ACCEPTABLE, // 406
	PROXY_AUTH_REQUIRED, // 407
	REQUEST_TIMEOUT, // 408
	CONFLICT, // 409
	GONE, // 410
	LENGTH_REQUIRED, // 411
	PRECONDITION_FAILED, // 412
	PAYLOAD_TOO_LARGE, // 413
	URI_TOO_LONG, // 414
	UNSUPPORTED_MEDIA, // 415
	RANGE_NOT_SATISFIED, // 416
	EXPECTATION_FAILED, // 417
	IM_A_TEAPOT, // 418
	MISDIRECTED, // 421
	UNPROCESSABLE, // 422
	LOCKED, // 423
	FAILED_DEPENDENCY, // 424
	TOO_EARLY, // 425
	UPGRADE_REQUIRED, // 426
	PRECONDITION_REQ, // 428
	TOO_MANY_REQUESTS, // 429
	REQ_HDR_TOO_LARGE, // 431
	LEGAL_UNAVAILABLE, // 451
	SERVER_ERROR, // 500
	NOT_IMPLEMENTED, // 501
	BAD_GATEWAY, // 502
	SERVICE_UNAVAIL, // 503
	GATEWAY_TIMEOUT, // 504
	HTTP_NOT_SUPPORTED, // 505
	VARIANT_NEGOT, // 506
	INSUFFICIENT_STORE, // 507
	LOOP_DETECTED, // 508
	NOT_EXTENDED, // 510
	NETWORK_AUTH_REQ, // 511
}

// Common MIME types for HTTP content negotiation and responses.
HTTP_Content_Type :: enum {
	TEXT_PLAIN,
	TEXT_HTML,
	TEXT_CSS,
	TEXT_JAVASCRIPT,
	TEXT_XML,
	TEXT_CSV,
	TEXT_MARKDOWN,
	APPLICATION_JSON,
	APPLICATION_XML,
	APPLICATION_PDF,
	APPLICATION_OCTET_STREAM,
	APPLICATION_ZIP,
	APPLICATION_GZIP,
	APPLICATION_JAVASCRIPT,
	APPLICATION_WWW_FORM_URLENCODED,
	IMAGE_JPEG,
	IMAGE_PNG,
	IMAGE_GIF,
	IMAGE_WEBP,
	IMAGE_SVG,
	IMAGE_ICON,
	AUDIO_MPEG,
	AUDIO_OGG,
	AUDIO_WAV,
	AUDIO_WEBM,
	VIDEO_MP4,
	VIDEO_OGG,
	VIDEO_WEBM,
	MULTIPART_FORM_DATA,
	FONT_WOFF,
	FONT_WOFF2,
	FONT_TTF,
	FONT_OTF,
}

// Matches a request path against a templated route pattern, populating the params map with captured values if matched.
//
// Parameters:
// - pattern: The route pattern with placeholders, e.g., "/user/:id".
// - path: The actual request path to match, e.g., "/user/123".
// - params: Pointer to a map where captured parameters will be stored, e.g., params["id"] = "123".
//
// Returns: true if the path matches the pattern exactly (including segment count), false otherwise.
//
// Notes: Supports only simple path segment parameters prefixed with ":". Does not handle query parameters or wildcards.
match_route :: proc(pattern: string, path: string, params: ^map[string]string) -> bool {
	pattern_segments := strings.split(pattern, "/")
	defer delete(pattern_segments)

	path_segments := strings.split(path, "/")
	defer delete(path_segments)

	if len(pattern_segments) != len(path_segments) {
		return false
	}

	for i in 0 ..< len(pattern_segments) {
		pattern_seg := pattern_segments[i]
		path_seg := path_segments[i]

		if strings.has_prefix(pattern_seg, ":") {
			param_name := pattern_seg[1:]
			params[param_name] = path_seg
		} else if pattern_seg != path_seg {
			return false
		}
	}

	return true
}

// Returns the standard string representation of an HTTP response status code (e.g., "200 OK").
//
// Parameters:
// - code: The HTTP_Response_Code enum value to convert.
//
// Returns: The status line string, or "500 Internal Server Error" for unrecognized codes.
get_response_code_string :: proc(code: HTTP_Response_Code) -> string {
	switch code {
	case .CONTINUE:
		return "100 Continue"
	case .SWITCHING_PROTOCOLS:
		return "101 Switching Protocols"
	case .PROCESSING:
		return "102 Processing"
	case .EARLY_HINTS:
		return "103 Early Hints"
	case .OK:
		return "200 OK"
	case .CREATED:
		return "201 Created"
	case .ACCEPTED:
		return "202 Accepted"
	case .NON_AUTHORITATIVE:
		return "203 Non-Authoritative Information"
	case .NO_CONTENT:
		return "204 No Content"
	case .RESET_CONTENT:
		return "205 Reset Content"
	case .PARTIAL_CONTENT:
		return "206 Partial Content"
	case .MULTI_STATUS:
		return "207 Multi-Status"
	case .ALREADY_REPORTED:
		return "208 Already Reported"
	case .IM_USED:
		return "226 IM Used"
	case .MULTIPLE_CHOICES:
		return "300 Multiple Choices"
	case .MOVED_PERMANENTLY:
		return "301 Moved Permanently"
	case .FOUND:
		return "302 Found"
	case .SEE_OTHER:
		return "303 See Other"
	case .NOT_MODIFIED:
		return "304 Not Modified"
	case .USE_PROXY:
		return "305 Use Proxy"
	case .TEMPORARY_REDIRECT:
		return "307 Temporary Redirect"
	case .PERMANENT_REDIRECT:
		return "308 Permanent Redirect"
	case .BAD_REQUEST:
		return "400 Bad Request"
	case .UNAUTHORIZED:
		return "401 Unauthorized"
	case .PAYMENT_REQUIRED:
		return "402 Payment Required"
	case .FORBIDDEN:
		return "403 Forbidden"
	case .NOT_FOUND:
		return "404 Not Found"
	case .METHOD_NOT_ALLOWED:
		return "405 Method Not Allowed"
	case .NOT_ACCEPTABLE:
		return "406 Not Acceptable"
	case .PROXY_AUTH_REQUIRED:
		return "407 Proxy Authentication Required"
	case .REQUEST_TIMEOUT:
		return "408 Request Timeout"
	case .CONFLICT:
		return "409 Conflict"
	case .GONE:
		return "410 Gone"
	case .LENGTH_REQUIRED:
		return "411 Length Required"
	case .PRECONDITION_FAILED:
		return "412 Precondition Failed"
	case .PAYLOAD_TOO_LARGE:
		return "413 Payload Too Large"
	case .URI_TOO_LONG:
		return "414 URI Too Long"
	case .UNSUPPORTED_MEDIA:
		return "415 Unsupported Media Type"
	case .RANGE_NOT_SATISFIED:
		return "416 Range Not Satisfiable"
	case .EXPECTATION_FAILED:
		return "417 Expectation Failed"
	case .IM_A_TEAPOT:
		return "418 I'm a teapot"
	case .MISDIRECTED:
		return "421 Misdirected Request"
	case .UNPROCESSABLE:
		return "422 Unprocessable Entity"
	case .LOCKED:
		return "423 Locked"
	case .FAILED_DEPENDENCY:
		return "424 Failed Dependency"
	case .TOO_EARLY:
		return "425 Too Early"
	case .UPGRADE_REQUIRED:
		return "426 Upgrade Required"
	case .PRECONDITION_REQ:
		return "428 Precondition Required"
	case .TOO_MANY_REQUESTS:
		return "429 Too Many Requests"
	case .REQ_HDR_TOO_LARGE:
		return "431 Request Header Fields Too Large"
	case .LEGAL_UNAVAILABLE:
		return "451 Unavailable For Legal Reasons"
	case .SERVER_ERROR:
		return "500 Internal Server Error"
	case .NOT_IMPLEMENTED:
		return "501 Not Implemented"
	case .BAD_GATEWAY:
		return "502 Bad Gateway"
	case .SERVICE_UNAVAIL:
		return "503 Service Unavailable"
	case .GATEWAY_TIMEOUT:
		return "504 Gateway Timeout"
	case .HTTP_NOT_SUPPORTED:
		return "505 HTTP Version Not Supported"
	case .VARIANT_NEGOT:
		return "506 Variant Also Negotiates"
	case .INSUFFICIENT_STORE:
		return "507 Insufficient Storage"
	case .LOOP_DETECTED:
		return "508 Loop Detected"
	case .NOT_EXTENDED:
		return "510 Not Extended"
	case .NETWORK_AUTH_REQ:
		return "511 Network Authentication Required"
	}
	return "500 Internal Server Error"
}

// Returns the MIME type string for a given HTTP_Content_Type enum value.
//
// Parameters:
// - code: The HTTP_Content_Type enum value.
//
// Returns: The corresponding MIME type string, or "text/plain" for unrecognized types.
get_content_type_string :: proc(code: HTTP_Content_Type) -> string {
	switch code {
	case .TEXT_PLAIN:
		return "text/plain"
	case .TEXT_HTML:
		return "text/html"
	case .TEXT_CSS:
		return "text/css"
	case .TEXT_JAVASCRIPT:
		return "text/javascript"
	case .TEXT_XML:
		return "text/xml"
	case .TEXT_CSV:
		return "text/csv"
	case .TEXT_MARKDOWN:
		return "text/markdown"
	case .APPLICATION_JSON:
		return "application/json"
	case .APPLICATION_XML:
		return "application/xml"
	case .APPLICATION_PDF:
		return "application/pdf"
	case .APPLICATION_OCTET_STREAM:
		return "application/octet-stream"
	case .APPLICATION_ZIP:
		return "application/zip"
	case .APPLICATION_GZIP:
		return "application/gzip"
	case .APPLICATION_JAVASCRIPT:
		return "application/javascript"
	case .APPLICATION_WWW_FORM_URLENCODED:
		return "application/x-www-form-urlencoded"
	case .IMAGE_JPEG:
		return "image/jpeg"
	case .IMAGE_PNG:
		return "image/png"
	case .IMAGE_GIF:
		return "image/gif"
	case .IMAGE_WEBP:
		return "image/webp"
	case .IMAGE_SVG:
		return "image/svg+xml"
	case .IMAGE_ICON:
		return "image/x-icon"
	case .AUDIO_MPEG:
		return "audio/mpeg"
	case .AUDIO_OGG:
		return "audio/ogg"
	case .AUDIO_WAV:
		return "audio/wav"
	case .AUDIO_WEBM:
		return "audio/webm"
	case .VIDEO_MP4:
		return "video/mp4"
	case .VIDEO_OGG:
		return "video/ogg"
	case .VIDEO_WEBM:
		return "video/webm"
	case .MULTIPART_FORM_DATA:
		return "multipart/form-data"
	case .FONT_WOFF:
		return "font/woff"
	case .FONT_WOFF2:
		return "font/woff2"
	case .FONT_TTF:
		return "font/ttf"
	case .FONT_OTF:
		return "font/otf"
	}
	return "text/plain"
}

// Sends a basic HTTP/1.1 response to the client socket.
//
// Parameters:
// - client: The TCP socket connected to the client.
// - status_code: The response status code (default: .OK / 200).
// - body: The content to send in the response body.
// - content_type: The MIME type of the body (default: .TEXT_PLAIN).
//
// Notes: Includes Content-Type and Content-Length headers. No additional headers like Server or Date.
send_response :: proc(
	client: net.TCP_Socket,
	status_code: HTTP_Response_Code = HTTP_Response_Code.OK,
	body: string,
	content_type: HTTP_Content_Type = HTTP_Content_Type.TEXT_PLAIN,
) {
	content_length := len(body)

	response := strings.concatenate(
		[]string {
			"HTTP/1.1 ",
			get_response_code_string(status_code),
			"\r\n",
			"Content-Type: ",
			get_content_type_string(content_type),
			"\r\n",
			"Content-Length: ",
			fmt.tprint(content_length),
			"\r\n",
			"\r\n",
			body,
		},
	)

	net.send(client, transmute([]u8)response)
}

// Processes an incoming client request: parses headers, matches routes, and invokes the handler or sends error response.
//
// Parameters:
// - client: The accepted TCP socket from the client.
// - server_config: Pointer to the server's configuration (routes, logger, etc.).
//
// Notes: Reads up to maxRequestSize bytes. Supports GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, TRACE, CONNECT.
//        Matches static routes first, then templated ones. Logs request and errors. Closes client socket on exit.
handle_client :: proc(client: net.TCP_Socket, server_config: ^HTTP_Server_Config) {
	context.logger = (server_config^).logger
	defer net.close(client)

	buffer := make([]byte, (server_config^).maxRequestSize)
	defer delete(buffer)
	bytes_read, read_err := net.recv(client, buffer[:])
	if read_err != nil {
		log.warn("Error reading from client: ", read_err)
		send_response(
			client,
			HTTP_Response_Code.BAD_REQUEST,
			"There was an error reading from the client.",
			HTTP_Content_Type.TEXT_PLAIN,
		)
		return
	}

	raw_request := string(buffer[:bytes_read])
	req_split, req_split_err := strings.split(raw_request, "\n")
	if req_split_err != nil {
		log.warn("Error splitting the request by lines: ", req_split_err)
		send_response(
			client,
			HTTP_Response_Code.BAD_REQUEST,
			"Invalid request format",
			HTTP_Content_Type.TEXT_PLAIN,
		)
		return
	}
	log.info("Recieved request: ", req_split[0])

	req_header_split, req_header_split_err := strings.split(req_split[0], " ")
	if req_header_split_err != nil || len(req_header_split) < 2 {
		log.warn("Error splitting the request Header: ", req_header_split_err)
		send_response(
			client,
			HTTP_Response_Code.BAD_REQUEST,
			"Invalid request header",
			HTTP_Content_Type.TEXT_PLAIN,
		)
		return
	}

	req_type: HTTP_Request_Type
	switch req_header_split[0] {
	case "GET":
		req_type = HTTP_Request_Type.GET
	case "POST":
		req_type = HTTP_Request_Type.POST
	case "PUT":
		req_type = HTTP_Request_Type.PUT
	case "PATCH":
		req_type = HTTP_Request_Type.PATCH
	case "CONNECT":
		req_type = HTTP_Request_Type.CONNECT
	case "DELETE":
		req_type = HTTP_Request_Type.DELETE
	case "HEAD":
		req_type = HTTP_Request_Type.HEAD
	case "OPTIONS":
		req_type = HTTP_Request_Type.OPTIONS
	case "TRACE":
		req_type = HTTP_Request_Type.TRACE
	}

	request := HTTP_Request_Handle {
		client,
		HTTP_Request {
			req_type,
			req_header_split[1],
			make(map[string]string),
			req_header_split[0],
			make(map[string]string),
		},
	}

	for route in (server_config^).routes {
		if !strings.contains(route.path, ":") &&
		   route.path == request.request.path &&
		   route.type == request.request.type {
			route.handler(request)
			return
		}
	}

	for route in (server_config^).routes {
		if strings.contains(route.path, ":") && route.type == request.request.type {
			if match_route(route.path, request.request.path, &request.request.params) {
				route.handler(request)
				return
			}
		}
	}

	delete(request.request.params)
	send_response(
		request.conn,
		HTTP_Response_Code.NOT_FOUND,
		strings.concatenate(
			[]string{"You are requesting: ", request.request.path, " which doesn't exist :("},
		),
		HTTP_Content_Type.TEXT_PLAIN,
	)
}

listen :: proc {
	listen_config,
	listen_values,
}

// Listens for incoming TCP connections and dispatches them to handlers in a loop.
//
// Parameters:
// - server_config: Pointer to the HTTP_Server_Config with routes, port, etc.
//
// Notes: Binds to the specified address and port. Accepts connections indefinitely.
//        If multithread is true, spawns a thread per client using thread.run_with_poly_data2.
//        Logs server start, connections, and errors. Graceful shutdown logs on exit.
listen_config :: proc(server_config: ^HTTP_Server_Config) {
	sock, listen_err := net.listen_tcp(
		net.Endpoint{port = server_config.port, address = server_config.address},
	)
	defer net.close(sock)

	if listen_err != nil {
		log.fatal("Couldn't create TCP Socket: ", listen_err)
		return
	}

	log.info("Server started on port ", server_config.port)

	for {
		client, src, accept_err := net.accept_tcp(sock)
		if accept_err != nil {
			log.warn("Error accepting connection from: ", src, " Error: ", accept_err)
			continue
		}

		log.info("Got new connection from: ", src)

		if server_config.multithread {
			thread.run_with_poly_data2(client, server_config, handle_client)
		} else {
			handle_client(client, server_config)
		}
	}

	log.info("Server shutting down gracefully")
}

// Convenience procedure to start the server with explicit values, constructing config internally.
//
// Parameters:
// - routes: Slice of HTTP_Route to handle requests.
// - port: The port number to bind to.
// - address: The IP address (default: net.IP4_Loopback / 127.0.0.1).
// - multithread: Enable threaded client handling (default: true).
// - logger: The log.Logger for server output.
//
// Notes: Sets maxRequestSize to 4096 bytes. Calls listen_config with the built config.
//        Use this for quick server setup without manually creating HTTP_Server_Config.
listen_values :: proc(
	routes: []HTTP_Route,
	port: int,
	address: net.Address = net.IP4_Loopback,
	multithread: bool = true,
	logger: log.Logger,
) {
	config := HTTP_Server_Config {
		routes         = routes,
		port           = port,
		address        = address,
		multithread    = multithread,
		maxRequestSize = 4096,
		logger         = logger,
	}
	listen_config(&config)
}
