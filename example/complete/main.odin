package main

import austri "../../austri"
import fmt "core:fmt"
import "core:log"

// Handler for serving a simple CSS file at /simple-css
handle_simple_css :: proc(request: austri.HTTP_Request_Handle) {
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		"body {color: green;}",
		austri.HTTP_Content_Type.TEXT_CSS,
	)
}

// Handler for serving the main HTML page at /, which links to the CSS
handle_html :: proc(request: austri.HTTP_Request_Handle) {
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		"<header><link rel=\"stylesheet\" href=\"/simple-css\"></header><body><h1>Hello, World</h1></body>",
		austri.HTTP_Content_Type.TEXT_HTML,
	)
}

// Handler for serving a plain text response at /index
handle_index :: proc(request: austri.HTTP_Request_Handle) {
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		"Hello, World!",
		austri.HTTP_Content_Type.TEXT_PLAIN,
	)
}

// Handler for templated route /user/:id
// Demonstrates path templating: captures the 'id' segment into request.params["id"]
// and responds with a personalized message.
handle_user_id :: proc(request: austri.HTTP_Request_Handle) {
	id, ok := request.request.params["id"]
	if !ok {
		austri.send_response(
			request.conn,
			austri.HTTP_Response_Code.BAD_REQUEST,
			"Missing id parameter",
			austri.HTTP_Content_Type.TEXT_PLAIN,
		)
		return
	}
	message := fmt.tprintf("Hello, user with ID: %s!", id)
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		message,
		austri.HTTP_Content_Type.TEXT_PLAIN,
	)
}

// Handler for POST /api/echo
// Demonstrates header parsing and body handling.
// Echoes back the received body along with some header information.
handle_echo :: proc(request: austri.HTTP_Request_Handle) {
	// Get Content-Type header
	content_type, has_content_type := request.request.headers["content-type"]
	content_type_str := content_type if has_content_type else "not specified"
	
	// Get Content-Length header
	content_length, has_content_length := request.request.headers["content-length"]
	content_length_str := content_length if has_content_length else "not specified"
	
	// Build response
	response := fmt.tprintf(
		"Received POST request\n" +
		"Content-Type: %s\n" +
		"Content-Length: %s\n" +
		"Body: %s",
		content_type_str,
		content_length_str,
		request.request.body,
	)
	
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		response,
		austri.HTTP_Content_Type.TEXT_PLAIN,
	)
}

main :: proc() {
	routes := []austri.HTTP_Route {
		{path = "/", handler = handle_html, type = .GET},
		{path = "/simple-css", handler = handle_simple_css, type = .GET},
		{path = "/index", handler = handle_index, type = .GET},
		{path = "/user/:id", handler = handle_user_id, type = .GET},
		{path = "/api/echo", handler = handle_echo, type = .POST},
	}

	austri.listen(routes, 8080, logger = log.create_console_logger(.Info))
}
