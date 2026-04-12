import SwiftiomaticSyntax

enum ImportSortOrder: String, Sendable, Equatable, AcceptableByOptionElement {
  case alphabetical
  case length
}

enum ImportGrouping: String, Sendable, Equatable, AcceptableByOptionElement {
  /// Only imports on consecutive lines (no blank lines or comments between them) form a group.
  case contiguous
  /// All consecutive import declarations form a group, even if separated by blank lines or comments.
  case all
}

struct SortImportsOptions: RuleOptions {
  @OptionElement(key: "sort_order")
  private(set) var sortOrder: ImportSortOrder = .alphabetical
  @OptionElement(key: "grouping")
  private(set) var grouping: ImportGrouping = .contiguous
  @OptionElement(key: "group_attributed_imports")
  private(set) var groupAttributedImports: Bool = false

  typealias Parent = SortImportsRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    if let value = configuration[$sortOrder.key] {
      try sortOrder.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$grouping.key] {
      try grouping.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$groupAttributedImports.key] {
      try groupAttributedImports.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
