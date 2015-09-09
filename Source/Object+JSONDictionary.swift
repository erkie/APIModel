import Foundation
import RealmSwift

func camelizedString(string: String) -> String {
    var items: [String] = string.componentsSeparatedByString("_")
    var camelCase = items.removeAtIndex(0)
    for item: String in items {
        camelCase += item.capitalizedString
    }
    return camelCase
}

func updateRealmObjectFromDictionaryWithMapping(realmObject: Object, data: [String:AnyObject], mapping: JSONMapping) {
    for (var key, value) in data {
        key = camelizedString(key)

        if let transform = mapping[key] {
            var optionalValue: AnyObject? = value as AnyObject?

            if value.isKindOfClass(NSNull) {
                optionalValue = nil
            }
 
            realmObject[key] = transform.perform(optionalValue)
        }
    }
}

extension Object {
    // We need to pass in JSONMapping manually because of problems in Swift
    // It's impossible to cast Objects to "Object that conforms to ApiTransformable" currently...
    public func updateFromForm(data: NSDictionary, mapping: JSONMapping) {
        updateFromDictionaryWithMapping(data as! [String:AnyObject], mapping: mapping)
    }

    public func updateFromDictionaryWithMapping(data: [String:AnyObject], mapping: JSONMapping) {
        updateRealmObjectFromDictionaryWithMapping(self, data: data, mapping: mapping)
    }
}
