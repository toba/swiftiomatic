import Foundation

/// A semantic version number supporting string-literal initialization and numeric comparison
public struct Version: RawRepresentable, Comparable, ExpressibleByStringLiteral,
  CustomStringConvertible,
  Sendable
{
  public let rawValue: String

  static let undefined = Version(rawValue: "0")!

  public init(stringLiteral value: String) {
    self.init(rawValue: value)!
  }

  public init?(rawValue: String) {
    let rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard CharacterSet.decimalDigits.contains(rawValue.unicodeScalars.first ?? " ") else {
      return nil
    }
    self.rawValue = rawValue
  }

  public static func < (lhs: Version, rhs: Version) -> Bool {
    lhs.rawValue.compare(
      rhs.rawValue,
      options: .numeric,
      locale: Locale(identifier: "en_US"),
    ) == .orderedAscending
  }

  public var description: String {
    rawValue
  }
}
