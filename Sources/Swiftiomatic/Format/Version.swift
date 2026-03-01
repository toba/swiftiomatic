import Foundation

/// Version number wrapper
package struct Version: RawRepresentable, Comparable, ExpressibleByStringLiteral, CustomStringConvertible,
    Sendable
{
    package let rawValue: String

    static let undefined = Version(rawValue: "0")!

    package init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }

    package init?(rawValue: String) {
        let rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CharacterSet.decimalDigits.contains(rawValue.unicodeScalars.first ?? " ") else {
            return nil
        }
        self.rawValue = rawValue
    }

    package static func < (lhs: Version, rhs: Version) -> Bool {
        lhs.rawValue.compare(
            rhs.rawValue,
            options: .numeric,
            locale: Locale(identifier: "en_US"),
        ) == .orderedAscending
    }

    package var description: String {
        rawValue
    }
}
