import Foundation

public typealias JSONMapping = [String:Transform]

public protocol ApiModel {
    
    static func apiAwareNamespace() -> ApiNamespace
    
    static func apiNamespace() -> String
    
    static func apiRoutes() -> ApiRoutes
    static func fromJSONMapping() -> JSONMapping
    func JSONDictionary() -> [String:AnyObject]

}

/*
 * Needed for backward compatibility
 */
public extension ApiModel {
    
    static func apiNamespace() -> String {
        return ""
    }
    
    static func apiAwareNamespace() -> ApiNamespace {
        var namespace = apiNamespace()
        if namespace == "" {
            return ApiNamespace(requestNamespace: nil, responseNamespace: nil)
        } else {
            return ApiNamespace(requestNamespace: namespace, responseNamespace: namespace)
        }
    }
 
}
