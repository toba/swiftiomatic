/// A hierarchical category for rule grouping, derived from the rule directory structure.
///
/// Categories enable filtering rules by topic (e.g., `--category redundancy`)
/// and category-level enable/disable in `.swiftiomatic.yaml`.
public struct RuleCategory: Sendable, Codable, Hashable, CustomStringConvertible {
  /// The top-level category (e.g., "redundancy", "performance").
  public let name: String

  /// The subcategory within the top-level category (e.g., "types", "collections").
  public let subcategory: String?

  public var description: String {
    if let subcategory {
      "\(name)/\(subcategory)"
    } else {
      name
    }
  }

  public init(name: String, subcategory: String? = nil) {
    self.name = name
    self.subcategory = subcategory
  }

  /// The default category for rules that haven't been categorized.
  public static let uncategorized = RuleCategory(name: "uncategorized")
}
