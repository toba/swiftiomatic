import Darwin
import Foundation
import SourceKitC

/// Wrapper to make a non-Sendable value sendable in contexts where the caller guarantees safety.
private struct UncheckedSendableValue<Value>: @unchecked Sendable {
    var value: Value
    init(_ value: Value) { self.value = value }
}

// MARK: - SourceKitObjectConvertible

protocol SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? { get }
}

extension Array: SourceKitObjectConvertible where Element: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        let children = map(\.sourceKitObject)
        let objects = children.map { $0?.sourcekitdObject }
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
        let values = children.map { $0?.sourcekitdObject }
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

/// Swift representation of sourcekitd_object_t
final class SourceKitObject {
    fileprivate let sourcekitdObject: sourcekitd_object_t
    private var children: [SourceKitObject?]

    init(yaml: String) {
        sourcekitdObject = sourcekitd_request_create_from_yaml(yaml, nil)!
        children = []
    }

    fileprivate init(_ sourcekitdObject: sourcekitd_object_t, children: [SourceKitObject?] = []) {
        self.sourcekitdObject = sourcekitdObject
        self.children = children
    }

    deinit {
        sourcekitd_request_release(sourcekitdObject)
    }

    func updateValue(_ value: SourceKitObjectConvertible, forKey key: UID) {
        precondition(value.sourceKitObject != nil)
        let sourceKitObject = value.sourceKitObject
        children.append(sourceKitObject)
        sourcekitd_request_dictionary_set_value(
            sourcekitdObject, key.sourcekitdUID, sourceKitObject!.sourcekitdObject,
        )
    }

    func updateValue(_ value: SourceKitObjectConvertible, forKey key: String) {
        updateValue(value, forKey: UID(key))
    }

    func updateValue<T: RawRepresentable>(_ value: SourceKitObjectConvertible, forKey key: T)
        where T.RawValue == String
    {
        updateValue(value, forKey: UID(key.rawValue))
    }

    func sendSync() -> sourcekitd_response_t? {
        sourcekitd_send_request_sync(sourcekitdObject)
    }

    func sendAsync() async throws -> sourcekitd_response_t {
        let handle = UncheckedSendableValue(
            UnsafeMutablePointer<sourcekitd_request_handle_t?>.allocate(capacity: 1),
        )

        return try await withTaskCancellationHandler {
            try await withUnsafeThrowingContinuation { continuation in
                sourcekitd_send_request(sourcekitdObject, handle.value) { response in
                    enum SourceKitSendError: Error { case error, noResponse }

                    guard let response else {
                        continuation.resume(throwing: SourceKitSendError.noResponse)
                        return
                    }

                    if sourcekitd_response_is_error(response) {
                        continuation.resume(throwing: SourceKitSendError.error)
                    } else {
                        let sendable = UncheckedSendableValue(response)
                        continuation.resume(returning: sendable.value)
                    }
                }
            }
        } onCancel: {
            sourcekitd_cancel_request(handle.value)
        }
    }
}

extension SourceKitObject: SourceKitObjectConvertible {
    var sourceKitObject: SourceKitObject? {
        self
    }
}

extension SourceKitObject: CustomStringConvertible {
    var description: String {
        let bytes = sourcekitd_request_description_copy(sourcekitdObject)!
        defer { free(bytes) }
        return String(cString: bytes)
    }
}

extension SourceKitObject: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: SourceKitObject...) {
        let objects: [sourcekitd_object_t?] = elements.map(\.sourcekitdObject)
        self.init(sourcekitd_request_array_create(objects, objects.count)!, children: elements)
    }
}

extension SourceKitObject: ExpressibleByDictionaryLiteral {
    convenience init(dictionaryLiteral elements: (UID, SourceKitObjectConvertible)...) {
        let keys: [sourcekitd_uid_t?] = elements.map(\.0.sourcekitdUID)
        let children = elements.map(\.1.sourceKitObject)
        let values: [sourcekitd_object_t?] = children.map { $0?.sourcekitdObject }
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
