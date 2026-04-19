import Foundation

/// CodingKey implementation that automatically discovers all string and integer keys
///
/// This avoids the need to predefine a [CodingKey enumeration][dev]. The implementation is based on
/// [advanced-codable][git] and the accompanying [article][nap].
///
/// [dev]: https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types#2904057
/// [git]: https://github.com/rnapier/advanced-codable/tree/main
/// [nap]: https://robnapier.net/anycodingkey
package struct AnyCodingKey: CodingKey, CustomStringConvertible, ExpressibleByStringLiteral,
    ExpressibleByIntegerLiteral, Hashable, Comparable
{
    package var description: String { stringValue }
    package let stringValue: String
    package init(_ string: String) { stringValue = string }
    package init?(stringValue: String) { self.init(stringValue) }
    package var intValue: Int?
    package init(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }

    //    public init(_ base: some CodingKey) {
    //        if let intValue = base.intValue {
    //            self.init(intValue: intValue)
    //        } else {
    //            self.init(stringValue: base.stringValue)!
    //        }
    //    }

    package init(stringLiteral value: String) { self.init(value) }
    package init(integerLiteral value: Int) { self.init(intValue: value) }
    package static func < (lhs: AnyCodingKey, rhs: AnyCodingKey) -> Bool {
        lhs.stringValue < rhs.stringValue
    }
}

extension Decoder {
    package var anyKeyedContainer: KeyedDecodingContainer<AnyCodingKey> {
        get throws { try container(keyedBy: AnyCodingKey.self) }
    }
}
