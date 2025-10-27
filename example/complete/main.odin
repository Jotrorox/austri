package main

import austri "../../"
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

main :: proc() {
	routes := []austri.HTTP_Route {
		{path = "/", handler = handle_html, type = .GET},
		{path = "/simple-css", handler = handle_simple_css, type = .GET},
		{path = "/index", handler = handle_index, type = .GET},
		{path = "/user/:id", handler = handle_user_id, type = .GET},
	}

	austri.listen(routes, 8080, logger = log.create_console_logger(.Info))
}
