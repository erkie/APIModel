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
            
            let transformedValue = transform.perform(optionalValue)
            
            if let primaryKey = realmObject.dynamicType.primaryKey(),
                let modelsPrimaryKey = realmObject[primaryKey] as? ApiId,
                let responsePrimaryKey = transformedValue as? ApiId
                where key == primaryKey && !modelsPrimaryKey.isEmpty
            {
                if modelsPrimaryKey == responsePrimaryKey {
                    continue
                } else {
                    print("APIMODEL WARNING: Api responded with different ID than stored. Changing this crashes Realm. Skipping (Tried to change \(modelsPrimaryKey) to \(responsePrimaryKey))")
                    continue
                }
            }
            
            realmObject[key] = transformedValue
        }
    }
}

func dictionaryFromDictionaryWithMapping(realmObject: Object, data: [String:AnyObject], mapping: JSONMapping) -> [String:AnyObject] {
    
    var transformedData: [String:AnyObject] = [:]
    
    for (var key, value) in data {
        key = camelizedString(key)
        
        if let transform = mapping[key] {
            var optionalValue: AnyObject? = value as AnyObject?
            
            if value.isKindOfClass(NSNull) {
                optionalValue = nil
            }
            
            transformedData[key] = transform.perform(optionalValue)
        }
    }
    
    return transformedData
    
}

extension Object {
    public func updateFromForm(data: NSDictionary) {
        let mapping = (self as! ApiModel).dynamicType.fromJSONMapping()
        updateFromDictionaryWithMapping(data as! [String:AnyObject], mapping: mapping)
    }
    
    // We need to pass in JSONMapping manually because of problems in Swift
    // It's impossible to cast Objects to "Object that conforms to ApiModel" currently...
    public func updateFromForm(data: NSDictionary, mapping: JSONMapping) {
        updateFromDictionaryWithMapping(data as! [String:AnyObject], mapping: mapping)
    }
    
    public func updateFromDictionary(data: [String:AnyObject]) {
        let mapping = (self as! ApiModel).dynamicType.fromJSONMapping()
        updateRealmObjectFromDictionaryWithMapping(self, data: data, mapping: mapping)
    }
    
    public func updateFromDictionaryWithMapping(data: [String:AnyObject], mapping: JSONMapping) {
        updateRealmObjectFromDictionaryWithMapping(self, data: data, mapping: mapping)
    }
    
    public func createOrUpdateFromDictionary(data: [String:AnyObject]) {
        let mapping = (self as! ApiModel).dynamicType.fromJSONMapping()
        let transformedDictionary = dictionaryFromDictionaryWithMapping(self, data: data, mapping: mapping)

        if let realm = realm {
            realm.create(self.dynamicType, value: transformedDictionary, update: true)
        }
    }
}
