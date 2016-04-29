import Foundation
import Alamofire

public typealias RequestParameters = [String:AnyObject]

public class ApiCall {
    public var method: Alamofire.Method
    public var path: String
    public var parameters: RequestParameters = [:]
    public var namespace: ApiNamespace = ApiNamespace(requestNamespace: nil, responseNamespace: nil)

    public required init(method: Alamofire.Method, path: String) {
        self.method = method
        self.path = path
    }
    
    public convenience init(method: Alamofire.Method, path: String, parameters: RequestParameters, namespace: ApiNamespace) {
        self.init(method: method, path: path)
        self.parameters = parameters
        self.namespace = namespace
    }
}
