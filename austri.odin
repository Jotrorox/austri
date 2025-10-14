package austri

import net "core:net"
import strings "core:strings"
import log "core:log"
import thread "core:thread"
import fmt "core:fmt"

HTTP_Requst_Type :: enum {
    GET,
    POST,
    HEAD,
    PUT,
    DELETE,
    CONNECT,
    OPTIONS,
    TRACE,
    PATCH
}

HTTP_Request :: struct {
    conn: net.TCP_Socket,
    type: HTTP_Requst_Type,
    path: string,
}

HTTP_Server_Config :: struct {
    routes: map[string]proc(HTTP_Request),
    port: int,
    address: net.Address,
    multithread: bool,
}

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
    NETWORK_AUTH_REQ,   // 511
}

get_response_code_string :: proc(code: HTTP_Response_Code) -> string {
    switch code {
    case .CONTINUE: return "100 Continue"
    case .SWITCHING_PROTOCOLS: return "101 Switching Protocols"
    case .PROCESSING: return "102 Processing"
    case .EARLY_HINTS: return "103 Early Hints"
    case .OK: return "200 OK"
    case .CREATED: return "201 Created"
    case .ACCEPTED: return "202 Accepted"
    case .NON_AUTHORITATIVE: return "203 Non-Authoritative Information"
    case .NO_CONTENT: return "204 No Content"
    case .RESET_CONTENT: return "205 Reset Content"
    case .PARTIAL_CONTENT: return "206 Partial Content"
    case .MULTI_STATUS: return "207 Multi-Status"
    case .ALREADY_REPORTED: return "208 Already Reported"
    case .IM_USED: return "226 IM Used"
    case .MULTIPLE_CHOICES: return "300 Multiple Choices"
    case .MOVED_PERMANENTLY: return "301 Moved Permanently"
    case .FOUND: return "302 Found"
    case .SEE_OTHER: return "303 See Other"
    case .NOT_MODIFIED: return "304 Not Modified"
    case .USE_PROXY: return "305 Use Proxy"
    case .TEMPORARY_REDIRECT: return "307 Temporary Redirect"
    case .PERMANENT_REDIRECT: return "308 Permanent Redirect"
    case .BAD_REQUEST: return "400 Bad Request"
    case .UNAUTHORIZED: return "401 Unauthorized"
    case .PAYMENT_REQUIRED: return "402 Payment Required"
    case .FORBIDDEN: return "403 Forbidden"
    case .NOT_FOUND: return "404 Not Found"
    case .METHOD_NOT_ALLOWED: return "405 Method Not Allowed"
    case .NOT_ACCEPTABLE: return "406 Not Acceptable"
    case .PROXY_AUTH_REQUIRED: return "407 Proxy Authentication Required"
    case .REQUEST_TIMEOUT: return "408 Request Timeout"
    case .CONFLICT: return "409 Conflict"
    case .GONE: return "410 Gone"
    case .LENGTH_REQUIRED: return "411 Length Required"
    case .PRECONDITION_FAILED: return "412 Precondition Failed"
    case .PAYLOAD_TOO_LARGE: return "413 Payload Too Large"
    case .URI_TOO_LONG: return "414 URI Too Long"
    case .UNSUPPORTED_MEDIA: return "415 Unsupported Media Type"
    case .RANGE_NOT_SATISFIED: return "416 Range Not Satisfiable"
    case .EXPECTATION_FAILED: return "417 Expectation Failed"
    case .IM_A_TEAPOT: return "418 I'm a teapot"
    case .MISDIRECTED: return "421 Misdirected Request"
    case .UNPROCESSABLE: return "422 Unprocessable Entity"
    case .LOCKED: return "423 Locked"
    case .FAILED_DEPENDENCY: return "424 Failed Dependency"
    case .TOO_EARLY: return "425 Too Early"
    case .UPGRADE_REQUIRED: return "426 Upgrade Required"
    case .PRECONDITION_REQ: return "428 Precondition Required"
    case .TOO_MANY_REQUESTS: return "429 Too Many Requests"
    case .REQ_HDR_TOO_LARGE: return "431 Request Header Fields Too Large"
    case .LEGAL_UNAVAILABLE: return "451 Unavailable For Legal Reasons"
    case .SERVER_ERROR: return "500 Internal Server Error"
    case .NOT_IMPLEMENTED: return "501 Not Implemented"
    case .BAD_GATEWAY: return "502 Bad Gateway"
    case .SERVICE_UNAVAIL: return "503 Service Unavailable"
    case .GATEWAY_TIMEOUT: return "504 Gateway Timeout"
    case .HTTP_NOT_SUPPORTED: return "505 HTTP Version Not Supported"
    case .VARIANT_NEGOT: return "506 Variant Also Negotiates"
    case .INSUFFICIENT_STORE: return "507 Insufficient Storage"
    case .LOOP_DETECTED: return "508 Loop Detected"
    case .NOT_EXTENDED: return "510 Not Extended"
    case .NETWORK_AUTH_REQ: return "511 Network Authentication Required"
    }
    return "500 Internal Server Error"
}

HTTP_Content_Type :: enum {
    TEXT_PLAIN,
    TEXT_HTML,
    APPLICATION_JSON,
}

get_content_type_string :: proc(code: HTTP_Content_Type) -> string {
    switch code {
    case .TEXT_PLAIN: return "text/plain"
    case .TEXT_HTML: return "text/html"
    case .APPLICATION_JSON: return "application/json"
    }
    return "text/plain"
}

send_response :: proc(
    client: net.TCP_Socket,
    status_code: HTTP_Response_Code = HTTP_Response_Code.OK,
    body: string,
    content_type: HTTP_Content_Type = HTTP_Content_Type.TEXT_PLAIN
    ) {
    content_length := len(body)

    response := strings.concatenate([]string{
        "HTTP/1.1 ", get_response_code_string(status_code), "\r\n",
        "Content-Type: ", get_content_type_string(content_type), "\r\n",
        "Content-Length: ", fmt.tprint(content_length), "\r\n",
        "\r\n",
        body })

    net.send(client, transmute([]u8)response)
}

handle_client :: proc(client: net.TCP_Socket, routes: map[string]proc(HTTP_Request)) {
    context.logger = log.create_console_logger(.Debug) // TODO: Make customizsable in the future
    defer net.close(client)

    buffer: [4096]u8
    bytes_read, read_err := net.recv(client, buffer[:])
    if read_err != nil {
        log.warn("Error reading from client: ", read_err)
        send_response(client, HTTP_Response_Code.BAD_REQUEST, "There was an error reading from the client.", HTTP_Content_Type.TEXT_PLAIN)
        return
    }

    raw_request := string(buffer[:bytes_read])
    req_split, req_split_err := strings.split(raw_request, "\n")
    if req_split_err != nil {
        log.warn("Error splitting the request by lines: ", req_split_err)
        send_response(client, HTTP_Response_Code.BAD_REQUEST, "Invalid request format", HTTP_Content_Type.TEXT_PLAIN)
        return
    }
    log.info("Recieved request: ", req_split[0])

    req_header_split, req_header_split_err := strings.split(req_split[0], " ")
    if req_header_split_err != nil {
        log.warn("Error splitting the request Header: ", req_header_split_err)
        send_response(client, HTTP_Response_Code.BAD_REQUEST, "Invalid request header", HTTP_Content_Type.TEXT_PLAIN)
        return
    }

    req_type: HTTP_Requst_Type
    switch req_header_split[0] {
    case "GET": req_type = HTTP_Requst_Type.GET
    case "POST": req_type = HTTP_Requst_Type.POST
    }

    request := HTTP_Request{ client, req_type, req_header_split[1] }

    if request.path in routes {
        routes[request.path](request)
        return
    }

    send_response(request.conn, HTTP_Response_Code.NOT_FOUND, strings.concatenate([]string{"You are requesting: ", request.path, " which doesn't exist :("}), HTTP_Content_Type.TEXT_PLAIN)
}

listen :: proc {
    listen_config,
    listen_values,
}

listen_config :: proc(server_config: HTTP_Server_Config) {
    sock, listen_err := net.listen_tcp(net.Endpoint{
        port = server_config.port,
        address = server_config.address
    })
    defer net.close(sock)

    if listen_err != nil {
        log.fatal("Couldn't create TCP Socket: ", listen_err)
        return
    }

    for {
        client, src, accept_err := net.accept_tcp(sock)
        if accept_err != nil {
            log.warn("Error accepting connection from: ", src, " Error: ", accept_err)
            continue
        }

        log.info("Got new connection from: ", src)

        thread.run_with_poly_data2(client, server_config.routes, handle_client)
    }
}

listen_values :: proc(
    routes: map[string]proc(HTTP_Request),
    port: int,
    address: net.Address = net.IP4_Loopback,
    multithread: bool = true
    ) {
    listen_config(HTTP_Server_Config{routes = routes, port = port, address = net.IP4_Loopback, multithread = true})
}
