import Foundation
import Alamofire

public class API {
    public var configuration: ApiConfiguration
    
    public var beforeRequestHooks: [((ApiRequest) -> Void)] = []
    public var afterRequestHooks: [((ApiRequest, ApiResponse) -> Void)] = []
    
    public init(configuration: ApiConfiguration) {
        self.configuration = configuration
        
        beforeRequest { request in
            if self.configuration.requestLogging {
                request.userInfo["requestStartedAt"] = NSDate()
                
                println("ApiModel: \(request.method.rawValue) \(request.path) with params: \(request.parameters) \(request.headers)")
            }
        }
        
        afterRequest { request, response in
            if self.configuration.requestLogging {
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
                
                println("ApiModel: \(request.method.rawValue) \(request.path) finished in \(duration) seconds with status \(response.status ?? 0)")
                
                if let error = response.error {
                    print("... Error \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func request(method: Alamofire.Method, path: String, parameters: [String: AnyObject] = [:], headers: [String: String] = [:], responseHandler: (ApiResponse?, NSError?) -> Void) {
        let configuration = api().configuration
        
        var request = ApiRequest(configuration: configuration, method: method, path: path)
        request.parameters = parameters
        request.headers = headers
        
        for hook in beforeRequestHooks {
            hook(request)
        }
        
        performRequest(request) { response in
            configuration.parser.parse(response.responseBody ?? "") { parsedResponse in
                // if response is either nil or NSNull and the request was not 200 it is an error
                if (parsedResponse == nil || (parsedResponse as? NSNull) != nil) && !response.isSuccessful {
                    response.error = NSError(domain: "Bad request", code: response.status ?? 0, userInfo: [:])
                }
                
                if response.isInvalid {
                    response.error = NSError(domain: "Invalid request", code: response.status ?? 0, userInfo: [:])
                }
                
                response.parsedResponse = parsedResponse
                responseHandler(response, response.error)
            }
        }
    }
    
    func performRequest(request: ApiRequest, responseHandler: (ApiResponse) -> Void) {
        var response = ApiResponse(request: request)
        
        Alamofire.request(request.method, request.url, parameters: request.parameters, encoding: request.encoding, headers: request.headers)
            .responseString { _, alamofireResponse, responseBody, error in
                response.responseBody = responseBody
                response.error = error
                response.status = alamofireResponse?.statusCode
                
                for hook in self.afterRequestHooks {
                    hook(request, response)
                }
                
                responseHandler(response)
        }
    }
    
    public func beforeRequest(hook: ((ApiRequest) -> Void)) {
        beforeRequestHooks.append(hook)
    }
    
    public func afterRequest(hook: ((ApiRequest, ApiResponse) -> Void)) {
        afterRequestHooks.append(hook)
    }
}

public struct ApiSingleton {
    static var instance: API = API(configuration: ApiConfiguration())
    
    public static func setInstance(apiInstance: API) {
        instance = apiInstance
    }
}

public func api() -> API {
    return ApiSingleton.instance
}
