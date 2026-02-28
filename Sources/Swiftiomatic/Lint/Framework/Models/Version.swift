/// A type describing the vendored SwiftLint version.
struct LintVersion: VersionComparable, Sendable {
    let value: String

    var rawValue: String { value }

    static let current = Self(value: "0.63.2")

    init(value: String) {
        self.value = value
    }
}
