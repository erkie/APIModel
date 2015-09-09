import RealmSwift
import Alamofire

public enum ApiFormModelStatus {
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

public class ApiFormResponse<ModelType:Object where ModelType:ApiTransformable> {
    public var responseData: [String:AnyObject]?
    public var responseObject: [String:AnyObject]?
    public var responseArray: [AnyObject]?
    public var object: ModelType?
    public var array: [ModelType]?
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
    
    public var responseStatus: ApiFormModelStatus {
        if let status = rawResponse?.status {
            return ApiFormModelStatus(statusCode: status)
        } else {
            return .None
        }
    }
}

public class ApiForm<ModelType:Object where ModelType:ApiTransformable> {
    public typealias ResponseCallback = (ApiFormResponse<ModelType>) -> Void
    
    public var status: ApiFormModelStatus = .None
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
    
    public init(model: ModelType) {
        self.model = model
    }
    
    public func updateFromForm(formParameters: NSDictionary) {
        model.modifyStoredObject {
            self.model.updateFromDictionaryWithMapping(formParameters as! [String:AnyObject], mapping: ModelType.fromJSONMapping())
        }
    }
    
    public func updateFromResponse(response: ApiFormResponse<ModelType>) {
        if let statusCode = response.rawResponse?.status {
            self.status = ApiFormModelStatus(statusCode: statusCode)
        }
        
        if let responseObject = response.responseObject {
            model.modifyStoredObject {
                self.model.updateFromDictionaryWithMapping(responseObject, mapping: ModelType.fromJSONMapping())
            }
        }
        
        if let errors = response.errors {
            self.errors = errors
        }
    }
    
    public class func fromApi(apiResponse: [String:AnyObject]) -> ModelType {
        let newModel = ModelType()
        newModel.updateFromDictionaryWithMapping(apiResponse, mapping: ModelType.fromJSONMapping())
        return newModel
    }
    
    // api-model style methods
    
    public class func get(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        let call = ApiCall(method: .GET, path: path, parameters: parameters, namespace: ModelType.apiNamespace())
        perform(call, callback: callback)
    }
    
    public class func get(path: String, callback: ResponseCallback?) {
        get(path, parameters: [:], callback: callback)
    }
    
    public class func post(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        let call = ApiCall(method: .POST, path: path, parameters: parameters, namespace: ModelType.apiNamespace())
        perform(call, callback: callback)
    }
    
    public class func post(path: String, callback: ResponseCallback?) {
        post(path, parameters: [:], callback: callback)
    }
    
    public class func delete(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        let call = ApiCall(method: .DELETE, path: path, parameters: parameters, namespace: ModelType.apiNamespace())
        perform(call, callback: callback)
    }
    
    public class func delete(path: String, callback: ResponseCallback?) {
        delete(path, parameters: [:], callback: callback)
    }
    
    public class func put(path: String, parameters: RequestParameters, callback: ResponseCallback?) {
        let call = ApiCall(method: .PUT, path: path, parameters: parameters, namespace: ModelType.apiNamespace())
        perform(call, callback: callback)
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
    
    public func save(callback: (ApiForm) -> Void) {
        let parameters: [String: AnyObject] = [
            ModelType.apiNamespace(): model.JSONDictionary()
        ]
        
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
    
    public func destroy(callback: (ApiForm) -> Void) {
        destroy([:], callback: callback)
    }
    
    public func destroy(parameters: RequestParameters, callback: (ApiForm) -> Void) {
        self.dynamicType.delete(model.apiRouteWithReplacements(ModelType.apiRoutes().destroy), parameters: parameters) { response in
            self.updateFromResponse(response)
            callback(self)
        }
    }
    
    public class func perform(call: ApiCall, callback: ResponseCallback?) {
        api().request(
            call.method,
            path: call.path,
            parameters: call.parameters
        ) { data, error in
            let response = ApiFormResponse<ModelType>()
            response.rawResponse = data
            
            if let errors = self.errorFromResponse(nil, error: error) {
                response.errors = errors
            }
            
            if let data: AnyObject = data?.parsedResponse {
                response.responseData = data as? [String:AnyObject]
                
                if let responseObject = self.objectFromResponseForNamespace(data, namespace: call.namespace) {
                    response.responseObject = responseObject
                    response.object = self.fromApi(responseObject)
                    
                    if let errors = self.errorFromResponse(responseObject, error: error) {
                        response.errors = errors
                    }
                } else if let arrayData = self.arrayFromResponseForNamespace(data, namespace: call.namespace) {
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
    
    private class func errorFromResponse(response: [String:AnyObject]?, error: NSError?) -> [String:[String]]? {
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
