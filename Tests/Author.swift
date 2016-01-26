//
//  Author.swift
//  ApiModel
//
//  Created by Craig Heneveld on 1/25/16.
//
//
import Foundation
import RealmSwift
import ApiModel

class Author: Object, ApiModel {
    // Standard Realm boilerplate
    dynamic var id = ""
    dynamic var name = ""
    
    // has many
    var posts = List<Post>()

    override class func primaryKey() -> String {
        return "id"
    }
    
    // Define the standard namespace this class usually resides in JSON responses
    // MUST BE singular ie `post` not `posts`
    class func apiNamespace() -> String {
        return "author"
    }
    
    // Define where and how to get these. Routes are assumed to use Rails style REST (index, show, update, destroy)
    class func apiRoutes() -> ApiRoutes {
        return ApiRoutes(
            index: "/authors.json",
            show: "/authors/:id:.json"
        )
    }
    
    // Define how it is converted from JSON responses into Realm objects. A host of transforms are available
    // See section "Transforms" in README. They are super easy to create as well!
    class func fromJSONMapping() -> JSONMapping {
        return [
            "id": ApiIdTransform(),
            "name": StringTransform()
        ]
    }
    
    // Define how this object is to be serialized back into a server response format
    func JSONDictionary() -> [String:AnyObject] {
        return [
            "id": id,
            "name": name,
        ]
    }
}