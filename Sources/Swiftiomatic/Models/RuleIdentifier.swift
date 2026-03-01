/// An identifier representing a rule, or all rules.
package enum RuleIdentifier: Hashable, ExpressibleByStringLiteral, Comparable, Sendable {
    // MARK: - Values

    /// Special identifier that should be treated as referring to 'all' rules. One helpful usecase is in
    /// disabling all rules in a given file by adding a `// sm:disable all` comment at the top of the
    /// file.
    case all

    /// Represents a single rule with the specified identifier.
    case single(identifier: String)

    // MARK: - Properties

    private static let allStringRepresentation = "all"

    /// The spelling of the string for this identifier.
    var stringRepresentation: String {
        switch self {
            case .all:
                return Self.allStringRepresentation

            case let .single(identifier):
                return identifier
        }
    }

    // MARK: - Initializers

    /// Creates a `RuleIdentifier` by its string representation.
    ///
    /// - Parameters:
    ///   - value: The string representation.
    init(_ value: String) {
        self = value == Self.allStringRepresentation ? .all : .single(identifier: value)
    }

    // MARK: - ExpressibleByStringLiteral Conformance

    package init(stringLiteral value: String) {
        self = Self(value)
    }

    // MARK: - Comparable Conformance

    package static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.stringRepresentation < rhs.stringRepresentation
    }
}
