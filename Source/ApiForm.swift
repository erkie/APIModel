import RealmSwift
import Alamofire

public enum ApiModelStatus {
    case None
    case Successful(Int)
    case Unauthorized(Int)
    case Invalid(Int)
    case ServerError(Int)
    
    init(statusCode: Int) {
        if statusCode >= 200 && statusCode <= 299 {
            self = .Successful(statusCode)
        } else if statusCode == 401 {
            self = .Unauthorized(statusCode)
        } else if statusCode >= 400 && statusCode <= 499 {
            self = .Invalid(statusCode)
        } else if statusCode >= 500 && statusCode <= 599 {
            self = .ServerError(statusCode)
        } else {
            self = .None
        }
    }
}

public class ApiModelResponse<ModelType:Object where ModelType:ApiModel> {
    public var responseData: [String:AnyObject]?
    public var responseObject: [String:AnyObject]?
    public var responseArray: [AnyObject]?
    public var errors: [String:[String]]?
    public var rawResponse: ApiResponse?
    
    public var isSuccessful: Bool {
        for (_, errorsForKey) in errors ?? [:] {
            if !errorsForKey.isEmpty {
                return false
            }
        }
        return true
    }
    
    public var responseStatus: ApiModelStatus {
        if let status = rawResponse?.status {
            return ApiModelStatus(statusCode: status)
        } else {
            return .None
        }
    }
    
    var _object: ModelType?
    var _parsedObject = false
    
    public var object: ModelType? {
        if _parsedObject {
            return _object
        }
        
        _parsedObject = true
        
        if let responseObject = responseObject {
            _object = fromApi(responseObject)
        }
        
        return _object
    }
    
    var _array: [ModelType]? = nil
    var _parsedArray = false
    
    public var array: [ModelType]? {
        if _parsedArray {
            return _array
        }
        _parsedArray = true
        
        if let arrayData = responseArray {
            _array = []
            
            for modelData in arrayData {
                if let modelDictionary = modelData as? [String:AnyObject] {
                    _array!.append(fromApi(modelDictionary))
                }
            }
        }
        
        return _array
    }
    
    func fromApi(apiResponse: [String:AnyObject]) -> ModelType {
        let newModel = ModelType()
        newModel.updateFromDictionary(apiResponse)
        return newModel
    }
}

public class Api<ModelType:Object where ModelType:ApiModel> {
    public typealias ResponseCallback = (ApiModelResponse<ModelType>) -> Void
    
    public var apiConfig: ApiConfig
    public var status: ApiModelStatus = .None
    public var errors: [String:[String]] = [:]
    public var model: ModelType
    
    public var errorMessages:[String] {
        var errorString: [String] = []
        for (key, errorsForProperty) in errors {
            for message in errorsForProperty {
                if key == "base" {
                    errorString.append(message)
                } else {
                    errorString.append("\(key.capitalizedString) \(message)")
                }
            }
        }
        return errorString
    }
    
    public var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    public required init(model: ModelType, apiConfig: ApiConfig) {
        self.model = model
        self.apiConfig = apiConfig
    }
    
    public convenience init(model: ModelType) {
        self.init(model: model, apiConfig: self.dynamicType.apiConfigForType())
    }
    
    public static func apiConfigForType() -> ApiConfig {
        if let configurable = ModelType.self as? ApiConfigurable.Type {
            return configurable.apiConfig(apiManager().config.copy())
        } else {
            return apiManager().config
        }
    }
    
    public func updateFromForm(formParameters: NSDictionary) {
        model.modifyStoredObject {
            self.model.updateFromDictionary(formParameters as! [String:AnyObject])
        }
    }
    
    public func updateFromResponse(response: ApiModelResponse<ModelType>) {
        if let statusCode = response.rawResponse?.status {
            self.status = ApiModelStatus(statusCode: statusCode)
        }
        
        if let responseObject = response.responseObject {
            model.modifyStoredObject {
                self.model.updateFromDictionary(responseObject)
            }
        }
        
        if let errors = response.errors {
            self.errors = errors
        }
    }
    
    // api-model style methods
    
    public class func performWithMethod(method: Alamofire.Method, path: String, parameters: RequestParameters, apiConfig: ApiConfig, callback: ResponseCallback?) {
        let call = ApiCall(method: method, path: path, parameters: parameters, namespace: ModelType.apiAwareNamespace())
        perform(call, apiConfig: apiConfig, callback: callback)
    }
    
    // GET
    public class func get(path: String, parameters: RequestParameters, apiConfig: ApiConfig, callback: ResponseCallback?) {
        performWithMethod(.GET, path: path, parameters: parameters, apiConfig: apiConfig, callback: callback)
    }
    
    public class func get(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        get(path, parameters: parameters, apiConfig: apiConfigForType(), callback: callback)
    }
    
    public class func get(path: String, callback: ResponseCallback?) {
        get(path, parameters: [:], callback: callback)
    }
    
    // POST
    public class func post(path: String, parameters: RequestParameters, apiConfig: ApiConfig, callback: ResponseCallback?) {
        performWithMethod(.POST, path: path, parameters: parameters, apiConfig: apiConfig, callback: callback)
    }
    
    public class func post(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        post(path, parameters: parameters, apiConfig: apiConfigForType(), callback: callback)
    }
    
    public class func post(path: String, callback: ResponseCallback?) {
        post(path, parameters: [:], callback: callback)
    }
    
    // DELETE
    public class func delete(path: String, parameters: RequestParameters, apiConfig: ApiConfig, callback: ResponseCallback?) {
        performWithMethod(.DELETE, path: path, parameters: parameters, apiConfig: apiConfig, callback: callback)
    }
    
    public class func delete(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        delete(path, parameters: parameters, apiConfig: apiConfigForType(), callback: callback)
    }
    
    public class func delete(path: String, callback: ResponseCallback?) {
        delete(path, parameters: [:], callback: callback)
    }
    
    // PUT
    public class func put(path: String, parameters: RequestParameters, apiConfig: ApiConfig, callback: ResponseCallback?) {
        performWithMethod(.PUT, path: path, parameters: parameters, apiConfig: apiConfig, callback: callback)
    }
    
    public class func put(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        put(path, parameters: parameters, apiConfig: apiConfigForType(), callback: callback)
    }
    
    public class func put(path: String, callback: ResponseCallback?) {
        put(path, parameters: [:], callback: callback)
    }
    
    // active record (rails) style methods
    
    public class func find(callback: (ModelType?) -> Void) {
        get(ModelType.apiRoutes().index) { response in
            callback(response.object)
        }
    }
    
    public class func findArray(callback: ([ModelType]) -> Void) {
        findArray(ModelType.apiRoutes().index, callback: callback)
    }
    
    public class func findArray(path: String, callback: ([ModelType]) -> Void) {
        get(path) { response in
            callback(response.array ?? [])
        }
    }
    
    public class func create(parameters: RequestParameters, callback: (ModelType?) -> Void) {
        post(ModelType.apiRoutes().create, parameters: parameters) { response in
            callback(response.object)
        }
    }
    
    public class func update(parameters: RequestParameters, callback: (ModelType?) -> Void) {
        put(ModelType.apiRoutes().update, parameters: parameters) { response in
            callback(response.object)
        }
    }
    
    public func save(callback: (Api) -> Void) {
        var parameters = model.JSONDictionary()
        if let namespace = ModelType.apiAwareNamespace().requestNamespace {
            parameters = [namespace : parameters]
        }
        
        let responseCallback: ResponseCallback = { response in
            self.updateFromResponse(response)
            callback(self)
        }
        
        if model.isApiSaved() {
            self.dynamicType.put(model.apiRouteWithReplacements(ModelType.apiRoutes().update), parameters: parameters, callback: responseCallback)
        } else {
            self.dynamicType.post(model.apiRouteWithReplacements(ModelType.apiRoutes().create), parameters: parameters, callback: responseCallback)
        }
    }
    
    public func destroy(callback: (Api) -> Void) {
        destroy([:], callback: callback)
    }
    
    public func destroy(parameters: RequestParameters, callback: (Api) -> Void) {
        self.dynamicType.delete(model.apiRouteWithReplacements(ModelType.apiRoutes().destroy), parameters: parameters) { response in
            self.updateFromResponse(response)
            callback(self)
        }
    }
    
    public class func perform(call: ApiCall, apiConfig: ApiConfig, callback: ResponseCallback?) {
        apiManager().request(
            call.method,
            path: call.path,
            parameters: call.parameters,
            apiConfig: apiConfig
        ) { data, error in
            let response = ApiModelResponse<ModelType>()
            response.rawResponse = data
            
            if let errors = self.errorFromResponse(nil, error: error) {
                response.errors = errors
            }
            
            if let data: AnyObject = data?.parsedResponse {
                response.responseData = data as? [String:AnyObject]
                
                if let responseObject = self.objectFromResponseForNamespace(data, namespace: call.namespace) {
                    response.responseObject = responseObject
                    
                    if let errors = self.errorFromResponse(responseObject, error: error) {
                        response.errors = errors
                    }
                } else if let arrayData = self.arrayFromResponseForNamespace(data, namespace: call.namespace) {
                    response.responseArray = arrayData
                }
            }
            
            callback?(response)
        }
    }
    
    private class func objectFromResponseForNamespace(data: AnyObject, namespace: ApiNamespace) -> [String:AnyObject]? {
        guard let namespace = namespace.responseNamespace else {
            return data as? [String : AnyObject]
        }
        return (data[namespace] as? [String:AnyObject]) ?? (data[namespace.pluralize()] as? [String:AnyObject])
    }
    
    private class func arrayFromResponseForNamespace(data: AnyObject, namespace: ApiNamespace) -> [AnyObject]? {
        guard let namespace = namespace.responseNamespace else {
            return data as? [AnyObject]
        }
        return (data[namespace] as? [AnyObject]) ?? (data[namespace.pluralize()] as? [AnyObject])
    }
    
    private class func errorFromResponse(response: [String:AnyObject]?, error: ApiResponseError?) -> [String:[String]]? {
        if let errors = response?["errors"] as? [String:[String]] {
            return errors
        } else if let errors = response?["errors"] as? [String] {
            return ["base": errors]
        } else if error != nil {
            return ["base": ["An unexpected server error occurred"]]
        } else {
            return nil
        }
    }
}
