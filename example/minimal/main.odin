package main

import austri "../../austri"
import "core:log"

handle_index :: proc(request: austri.HTTP_Request_Handle) {
	austri.send_response(
		request.conn,
		austri.HTTP_Response_Code.OK,
		"Hello, World!",
		austri.HTTP_Content_Type.TEXT_PLAIN,
	)
}

main :: proc() {
	routes := []austri.HTTP_Route{{path = "/", handler = handle_index, type = .GET}}

	austri.listen(routes, 8080, logger = log.create_console_logger(.Info))
}
