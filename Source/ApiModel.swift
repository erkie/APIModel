import Foundation

public typealias JSONMapping = [String:Transform]

public protocol ApiModel {
    // https://realm.io/docs/swift/latest/#best-practices
    // Insert-or-update — If your dataset has a unique identifier,
    // such as a primary key, you can use it to easily implement
    // insert-or-update logic using Realm().add(_:update:): with
    // new information received from a REST API response. These
    // methods automatically check if each object already
    // exists and will accordingly either
    var insertOrUpdate: Bool? { get }
    
    static func apiNamespace() -> String
    static func apiRoutes() -> ApiRoutes
    static func fromJSONMapping() -> JSONMapping
    func JSONDictionary() -> [String:AnyObject]
}

public extension ApiModel {
    var insertOrUpdate: Bool? { return false }
}