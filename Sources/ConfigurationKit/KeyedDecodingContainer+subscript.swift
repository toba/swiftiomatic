public import Foundation

public extension KeyedDecodingContainer {
    // MARK: subscript

    subscript<T: Decodable>(key: Key) -> T {
        get throws { try decode(T.self, forKey: key) }
    }

    subscript<T: DecodableWithConfiguration>(
        key: Key,
        with configuration: T.DecodingConfiguration,
    ) -> T {
        get throws { try decode(T.self, forKey: key, configuration: configuration) }
    }

    // MARK: conditional

    /// Return value of the key if it exists, otherwise return `nil`
    ///
    /// This is different from standard `Decodable` behavior which will throw an error if the key is
    /// not present
    func ifPresent<T: Decodable>(_ key: Key) throws -> T? {
        try decodeIfPresent(T.self, forKey: key)
    }

    /// Return value of the key if it exists, otherwise return the `otherwise` value
    func ifPresent<T: Decodable>(_ key: Key, otherwise value: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? value
    }

    /// Return string value or `nil` if the key is not present or its value is an empty string
    func ifNotEmpty(_ key: Key) throws -> String? {
        if let value = try decodeIfPresent(String.self, forKey: key) {
            value.isEmpty ? nil : value
        } else {
            nil
        }
    }

    /// Return the value or `nil` if an empty string is found
    func ifNotEmptyString<T: Decodable>(_ key: Key) throws -> T? {
        if let value = try decodeIfPresent(String.self, forKey: key), value.isEmpty {
            nil
        } else {
            try decodeIfPresent(T.self, forKey: key)
        }
    }

    /// Return `String` value of a key that may be stored as a number
    func maybeInt(_ key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            value
        } else {
            try String(decode(Int.self, forKey: key))
        }
    }

    /// Return `String` value of a key that may be stored as a number or return `nil` if the key is
    /// not present
    func maybeIntIfPresent(_ key: Key) throws -> String? {
        if contains(key) { try maybeInt(key) } else { nil }
    }

    /// Attempt to convert various value types to a boolean
    func truthLike(_ key: Key, otherwise: Bool = false) -> Bool {
        if contains(key) {
            if let value: Bool = try? self[key] {
                value
            } else if let value: String = try? self[key] {
                Bool(value) ?? otherwise
            } else if let value: Int = try? self[key] {
                value > 0
            } else {
                otherwise
            }
        } else {
            otherwise
        }
    }
}
