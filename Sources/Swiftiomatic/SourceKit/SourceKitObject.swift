import Foundation
import SourceKitC

// MARK: - SourceKitObjectConvertible

/// A type that can be converted into a ``SourceKitObject`` for use in sourcekitd requests
protocol SourceKitObjectConvertible {
    /// The sourcekitd request object representation, or `nil` if conversion fails
    var sourceKitObject: SourceKitObject? { get }
}

extension Array: SourceKitObjectConvertible where Element: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        let children = map(\.sourceKitObject)
        let objects = children.map { $0?.sourceKitdObject }
        return sourcekitd_request_array_create(objects, objects.count).map {
            SourceKitObject($0, children: children)
        }
    }
}

extension Dictionary: SourceKitObjectConvertible
    where Key: UIDRepresentable, Value: SourceKitObjectConvertible
{
    var sourceKitObject: SourceKitObject? {
        let keys: [sourcekitd_uid_t?] = keys.map(\.uid.sourcekitdUID)
        let children = values.map(\.sourceKitObject)
        let values = children.map { $0?.sourceKitdObject }
        return sourcekitd_request_dictionary_create(keys, values, count).map {
            SourceKitObject($0, children: children)
        }
    }
}

extension Int: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        Int64(self).sourceKitObject
    }
}

extension Int64: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        sourcekitd_request_int64_create(self).map { SourceKitObject($0) }
    }
}

extension String: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        sourcekitd_request_string_create(self).map { SourceKitObject($0) }
    }
}

extension UID: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        sourcekitd_request_uid_create(sourcekitdUID).map { SourceKitObject($0) }
    }
}

// MARK: - SourceKitObject

/// Swift wrapper around `sourcekitd_object_t` with automatic memory management
///
/// Retains child objects to prevent premature deallocation and releases
/// the underlying C object on `deinit`.
final class SourceKitObject {
    fileprivate let sourceKitdObject: sourcekitd_object_t
    private var children: [SourceKitObject?]

    /// Create a request object from a YAML string representation
    ///
    /// - Parameters:
    ///   - yaml: The YAML-formatted request string.
    init(yaml: String) {
        sourceKitdObject = sourcekitd_request_create_from_yaml(yaml, nil)!
        children = []
    }

    fileprivate init(_ sourcekitdObject: sourcekitd_object_t, children: [SourceKitObject?] = []) {
        sourceKitdObject = sourcekitdObject
        self.children = children
    }

    deinit {
        sourcekitd_request_release(sourceKitdObject)
    }

    /// Set a value in this dictionary-type request object
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The ``UID`` key to associate the value with.
    func updateValue(_ value: SourceKitObjectConvertible, forKey key: UID) {
        precondition(value.sourceKitObject != nil)
        let sourceKitObject = value.sourceKitObject
        children.append(sourceKitObject)
        sourcekitd_request_dictionary_set_value(
            sourceKitdObject, key.sourcekitdUID, sourceKitObject!.sourceKitdObject,
        )
    }

    /// Set a value in this dictionary-type request object using a string key
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The string key (converted to a ``UID``).
    func updateValue(_ value: SourceKitObjectConvertible, forKey key: String) {
        updateValue(value, forKey: UID(key))
    }

    /// Set a value in this dictionary-type request object using a `RawRepresentable` key
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The raw-representable key whose `rawValue` is converted to a ``UID``.
    func updateValue<T: RawRepresentable>(_ value: SourceKitObjectConvertible, forKey key: T)
        where T.RawValue == String
    {
        updateValue(value, forKey: UID(key.rawValue))
    }

    /// Send this request synchronously and return the raw response
    func sendSync() -> sourcekitd_response_t? {
        sourcekitd_send_request_sync(sourceKitdObject)
    }
}

extension SourceKitObject: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        self
    }
}

extension SourceKitObject: CustomStringConvertible {
    var description: String {
        let bytes = sourcekitd_request_description_copy(sourceKitdObject)!
        defer { free(bytes) }
        return String(cString: bytes)
    }
}

extension SourceKitObject: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: SourceKitObject...) {
        let objects: [sourcekitd_object_t?] = elements.map(\.sourceKitdObject)
        self.init(sourcekitd_request_array_create(objects, objects.count)!, children: elements)
    }
}

extension SourceKitObject: ExpressibleByDictionaryLiteral {
    convenience init(dictionaryLiteral elements: (UID, SourceKitObjectConvertible)...) {
        let keys: [sourcekitd_uid_t?] = elements.map(\.0.sourcekitdUID)
        let children = elements.map(\.1.sourceKitObject)
        let values: [sourcekitd_object_t?] = children.map { $0?.sourceKitdObject }
        self.init(
            sourcekitd_request_dictionary_create(keys, values, elements.count)!, children: children,
        )
    }
}

extension SourceKitObject: ExpressibleByIntegerLiteral {
    convenience init(integerLiteral value: IntegerLiteralType) {
        self.init(sourcekitd_request_int64_create(Int64(value))!)
    }
}

extension SourceKitObject: ExpressibleByStringLiteral {
    convenience init(stringLiteral value: StringLiteralType) {
        self.init(sourcekitd_request_string_create(value)!)
    }
}
