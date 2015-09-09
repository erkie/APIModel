import Foundation

public enum ApiRoutesAction {
    case Index
    case Show
    case Create
    case Update
    case Destroy
}


public class ApiRoutes {
    public var index: String
    public var show: String
    public var create: String
    
    public var update: String {
        get {
            return show
        }
    }

    public var destroy: String {
        get {
            return show
        }
    }

    public class func resource(resourcePath: String) -> ApiRoutes {
        return ApiRoutes(index: resourcePath, show: resourcePath)
    }

    public init(index: String, show: String, create: String) {
        self.index = index
        self.show = show
        self.create = create
    }

    public convenience init(index: String, show: String) {
        self.init(index: index, show: show, create: index)
    }

    public convenience init() {
        self.init(index: "NO RESOURCE DEFINED", show: "NO RESOURCE DEFINED", create: "NO RESOURCE DEFINED")
    }
    
    public func getAction(resourceAction: ApiRoutesAction) -> String {
        switch resourceAction {
        case .Index:
            return index
        case .Create:
            return create
        case .Show:
            return show
        case .Update:
            return update
        case .Destroy:
            return destroy
        }
    }
}
