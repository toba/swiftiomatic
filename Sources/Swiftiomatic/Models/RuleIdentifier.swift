/// An identifier representing a rule, or all rules.
public enum RuleIdentifier: Hashable, ExpressibleByStringLiteral, Comparable, Sendable {
    /// Special identifier that should be treated as referring to 'all' rules. One helpful usecase is in
    /// disabling all rules in a given file by adding a `// sm:disable all` comment at the top of the
    /// file.
    case all

    /// Represents a single rule with the specified identifier.
    case single(identifier: String)

    private static let allStringRepresentation = "all"

    /// The spelling of the string for this identifier.
    var stringRepresentation: String {
        switch self {
            case .all: Self.allStringRepresentation
            case let .single(identifier): identifier
        }
    }

    /// Creates a `RuleIdentifier` by its string representation.
    ///
    /// - Parameters:
    ///   - value: The string representation.
    init(_ value: String) {
        self = value == Self.allStringRepresentation ? .all : .single(identifier: value)
    }

    public init(stringLiteral value: String) {
        self = Self(value)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.stringRepresentation < rhs.stringRepresentation
    }
}
