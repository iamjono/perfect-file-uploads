//
//  MustacheHandler.swift
//
//  Created by Jonathan Guthrie on 2016-07-23.
//  Modified from a file by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectMustache

// Handler class
// When referenced in a mustache template, this class will be instantiated to handle the request
// and provide a set of values which will be used to complete the template.
struct UploadHandler: MustachePageHandler { // all template handlers must inherit from PageHandler

	// This is the function which all handlers must impliment.
	// It is called by the system to allow the handler to return the set of values which will be used when populating the template.
	// - parameter context: The MustacheEvaluationContext which provides access to the WebRequest containing all the information pertaining to the request
	// - parameter collector: The MustacheEvaluationOutputCollector which can be used to adjust the template output. For example a `defaultEncodingFunc` could be installed to change how outgoing values are encoded.
	func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
		#if DEBUG
			print("UploadHandler got request")
		#endif
		var values = MustacheEvaluationContext.MapType()
		// Grab the WebRequest so we can get information about what was uploaded
		let request = contxt.webRequest

		// create uploads dir to store files
		let fileDir = Dir(Dir.workingDir.path + "files")
		do {
			try fileDir.create()
		} catch {
			print(error)
		}
		// Grab the fileUploads array and see what's there
		// If this POST was not multi-part, then this array will be empty

		if let uploads = request.postFileUploads where uploads.count > 0 {
			// Create an array of dictionaries which will show what was uploaded
			// This array will be used in the corresponding mustache template
			var ary = [[String:Any]]()

			for upload in uploads {
				ary.append([
					"fieldName": upload.fieldName,
					"contentType": upload.contentType,
					"fileName": upload.fileName,
					"fileSize": upload.fileSize,
					"tmpFileName": upload.tmpFileName
					])

				// move file to webroot
				let thisFile = File(upload.tmpFileName)
				do {
					let _ = try thisFile.moveTo(path: fileDir.path + upload.fileName, overWrite: true)
				} catch {
					print(error)
				}

			}
			values["files"] = ary
			values["count"] = ary.count
		}

		// Grab the regular form parameters
		let params = request.params()
		if params.count > 0 {
			// Create an array of dictionaries which will show what was posted
			// This will not include any uploaded files. Those are handled above.
			var ary = [[String:Any]]()

			for (name, value) in params {
				ary.append([
					"paramName":name,
					"paramValue":value
					])
			}
			values["params"] = ary
			values["paramsCount"] = ary.count
		}

		values["title"] = "Upload Enumerator"
		contxt.extendValues(with: values)
		do {
			try contxt.requestCompleted(withCollector: collector)
		} catch {
			let response = contxt.webResponse
			response.status = .internalServerError
			response.appendBody(string: "\(error)")
			response.completed()
		}
	}
}
