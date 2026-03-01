/// A comparable `major.minor.patch` version number.
public protocol VersionComparable: Comparable {
    /// The version string.
    var rawValue: String { get }
}

extension VersionComparable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if let lhsComparators = lhs.comparators, let rhsComparators = rhs.comparators {
            return lhsComparators == rhsComparators
        }
        return lhs.rawValue == rhs.rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if let lhsComparators = lhs.comparators, let rhsComparators = rhs.comparators {
            return lhsComparators.lexicographicallyPrecedes(rhsComparators)
        }
        return lhs.rawValue < rhs.rawValue
    }

    private var comparators: [Int]? {
        let components = rawValue.split(separator: ".").compactMap { Int($0) }
        guard let major = components.first else {
            return nil
        }
        let minor = components.dropFirst(1).first ?? 0
        let patch = components.dropFirst(2).first ?? 0
        return [major, minor, patch]
    }
}
