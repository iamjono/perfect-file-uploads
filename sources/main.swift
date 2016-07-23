//
//  main.swift
//  File Uploads
//
//  Created by Jonathan Guthrie on 2016-07-23.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache

// Create HTTP server
let server = HTTPServer()

let handler = {
	(request: HTTPRequest, response: HTTPResponse) in

	let webRoot = request.documentRoot
	mustacheRequest(request: request, response: response, handler: UploadHandler(), templatePath: webRoot + "/response.mustache")
}

// Add our routes
var routes = Routes()
routes.add(method: .post, uri: "/upload", handler: handler)

server.addRoutes(routes)

// serve static content, including the index.html file
// remember to add files in ./webroot to the buildphase in xcode, to "copyfiles"
server.documentRoot = "./webroot"


// Set the listen port
server.serverPort = 8181


do {
    // Launch the server
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
