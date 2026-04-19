public import Foundation

extension KeyedDecodingContainer {
    //    func decode<T: Decodable>(_ key: Key) throws -> T {
    //        try decode(T.self, forKey: key)
    //    }

    //    func decode<T: DecodableWithConfiguration>(
    //        _ key: Key,
    //        with configuration: T.DecodingConfiguration
    //    ) throws -> T {
    //        try decode(T.self, forKey: key, configuration: configuration)
    //    }

    // MARK: subscript

    public subscript<T: Decodable>(key: Key) -> T {
        get throws { try decode(T.self, forKey: key) }
    }

    //    subscript<T: Decodable>(key: Key, otherwise value: T) -> T {
    //        get throws { try decodeIfPresent(T.self, forKey: key) ?? value }
    //    }

    //    subscript<T>(orEmpty key: Key) -> T where T: Decodable & RangeReplaceableCollection {
    //        get throws { try decodeIfPresent(T.self, forKey: key) ?? .init() }
    //    }

    //    subscript<T: Decodable>(key: Key, failWith value: T) -> T {
    //        do {
    //            return try decode(T.self, forKey: key)
    //        } catch {
    //            assertionFailure("Could not decode \(key): \(error)")
    //            return value
    //        }
    //    }

    public subscript<T: DecodableWithConfiguration>(
        key: Key,
        with configuration: T.DecodingConfiguration,
    ) -> T {
        get throws { try decode(T.self, forKey: key, configuration: configuration) }
    }

    // MARK: conditional

    /// Return value of the key if it exists, otherwise return `nil`
    ///
    /// This is different from standard `Decodable` behavior which will throw an error if the key
    /// is not present
    public func ifPresent<T: Decodable>(_ key: Key) throws -> T? {
        try decodeIfPresent(T.self, forKey: key)
    }

    /// Return value of the key if it exists, otherwise return the `otherwise` value
    public func ifPresent<T: Decodable>(_ key: Key, otherwise value: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? value
    }

    /// Return string value or `nil` if the key is not present or its value is an empty string
    public func ifNotEmpty(_ key: Key) throws -> String? {
        if let value = try decodeIfPresent(String.self, forKey: key) {
            value.isEmpty ? nil : value
        } else {
            nil
        }
    }

    /// Return the value or `nil` if an empty string is found
    public func ifNotEmptyString<T: Decodable>(_ key: Key) throws -> T? {
        if let value = try decodeIfPresent(String.self, forKey: key), value.isEmpty {
            nil
        } else {
            try decodeIfPresent(T.self, forKey: key)
        }
    }

    /// Return `String` value of a key that may be stored as a number
    public func maybeInt(_ key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            value
        } else {
            try String(decode(Int.self, forKey: key))
        }
    }

    /// Return `String` value of a key that may be stored as a number or return `nil` if the key is
    /// not present
    public func maybeIntIfPresent(_ key: Key) throws -> String? {
        if contains(key) { try maybeInt(key) } else { nil }
    }

    /// Return `String` value of a key that may be stored as a number or return `nil` if the key is
    /// not present
    //    func maybeIntIfNotEmpty(_ key: Key) throws -> String? {
    //        if let value = try? decodeIfPresent(String.self, forKey: key) {
    //            value.isEmpty ? nil : value
    //        } else if let value = try? decodeIfPresent(Int.self, forKey: key) {
    //            String(value)
    //        } else {
    //            nil
    //        }
    //    }

    /// Return `String` value of a key that may be stored as a number. If there is an error then
    /// return the `otherwise` value.
    //    func maybeInt(_ key: Key, otherwise value: String) -> String {
    //        do {
    //            return try maybeInt(key)
    //        } catch {
    //            // assertionFailure("Could not decode \(key): \(error)")
    //            return value
    //        }
    //    }

    /// Attempt to convert various value types to a boolean
    public func truthLike(_ key: Key, otherwise: Bool = false) -> Bool {
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

    /// Value container at given key organized with ``AnyCodingKey``
    //    func nestedAnyContainer(_ key: Key) throws -> KeyedDecodingContainer<AnyCodingKey> {
    //        try nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
    //    }

    //    func nestedAnyContainer(_ key: String) throws -> KeyedDecodingContainer<AnyCodingKey> {
    //        try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(key))
    //    }
}
