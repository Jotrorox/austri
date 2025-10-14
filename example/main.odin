package main

import austri "../"

handle_html :: proc(request: austri.HTTP_Request) {
    austri.send_response(request.conn, austri.HTTP_Response_Code.OK, "<h1>Hello, World</h1>", austri.HTTP_Content_Type.TEXT_HTML)
}

handle_index :: proc(request: austri.HTTP_Request) {
    austri.send_response(client = request.conn, body = "Hello, World!")
}

main :: proc() {
    routes: map[string]proc(austri.HTTP_Request)
    defer delete(routes)

    routes["/html"] = handle_html
    routes["/"] = handle_index

    austri.listen(routes, 8080)
}

