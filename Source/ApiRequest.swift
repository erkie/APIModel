import Alamofire

public class ApiRequest {
    public var configuration: ApiConfiguration
    public var method: Alamofire.Method
    public var path: String
    public var parameters: [String:AnyObject] = [:]
    public var headers: [String:String] = [:]
    public var userInfo: [String:AnyObject] = [:]
    
    public var encoding: ParameterEncoding {
        return configuration.encoding
    }
    
    public init(configuration: ApiConfiguration, method: Alamofire.Method, path: String) {
        self.configuration = configuration
        self.method = method
        self.path = path
    }
    
    public var url: String {
        if let _ = NSURL(string: path)?.scheme {
            return path
        } else {
            return configuration.host + path
        }
    }
}
