public class ApiNamespace {
    
    public let requestNamespace: String?
    public let responseNamespace: String?
    
    public required init(requestNamespace: String?, responseNamespace: String?) {
        self.requestNamespace = requestNamespace
        self.responseNamespace = responseNamespace
    }
    
}
