public import SwiftiomaticSyntax

/// A type describing the Swiftiomatic version.
public struct SwiftiomaticVersion: VersionComparable, Sendable {
  public let value: String

  public var rawValue: String {
    value
  }

  public static let current = Self(value: "0.22.0")
}
