import Alamofire

public class ApiConfig {
    public var host: String = ""
    public var parser: ApiParser = JSONParser()
    public var encoding: ParameterEncoding = .URL
    public var requestLogging: Bool = true
    public var rootNamespace = ""
    public var urlSessionConfig: NSURLSessionConfiguration?
    
    public required init() {
    }
    
    public convenience init(host: String, urlSessionConfig: NSURLSessionConfiguration) {
        self.init()
        self.host = host
        self.urlSessionConfig = urlSessionConfig
    }

    public convenience init(host: String) {
        self.init()
        self.host = host
    }
    
    public convenience init(apiConfig: ApiConfig) {
        self.init()
        self.host = apiConfig.host
        self.parser = apiConfig.parser
        self.encoding = apiConfig.encoding
        self.requestLogging = apiConfig.requestLogging
        self.rootNamespace = apiConfig.rootNamespace
        self.urlSessionConfig = apiConfig.urlSessionConfig
    }
    
    public func copy() -> ApiConfig {
        return ApiConfig(apiConfig: self)
    }
}
