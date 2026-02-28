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

func toNSDictionary(_ dictionary: [String: SourceKitValue]) -> NSDictionary {
    func toNSValue(_ value: SourceKitValue) -> Any {
        switch value {
            case let .string(s): return s
            case let .int64(n): return NSNumber(value: n)
            case let .bool(b): return NSNumber(value: b)
            case let .data(d): return d
            case let .array(a): return a.map { toNSValue($0) }
            case let .dictionary(d): return toNSDictionary(d)
        }
    }

    return dictionary.mapValues(toNSValue).bridge()
}
