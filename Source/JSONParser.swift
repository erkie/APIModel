//
//  JSONParser.swift
//  ApiModel
//
//  Created by Erik Rothoff Andersson on 01/06/15.
//
//

import Foundation
import SwiftyJSON

public class JSONParser: ApiParser {
    public func parse(responseString: String, completionHandler: (AnyObject?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            var responseJSON: JSON
            if responseString.isEmpty {
                responseJSON = JSON.null
            } else {
                if let data = (responseString as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
                    responseJSON = SwiftyJSON.JSON(data: data)
                } else {
                    responseJSON = JSON.null
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(responseJSON.dictionaryObject ?? responseJSON.arrayObject ?? NSNull())
            })
        })
    }
}