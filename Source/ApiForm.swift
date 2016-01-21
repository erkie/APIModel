import RealmSwift
import Alamofire

public protocol ApiModelResponseable {
    
    var responseData: [String:AnyObject]? { get set }
    var rawResponse: ApiResponse?  { get set }
    
    var serverErrors: AnyObject?  { get set }
    var validationErrors: [[String : String]]?  { get set }
}

public extension ApiModelResponseable {
    
    private func errorArraytoStrings(array: [[String: String]]?) -> [String]? {
        if let array = array {
            var messages = [String]()
            
            for fieldErrors in array {
                
                for (field, descrpt) in fieldErrors {
                    messages.append("\(field.capitalizedString): \(descrpt)")
                }
            }
            
            return messages
        }
        
        return nil
    }
    
    var isSuccessful: Bool {
        if let rawResponse = self.rawResponse {
            return rawResponse.isSuccessful
        }
        
        return false
    }
    
    var serverErrorMessages: [String]? {
        
        if let serverErrors = serverErrors as? [[String: String]] {
            return errorArraytoStrings(serverErrors)
        }
        
        return nil
    }
    
    var hasInternalServerError: Bool {
        if let rawResponse = self.rawResponse where rawResponse.isInternalServerError {
            return true
        }
        
        return false
    }
    
    var hasValidationErrors: Bool {
        if let rawResponse = self.rawResponse where rawResponse.isUnprocessableEntity {
            return true
        }
        
        return false
    }
    
    var hasErrors: Bool {
        return hasValidationErrors || hasInternalServerError
    }
    
    
    var validationErrorMessages: [String]? {
        return errorArraytoStrings(validationErrors)
    }
}


public class ApiModelResponse<ModelType:Object where ModelType:ApiModel> : ApiModelResponseable {
    public var responseData: [String:AnyObject]?
    public var rawResponse: ApiResponse?
    public var serverErrors: AnyObject?
    public var validationErrors: [[String : String]]?
    
    private var responseObject: [String:AnyObject]?
    private var responseArray: [AnyObject]?
    private var object: ModelType?
    private var array: [ModelType]?
}

public class Api<ModelType:Object where ModelType:ApiModel> {
    public typealias ResponseCallback = (ApiModelResponse<ModelType>) -> Void
    public typealias ArrayResponseCallback = ([ModelType]?, ApiModelResponse<ModelType>?) -> Void
    public typealias ObjectResponseCallback = (ModelType?, ApiModelResponse<ModelType>?) -> Void
    
    public var apiConfig: ApiConfig
    private var model: ModelType
    private var apiModelResponse: ApiModelResponse<ModelType>?
    
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
        if let responseObject = response.responseObject {
            model.modifyStoredObject {
                self.model.updateFromDictionary(responseObject)
            }
            
            self.apiModelResponse = response
        }
    }
    
    public class func fromApi(apiResponse: [String:AnyObject]) -> ModelType {
        let newModel = ModelType()
        newModel.updateFromDictionary(apiResponse)
        return newModel
    }
    
    // api-model style methods
    
    public class func performWithMethod(method: Alamofire.Method, path: String, parameters: RequestParameters, apiConfig: ApiConfig, callback: ResponseCallback?) {
        let call = ApiCall(method: method, path: path, parameters: parameters, namespace: ModelType.apiNamespace())
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
    
    public class func find(callback: ObjectResponseCallback) {
        get(ModelType.apiRoutes().index) { response in
            callback(response.object, response)
        }
    }
    
    public class func findArray(callback: ArrayResponseCallback) {
        findArray(ModelType.apiRoutes().index, callback: callback)
    }
    
    public class func findArray(path: String, callback: ArrayResponseCallback) {
        get(path) { response in
            callback(response.array, response)
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
    
    public func save(callback: ResponseCallback) {
        let parameters: [String: AnyObject] = [
            ModelType.apiNamespace(): model.JSONDictionary()
        ]
        
        let responseCallback: ResponseCallback = { response in
            self.updateFromResponse(response)
            callback(response)
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
        ){ apiResponse, error in
            
            let response = ApiModelResponse<ModelType>()
            
            response.rawResponse = apiResponse

            if let apiResponse = apiResponse, parsedResponse: AnyObject = apiResponse.parsedResponse {
                response.responseData = parsedResponse as? [String:AnyObject]
                
                if let responseData = response.responseData, errors = responseData["errors"] {
                    response.serverErrors = errors
                } else if apiResponse.isInternalServerError{
                    response.serverErrors = [["base": "An unexpected server error occured"]]
                }
                
                if let responseObject = self.objectFromResponseForNamespace(parsedResponse, namespace: call.namespace) {
                    response.responseObject = responseObject
                    response.object = self.fromApi(responseObject)
                    
                    
                    if let validationErrors = responseObject["errors"] as? [[String : String]] {
                        response.validationErrors = validationErrors
                    }
                    
                } else if let arrayData = self.arrayFromResponseForNamespace(parsedResponse, namespace: call.namespace) {
                    response.responseArray = arrayData
                    response.array = []
                    
                    for modelData in arrayData {
                        if let modelDictionary = modelData as? [String:AnyObject] {
                            response.array?.append(self.fromApi(modelDictionary))
                        }
                    }
                }
            }

            callback?(response)
        }
    }
    
    private class func objectFromResponseForNamespace(data: AnyObject, namespace: String) -> [String:AnyObject]? {
        return (data[namespace] as? [String:AnyObject]) ?? (data[namespace.pluralize()] as? [String:AnyObject])
    }
    
    private class func arrayFromResponseForNamespace(data: AnyObject, namespace: String) -> [AnyObject]? {
        return (data[namespace] as? [AnyObject]) ?? (data[namespace.pluralize()] as? [AnyObject])
    }
}
