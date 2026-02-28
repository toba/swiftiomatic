import Foundation

/// Version number wrapper
struct Version: RawRepresentable, Comparable, ExpressibleByStringLiteral, CustomStringConvertible,
    Sendable
{
    let rawValue: String

    static let undefined = Version(rawValue: "0")!

    init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }

    init?(rawValue: String) {
        let rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CharacterSet.decimalDigits.contains(rawValue.unicodeScalars.first ?? " ") else {
            return nil
        }
        self.rawValue = rawValue
    }

    static func < (lhs: Version, rhs: Version) -> Bool {
        lhs.rawValue.compare(
            rhs.rawValue,
            options: .numeric,
            locale: Locale(identifier: "en_US"),
        ) == .orderedAscending
    }

    var description: String {
        rawValue
    }
}
