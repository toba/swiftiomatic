/// A type describing the Swiftiomatic version.
struct SwiftiomaticVersion: VersionComparable, Sendable {
  let value: String

  var rawValue: String {
    value
  }

  static let current = Self(value: "1.0.0")
}
