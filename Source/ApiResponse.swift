import Foundation

public class ApiResponse {
    public var request: ApiRequest
    public var responseBody: String?
    public var error: NSError?
    public var status: Int?
    public var parsedResponse: AnyObject?
    
    public var isSuccessful: Bool {
        if let status = status {
            return status >= 200 && status <= 299
        }
        
        return false
    }
    
    public var isInternalServerError: Bool {
        if let status = status {
            return status >= 500 && status <= 599
        }
        
        return false
    }
    
    public var isUnprocessableEntity: Bool {
        if let status = status {
            return status == 422
        }
        
        return false
    }
    
    public var isClientError: Bool {
        if let status = status {
            return status >= 400 && status <= 499
        } else {
            return true
        }
    }
    
    public init(request: ApiRequest) {
        self.request = request
    }
}
