// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// Pruned: removed declarationsToJSON and SourceDeclaration-dependent functions.

import Foundation

func toJSON(_ object: Any, options: JSONSerialization.WritingOptions? = nil) -> String {
    if let array = object as? [Any], array.isEmpty {
        return "[\n\n]"
    }
    do {
        let options = options ?? [.prettyPrinted, .sortedKeys]
        let prettyJSONData = try JSONSerialization.data(withJSONObject: object, options: options)
        if let jsonString = String(data: prettyJSONData, encoding: .utf8) {
            return jsonString
        }
    } catch {}
    return ""
}

func toNSDictionary(_ dictionary: [String: SourceKitRepresentable]) -> NSDictionary {
    func toNSDictionaryValue(_ object: SourceKitRepresentable) -> Any {
        switch object {
        case let object as [SourceKitRepresentable]:
            return object.map { toNSDictionaryValue($0) }
        case let object as [[String: SourceKitRepresentable]]:
            return object.map { toNSDictionary($0) }
        case let object as [String: SourceKitRepresentable]:
            return toNSDictionary(object)
        case let object as String:
            return object
        case let object as Int64:
            return NSNumber(value: object)
        case let object as Bool:
            return NSNumber(value: object)
        case let object as Any:
            return object
        default:
            fatalError("Should never happen because we've checked all SourceKitRepresentable types")
        }
    }

    return dictionary.mapValues(toNSDictionaryValue).bridge()
}
