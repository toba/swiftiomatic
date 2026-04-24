import Foundation

/// Lightweight encoder that captures key-value pairs as `JSONValue`
/// instead of `Any`, enabling type-safe equality and direct encoding
/// without `JSONSerialization` round-trips.
final class JSONValueEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var values: [String: JSONValue] = [:]

    func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(JSONValueKeyedContainer<Key>(encoder: self))
    }
    func unkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }

    func singleValueContainer() -> SingleValueEncodingContainer {
        JSONValueSingleContainer(encoder: self)
    }

    /// Converts an arbitrary `Encodable` to `JSONValue` via `JSONEncoder`
    /// round-trip. Used only for complex nested types.
    private static func encodeToJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    private struct JSONValueKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: JSONValueEncoder
        var codingPath: [CodingKey] = []

        mutating func encodeNil(forKey key: Key) { encoder.values[key.stringValue] = .null }
        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.values[key.stringValue] = try JSONValueEncoder.toJSONValue(value)
        }
        mutating func nestedContainer<NestedKey: CodingKey>(
            keyedBy _: NestedKey.Type,
            forKey _: Key
        ) -> KeyedEncodingContainer<NestedKey> {
            fatalError()
        }
        mutating func nestedUnkeyedContainer(forKey _: Key) -> UnkeyedEncodingContainer {
            fatalError()
        }
        mutating func superEncoder() -> any Encoder { fatalError() }
        mutating func superEncoder(forKey _: Key) -> any Encoder { fatalError() }
    }

    private struct JSONValueSingleContainer: SingleValueEncodingContainer {
        let encoder: JSONValueEncoder
        var codingPath: [CodingKey] = []
        mutating func encodeNil() { encoder.values["_singleValue"] = .null }
        mutating func encode<T: Encodable>(_ value: T) throws {
            encoder.values["_singleValue"] = try JSONValueEncoder.toJSONValue(value)
        }
    }

    /// Converts a primitive or complex `Encodable` value to `JSONValue`.
    fileprivate static func toJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        switch value {
            case let string as String: .string(string)
            case let bool as Bool: .bool(bool)
            case let integer as any FixedWidthInteger: .int(Int(integer))
            case let floating as any BinaryFloatingPoint: .double(Double(floating))
            default: try encodeToJSONValue(value)
        }
    }
}
