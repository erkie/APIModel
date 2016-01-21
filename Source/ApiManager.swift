import Foundation
import Alamofire

public class ApiManager {
    public var config: ApiConfig
    
    public var beforeRequestHooks: [((ApiRequest) -> Void)] = []
    public var afterRequestHooks: [((ApiRequest, ApiResponse) -> Void)] = []
    
    public init(config: ApiConfig) {
        self.config = config
        
        beforeRequest { request in
            if self.config.requestLogging {
                request.userInfo["requestStartedAt"] = NSDate()
                
                print("ApiModel: \(request.method.rawValue) \(request.path) with headers: \(request.headers)")
            }
        }
        
        afterRequest { request, response in
            if self.config.requestLogging {
                let duration: String
                if let requestStartedAt = request.userInfo["requestStartedAt"] as? NSDate {
                    let formatter = NSNumberFormatter()
                    formatter.minimumFractionDigits = 2
                    formatter.maximumFractionDigits = 2
                    formatter.minimumIntegerDigits = 1
                    
                    let requestDuration = NSDate().timeIntervalSinceDate(requestStartedAt)
                    duration = formatter.stringFromNumber(requestDuration) ?? "\(requestDuration)"
                } else {
                    duration = "?"
                }
                
                print("ApiModel: \(request.method.rawValue) \(request.path) finished in \(duration) seconds with status \(response.status ?? 0)")
                
                if let error = response.error {
                    print("... Error \(error.description)")
                }
            }
        }
    }
    
    public func request(
        method: Alamofire.Method,
        path: String,
        parameters: [String: AnyObject] = [:],
        headers: [String: String] = [:],
        apiConfig: ApiConfig,
        responseHandler: (ApiResponse?, NSError?) -> Void
    ) {
        let parser = apiConfig.parser
        
        let request = ApiRequest(
            config: apiConfig,
            method: method,
            path: path
        )
        
        request.parameters = parameters
        request.headers = headers
        
        for hook in beforeRequestHooks {
            hook(request)
        }
        
        performRequest(request) { response in
            
            parser.parse(response.responseBody ?? "") { parsedResponse in
                
                let (finalResponse, error) = self.handleResponse(
                    response,
                    parsedResponse: parsedResponse,
                    apiConfig: apiConfig
                )
                
                responseHandler(finalResponse, error)
            }
        }
    }
    
    public func handleResponse(
        response: ApiResponse,
        parsedResponse: AnyObject?,
        apiConfig: ApiConfig
    ) -> (ApiResponse?, NSError?) {
        
        response.parsedResponse = parsedResponse
        
        if let nestedResponse = parsedResponse as? [String:AnyObject] where !apiConfig.rootNamespace.isEmpty {
            response.parsedResponse = fetchPathFromDictionary(apiConfig.rootNamespace, dictionary: nestedResponse)
        } else {
            response.parsedResponse = parsedResponse
        }
        
        return (response, response.error)
    }
    
    func performRequest(request: ApiRequest, responseHandler: (ApiResponse) -> Void) {
        let response = ApiResponse(request: request)
        
        Alamofire.request(
            request.method,
            request.url,
            parameters: request.parameters,
            encoding: request.encoding,
            headers: request.headers
        )
        .response{ almoRequest, almoResponse, data, error in
            if let almoResponse = almoResponse{
                response.status = almoResponse.statusCode
            }
            
            if let data = data {
                response.responseBody = NSString(data: data, encoding: NSUTF8StringEncoding) as String!
            }
            
            if let error = error{
                response.error = error
            }
            
            for hook in self.afterRequestHooks {
                hook(request, response)
            }
            
            responseHandler(response)
            
        }
    }
    
    public func beforeRequest(hook: ((ApiRequest) -> Void)) {
        beforeRequestHooks.insert(hook, atIndex: 0)
    }
    
    public func afterRequest(hook: ((ApiRequest, ApiResponse) -> Void)) {
        afterRequestHooks.append(hook)
    }
}

public struct ApiSingleton {
    static var instance: ApiManager = ApiManager(config: ApiConfig())
    
    public static func setInstance(apiInstance: ApiManager) {
        instance = apiInstance
    }
}

public func apiManager() -> ApiManager {
    return ApiSingleton.instance
}
