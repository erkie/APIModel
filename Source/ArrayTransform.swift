import Foundation
import RealmSwift

public class ArrayTransform<T: Object where T:ApiTransformable>: Transform {
    public init() {}

    public func perform(value: AnyObject?) -> AnyObject {
        if let values = value as? [[String:AnyObject]] {
            var models: [AnyObject] = []
            for nestedData in values {
                let model = T()
                updateRealmObjectFromDictionaryWithMapping(model, data: nestedData, mapping: T.fromJSONMapping())

                models.append(model)
            }
            return models
        } else {
            return []
        }
    }
}
