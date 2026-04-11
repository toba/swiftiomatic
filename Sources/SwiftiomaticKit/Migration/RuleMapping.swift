import Foundation

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
  private static let swiftlintRenamed: [String: String] = [
    "empty_count": "empty_collection_literal",
    "syntactic_sugar": "empty_collection_literal",
    "shorthand_operator": "shorthand_argument",
    "statement_position": "opening_brace",
    "large_tuple": "function_parameter_count",
    "unused_capture_list": "unused_closure_parameter",
    "redundant_self_in_closure": "explicit_self",
    "contains_over_first_not_nil": "first_where",
  ]

  /// SwiftLint rules that were removed or superseded
  private static let swiftlintRemoved: [String: String] = [
    "class_delegate_protocol": "Superseded by Swift 6 strict concurrency",
    "unused_setter_value": "Handled by the compiler in Swift 6",
    "weak_computed_property": "Removed — computed properties cannot be weak",
    "inert_defer": "Handled by the compiler warning",
    "nslocalizedstring_key": "Use String Catalogs instead",
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
    "blankLinesAtEndOfScope": "vertical_whitespace_closing_braces",
    "blankLinesAtStartOfScope": "vertical_whitespace_opening_braces",
    "blankLinesBetweenScopes": "blank_lines_between_scopes",
    "braces": "opening_brace",
    "consecutiveBlankLines": "vertical_whitespace",
    "consecutiveSpaces": "consecutive_spaces",
    "duplicateImports": "duplicate_imports",
    "elseOnSameLine": "opening_brace",
    "emptyBraces": "empty_braces",
    "hoistPatternLet": "pattern_matching_keywords",
    "indent": "indentation_width",
    "leadingDelimiters": "leading_delimiters",
    "linebreakAtEndOfFile": "trailing_whitespace",
    "numberFormatting": "number_formatting",
    "redundantBackticks": "redundant_backticks",
    "redundantClosure": "redundant_closure",
    "redundantGet": "redundant_get",
    "redundantInit": "explicit_init",
    "redundantLet": "redundant_discardable_let",
    "redundantNilInit": "implicit_optional_initialization",
    "redundantObjc": "redundant_objc_attribute",
    "redundantParens": "redundant_parens",
    "redundantPattern": "empty_enum_arguments",
    "redundantRawValues": "redundant_raw_values",
    "redundantReturn": "implicit_return",
    "redundantSelf": "explicit_self",
    "redundantType": "redundant_type_annotation",
    "redundantVoidReturnType": "redundant_void_return",
    "semicolons": "trailing_semicolon",
    "sortImports": "sorted_imports",
    "sortDeclarations": "sort_declarations",
    "spaceAroundBraces": "space_around_brackets",
    "spaceAroundBrackets": "space_around_brackets",
    "spaceAroundComments": "space_around_comments",
    "spaceAroundGenerics": "space_around_generics",
    "spaceAroundOperators": "operator_usage_spacing",
    "spaceAroundParens": "space_around_parens",
    "spaceInsideBraces": "space_inside_brackets",
    "spaceInsideBrackets": "space_inside_brackets",
    "spaceInsideComments": "space_around_comments",
    "spaceInsideGenerics": "space_inside_generics",
    "spaceInsideParens": "space_inside_parens",
    "strongifiedSelf": "strongified_self",
    "todos": "todo",
    "trailingClosures": "trailing_closure",
    "trailingCommas": "trailing_comma",
    "trailingSpace": "trailing_whitespace",
    "unusedArguments": "unused_closure_parameter",
    "void": "void_return",
    "wrapArguments": "multiline_arguments",
    "wrapParameters": "multiline_parameters",
    "yodaConditions": "yoda_condition",
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
