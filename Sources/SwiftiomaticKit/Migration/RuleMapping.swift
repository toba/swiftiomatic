import Foundation
import SwiftiomaticSyntax

/// Result of mapping a rule ID from SwiftLint or SwiftFormat to Swiftiomatic
public enum MappedRule: Equatable, Sendable {
  /// The rule ID exists in Swiftiomatic with the same identifier
  case exact(String)
  /// The rule was renamed — the old ID maps to a new Swiftiomatic ID
  case renamed(old: String, new: String)
  /// The rule was deliberately removed or superseded
  case removed(reason: String)
  /// No known mapping exists
  case unmapped

  /// The Swiftiomatic rule ID, if one exists
  var swiftiomaticID: String? {
    switch self {
    case .exact(let id): id
    case .renamed(_, let new): new
    case .removed, .unmapped: nil
    }
  }
}

/// Maps rule identifiers from SwiftLint and SwiftFormat to Swiftiomatic equivalents
public enum RuleMapping {
  // MARK: - SwiftLint

  /// SwiftLint rules that were renamed in Swiftiomatic
  ///
  /// Most SwiftLint rules exist in Swiftiomatic with the same identifier and are
  /// resolved by exact match or deprecated alias. Only add entries here when the
  /// SwiftLint ID genuinely maps to a *different* Swiftiomatic ID and is not
  /// already covered by ``Rule.deprecatedAliases``.
  private static let swiftlintRenamed: [String: String] = [
    "contains_over_range_nil_comparison": ContainsOverRangeCheckRule.id,
    "multiple_closures_with_trailing_closure": MultipleTrailingClosuresRule.id,
    "operator_usage_whitespace": OperatorUsageSpacingRule.id,
    "prefer_self_type_over_type_of_self": SelfTypeOverTypeOfSelfRule.id,
    "prefer_zero_over_explicit_init": ZeroOverExplicitInitRule.id,
    "sorted_first_last": MinMaxOverSortedRule.id,
    "unneeded_escaping": RedundantEscapingRule.id,
    "unneeded_parentheses_in_closure_argument": RedundantClosureArgumentParensRule.id,
    "unneeded_throws_rethrows": RedundantThrowsRule.id,
  ]

  /// SwiftLint rules that were removed or superseded
  private static let swiftlintRemoved: [String: String] = [
    "class_delegate_protocol": "Superseded by Swift 6 strict concurrency",
    "unused_setter_value": "Handled by the compiler in Swift 6",
    "weak_computed_property": "Removed — computed properties cannot be weak",
    "inert_defer": "Handled by the compiler warning",
    "nslocalizedstring_key": "Use String Catalogs instead",
    "unused_capture_list": "Removed — handled by the compiler",
  ]

  /// Map a SwiftLint rule identifier to a Swiftiomatic rule
  ///
  /// - Parameters:
  ///   - id: The SwiftLint rule identifier (snake_case).
  /// - Returns: The mapping result.
  public static func swiftlint(_ id: String) -> MappedRule {
    // Check renamed first
    if let newID = swiftlintRenamed[id] {
      return .renamed(old: id, new: newID)
    }
    // Check removed
    if let reason = swiftlintRemoved[id] {
      return .removed(reason: reason)
    }
    // Check if the ID exists directly in Swiftiomatic
    if swiftiomaticRuleIDs.contains(id) {
      return .exact(id)
    }
    // Also check deprecated aliases
    if let resolved = resolveAlias(id) {
      return .renamed(old: id, new: resolved)
    }
    return .unmapped
  }

  // MARK: - SwiftFormat

  /// SwiftFormat camelCase rule names → Swiftiomatic snake_case equivalents
  private static let swiftformatMapping: [String: String] = [
    "blankLinesAtEndOfScope": VerticalWhitespaceClosingBracesRule.id,
    "blankLinesAtStartOfScope": VerticalWhitespaceOpeningBracesRule.id,
    "blankLinesBetweenScopes": BlankLinesBetweenScopesRule.id,
    "braces": OpeningBraceRule.id,
    "consecutiveBlankLines": VerticalWhitespaceRule.id,
    "consecutiveSpaces": ConsecutiveSpacesRule.id,
    "duplicateImports": DuplicateImportsRule.id,
    "elseOnSameLine": OpeningBraceRule.id,
    "emptyBraces": EmptyBracesRule.id,
    "hoistPatternLet": PatternMatchingKeywordsRule.id,
    "indent": IndentationWidthRule.id,
    "isEmpty": EmptyCountRule.id,
    "leadingDelimiters": LeadingDelimitersRule.id,
    "linebreakAtEndOfFile": TrailingWhitespaceRule.id,
    "numberFormatting": NumberSeparatorRule.id,
    "privateStateVariables": PrivateSwiftUIStatePropertyRule.id,
    "redundantBackticks": RedundantBackticksRule.id,
    "redundantClosure": RedundantClosureRule.id,
    "redundantGet": RedundantGetRule.id,
    "redundantInit": ExplicitInitRule.id,
    "redundantLet": RedundantDiscardableLetRule.id,
    "redundantNilInit": ImplicitOptionalInitializationRule.id,
    "redundantObjc": RedundantObjcAttributeRule.id,
    "redundantParens": RedundantParensRule.id,
    "redundantPattern": EmptyEnumArgumentsRule.id,
    "redundantRawValues": RedundantStringEnumValueRule.id,
    "redundantReturn": ImplicitReturnRule.id,
    "redundantSelf": ExplicitSelfRule.id,
    "redundantType": RedundantTypeAnnotationRule.id,
    "redundantVoidReturnType": RedundantVoidReturnRule.id,
    "semicolons": TrailingSemicolonRule.id,
    "sortDeclarations": SortDeclarationsRule.id,
    "sortImports": SortImportsRule.id,
    "spaceAroundBraces": SpaceAroundBracketsRule.id,
    "spaceAroundBrackets": SpaceAroundBracketsRule.id,
    "spaceAroundComments": SpaceAroundCommentsRule.id,
    "spaceAroundGenerics": SpaceAroundGenericsRule.id,
    "spaceAroundOperators": OperatorUsageSpacingRule.id,
    "spaceAroundParens": SpaceAroundParensRule.id,
    "spaceInsideBraces": SpaceInsideBracketsRule.id,
    "spaceInsideBrackets": SpaceInsideBracketsRule.id,
    "spaceInsideComments": SpaceAroundCommentsRule.id,
    "spaceInsideGenerics": SpaceInsideGenericsRule.id,
    "spaceInsideParens": SpaceInsideParensRule.id,
    "strongifiedSelf": StrongifiedSelfRule.id,
    "todos": TodoRule.id,
    "trailingClosures": TrailingClosureRule.id,
    "trailingCommas": TrailingCommaRule.id,
    "trailingSpace": TrailingWhitespaceRule.id,
    "unusedArguments": UnusedClosureParameterRule.id,
    "void": VoidReturnRule.id,
    "wrapArguments": MultilineArgumentsRule.id,
    "wrapParameters": MultilineParametersRule.id,
    "yodaConditions": YodaConditionRule.id,
  ]

  /// SwiftFormat rules that have no Swiftiomatic equivalent
  private static let swiftformatRemoved: [String: String] = [
    "andOperator": "Use sm:disable and_operator if needed",
    "anyObjectProtocol": "Handled by the compiler in Swift 6",
    "assertionFailures": "Use sm:disable assertion_failures if needed",
    "markTypes": "Use sm:disable mark_types if needed",
    "modifierOrder": "Use sm:disable modifier_order if needed",
  ]

  /// Map a SwiftFormat rule name to a Swiftiomatic rule
  ///
  /// - Parameters:
  ///   - name: The SwiftFormat rule name (camelCase).
  /// - Returns: The mapping result.
  public static func swiftformat(_ name: String) -> MappedRule {
    if let mapped = swiftformatMapping[name] {
      return .renamed(old: name, new: mapped)
    }
    if let reason = swiftformatRemoved[name] {
      return .removed(reason: reason)
    }
    // Try converting camelCase to snake_case and checking directly
    let snakeCase = name.camelCaseToSnakeCase()
    if swiftiomaticRuleIDs.contains(snakeCase) {
      return .renamed(old: name, new: snakeCase)
    }
    return .unmapped
  }

  // MARK: - Swiftiomatic Rule IDs (resolved at first use)

  /// All valid Swiftiomatic rule IDs, populated from the registry
  private static let swiftiomaticRuleIDs: Set<String> = {
    RuleRegistry.registerAllRulesOnce()
    return Set(RuleRegistry.shared.list.rules.keys)
  }()

  /// All deprecated aliases → current ID
  private static let aliasMap: [String: String] = {
    RuleRegistry.registerAllRulesOnce()
    var map: [String: String] = [:]
    for (id, ruleType) in RuleRegistry.shared.list.rules {
      for alias in ruleType.deprecatedAliases {
        map[alias] = id
      }
    }
    return map
  }()

  /// Try to resolve a deprecated alias to its current rule ID
  private static func resolveAlias(_ id: String) -> String? {
    aliasMap[id]
  }
}

// MARK: - String Helpers

extension String {
  /// Convert a camelCase string to snake_case
  func camelCaseToSnakeCase() -> String {
    var result = ""
    for (i, char) in enumerated() {
      if char.isUppercase {
        if i > 0 { result += "_" }
        result += char.lowercased()
      } else {
        result += String(char)
      }
    }
    return result
  }
}
