/// A type describing the vendored lint engine version.
struct LintVersion: VersionComparable, Sendable {
  let value: String

  var rawValue: String {
    value
  }

  static let current = Self(value: "0.63.2")
}
