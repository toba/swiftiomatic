import Foundation

/// Lightweight encoder that captures key-value pairs as `JSONValue` instead of `Any` , enabling
/// type-safe equality and direct encoding without `JSONSerialization` round-trips.
///
/// **Invariant**: only used by `Configuration.encode(to:)` to project flat key/value rule and
/// setting maps into a keyed container. Top-level unkeyed encoding, `superEncoder` , and nested
/// containers are never reached on this path. If a future caller needs them, implement them rather
/// than removing the trap.
final class JSONValueEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var values: [String: JSONValue] = [:]

    func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(JSONValueKeyedContainer<Key>(encoder: self))
    }
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        preconditionFailure("JSONValueEncoder does not support unkeyed containers; see type doc.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        JSONValueSingleContainer(encoder: self)
    }

    private struct JSONValueKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: JSONValueEncoder
        var codingPath: [CodingKey] = []

        mutating func encodeNil(forKey key: Key) { encoder.values[key.stringValue] = .null }
        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.values[key.stringValue] = try JSONValueBuilder.build(value)
        }
        mutating func nestedContainer<NestedKey: CodingKey>(
            keyedBy _: NestedKey.Type,
            forKey _: Key
        ) -> KeyedEncodingContainer<NestedKey> {
            preconditionFailure(
                "JSONValueEncoder does not support nested keyed containers; see type doc.")
        }
        mutating func nestedUnkeyedContainer(forKey _: Key) -> UnkeyedEncodingContainer {
            preconditionFailure(
                "JSONValueEncoder does not support nested unkeyed containers; see type doc.")
        }
        mutating func superEncoder() -> any Encoder {
            preconditionFailure("JSONValueEncoder does not support superEncoder; see type doc.")
        }
        mutating func superEncoder(forKey _: Key) -> any Encoder {
            preconditionFailure("JSONValueEncoder does not support superEncoder; see type doc.")
        }
    }

    private struct JSONValueSingleContainer: SingleValueEncodingContainer {
        let encoder: JSONValueEncoder
        var codingPath: [CodingKey] = []
        mutating func encodeNil() { encoder.values["_singleValue"] = .null }
        mutating func encode<T: Encodable>(_ value: T) throws {
            encoder.values["_singleValue"] = try JSONValueBuilder.build(value)
        }
    }
}

// MARK: - JSONValueBuilder

/// Recursive `Encoder` that builds a `JSONValue` directly, without round-tripping through
/// `JSONEncoder` + `JSONDecoder` . Used by `JSONValueEncoder` to convert `Encodable` rule and
/// setting values into typed JSON.
final class JSONValueBuilder: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]

    final class Storage {
        var value: JSONValue = .null
    }
    fileprivate let storage: Storage

    init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        storage = Storage()
    }

    var result: JSONValue { storage.value }

    func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        if case .object = storage.value {} else { storage.value = .object([:]) }
        return KeyedEncodingContainer(KeyedContainer<Key>(storage: storage, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        if case .array = storage.value {} else { storage.value = .array([]) }
        return UnkeyedContainer(storage: storage, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        SingleContainer(storage: storage, codingPath: codingPath)
    }

    /// Encode any `Encodable` to a `JSONValue` without round-tripping through `Data` .
    static func build<T: Encodable>(_ value: T) throws -> JSONValue {
        switch value {
            case let v as String: return .string(v)
            case let v as Bool: return .bool(v)
            case let v as Int: return .int(v)
            case let v as any FixedWidthInteger: return .int(Int(v))
            case let v as Double: return .double(v)
            case let v as any BinaryFloatingPoint: return .double(Double(v))
            default: break
        }
        let builder = JSONValueBuilder()
        try value.encode(to: builder)
        return builder.result
    }
}

private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let storage: JSONValueBuilder.Storage
    var codingPath: [CodingKey]

    private func write(_ key: String, _ value: JSONValue) {
        if case var .object(dict) = storage.value {
            dict[key] = value
            storage.value = .object(dict)
        } else {
            storage.value = .object([key: value])
        }
    }

    mutating func encodeNil(forKey key: Key) { write(key.stringValue, .null) }
    mutating func encode(_ v: Bool, forKey key: Key) throws { write(key.stringValue, .bool(v)) }
    mutating func encode(_ v: String, forKey key: Key) throws { write(key.stringValue, .string(v)) }
    mutating func encode(_ v: Double, forKey key: Key) throws { write(key.stringValue, .double(v)) }
    mutating func encode(_ v: Float, forKey key: Key) throws {
        write(key.stringValue, .double(Double(v)))
    }
    mutating func encode(_ v: Int, forKey key: Key) throws { write(key.stringValue, .int(v)) }
    mutating func encode(_ v: Int8, forKey key: Key) throws { write(key.stringValue, .int(Int(v))) }
    mutating func encode(_ v: Int16, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode(_ v: Int32, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode(_ v: Int64, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode(_ v: UInt, forKey key: Key) throws { write(key.stringValue, .int(Int(v))) }
    mutating func encode(_ v: UInt8, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode(_ v: UInt16, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode(_ v: UInt32, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode(_ v: UInt64, forKey key: Key) throws {
        write(key.stringValue, .int(Int(v)))
    }
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let inner = JSONValueBuilder(codingPath: codingPath + [key])
        try value.encode(to: inner)
        write(key.stringValue, inner.result)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type,
        forKey _: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        preconditionFailure("JSONValueBuilder does not support nestedContainer.")
    }
    mutating func nestedUnkeyedContainer(forKey _: Key) -> UnkeyedEncodingContainer {
        preconditionFailure("JSONValueBuilder does not support nestedUnkeyedContainer.")
    }
    mutating func superEncoder() -> any Encoder {
        preconditionFailure("JSONValueBuilder does not support superEncoder.")
    }
    mutating func superEncoder(forKey _: Key) -> any Encoder {
        preconditionFailure("JSONValueBuilder does not support superEncoder(forKey:).")
    }
}

private struct UnkeyedContainer: UnkeyedEncodingContainer {
    let storage: JSONValueBuilder.Storage
    var codingPath: [CodingKey]
    var count: Int {
        if case let .array(arr) = storage.value { return arr.count }
        return 0
    }

    private func append(_ value: JSONValue) {
        if case var .array(arr) = storage.value {
            arr.append(value)
            storage.value = .array(arr)
        } else {
            storage.value = .array([value])
        }
    }

    mutating func encodeNil() throws { append(.null) }
    mutating func encode(_ v: Bool) throws { append(.bool(v)) }
    mutating func encode(_ v: String) throws { append(.string(v)) }
    mutating func encode(_ v: Double) throws { append(.double(v)) }
    mutating func encode(_ v: Float) throws { append(.double(Double(v))) }
    mutating func encode(_ v: Int) throws { append(.int(v)) }
    mutating func encode(_ v: Int8) throws { append(.int(Int(v))) }
    mutating func encode(_ v: Int16) throws { append(.int(Int(v))) }
    mutating func encode(_ v: Int32) throws { append(.int(Int(v))) }
    mutating func encode(_ v: Int64) throws { append(.int(Int(v))) }
    mutating func encode(_ v: UInt) throws { append(.int(Int(v))) }
    mutating func encode(_ v: UInt8) throws { append(.int(Int(v))) }
    mutating func encode(_ v: UInt16) throws { append(.int(Int(v))) }
    mutating func encode(_ v: UInt32) throws { append(.int(Int(v))) }
    mutating func encode(_ v: UInt64) throws { append(.int(Int(v))) }
    mutating func encode<T: Encodable>(_ value: T) throws {
        let inner = JSONValueBuilder(codingPath: codingPath)
        try value.encode(to: inner)
        append(inner.result)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        preconditionFailure("JSONValueBuilder does not support nestedContainer in unkeyed.")
    }
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        preconditionFailure("JSONValueBuilder does not support nestedUnkeyedContainer.")
    }
    mutating func superEncoder() -> any Encoder {
        preconditionFailure("JSONValueBuilder does not support superEncoder.")
    }
}

private struct SingleContainer: SingleValueEncodingContainer {
    let storage: JSONValueBuilder.Storage
    var codingPath: [CodingKey]

    mutating func encodeNil() throws { storage.value = .null }
    mutating func encode(_ v: Bool) throws { storage.value = .bool(v) }
    mutating func encode(_ v: String) throws { storage.value = .string(v) }
    mutating func encode(_ v: Double) throws { storage.value = .double(v) }
    mutating func encode(_ v: Float) throws { storage.value = .double(Double(v)) }
    mutating func encode(_ v: Int) throws { storage.value = .int(v) }
    mutating func encode(_ v: Int8) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: Int16) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: Int32) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: Int64) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: UInt) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: UInt8) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: UInt16) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: UInt32) throws { storage.value = .int(Int(v)) }
    mutating func encode(_ v: UInt64) throws { storage.value = .int(Int(v)) }
    mutating func encode<T: Encodable>(_ value: T) throws {
        storage.value = try JSONValueBuilder.build(value)
    }
}
