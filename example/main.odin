package main

import austri "../"

handle_simple_css :: proc(request: austri.HTTP_Request) {
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		"body {color: green;}",
		austri.HTTP_Content_Type.TEXT_CSS,
	)
}

handle_html :: proc(request: austri.HTTP_Request) {
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		"<header><link rel=\"stylesheet\" href=\"/simple-css\"></header><body><h1>Hello, World</h1></body>",
		austri.HTTP_Content_Type.TEXT_HTML,
	)
}

handle_index :: proc(request: austri.HTTP_Request) {
	austri.send_response(client = request.conn, body = "Hello, World!")
}

main :: proc() {
	routes: map[string]proc(_: austri.HTTP_Request)
	defer delete(routes)

	routes["/html"] = handle_html
	routes["/simple-css"] = handle_simple_css
	routes["/"] = handle_index

	austri.listen(routes, 8080)
}
