import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct RuleMappingTests {
  // MARK: - SwiftLint Mapping

  @Test func swiftlintExactMatch() {
    let result = RuleMapping.swiftlint("force_cast")
    #expect(result == .exact("force_cast"))
  }

  @Test func swiftlintMultipleExactMatches() {
    // Verify several common SwiftLint rules map directly
    for ruleID in [
      "trailing_whitespace", "line_length", "force_try",
      "identifier_name", "nesting", "vertical_whitespace",
    ] {
      let result = RuleMapping.swiftlint(ruleID)
      #expect(result == .exact(ruleID), "Expected \(ruleID) to map as .exact")
    }
  }

  @Test func swiftlintExactMatchFormerlyMismapped() {
    // These rules exist in Swiftiomatic with the same ID as SwiftLint
    for ruleID in [
      "empty_count", "syntactic_sugar", "shorthand_operator",
      "statement_position", "large_tuple", "contains_over_first_not_nil",
    ] {
      let result = RuleMapping.swiftlint(ruleID)
      #expect(result == .exact(ruleID), "Expected \(ruleID) to map as .exact")
    }
  }

  @Test func swiftlintDeprecatedAliasResolved() {
    // redundant_self_in_closure is a deprecated alias for redundant_self
    let result = RuleMapping.swiftlint("redundant_self_in_closure")
    #expect(result == .renamed(old: "redundant_self_in_closure", new: "redundant_self"))
  }

  @Test func swiftlintRemovedUnusedCaptureList() {
    let result = RuleMapping.swiftlint("unused_capture_list")
    if case .removed(let reason) = result {
      #expect(reason.contains("compiler"))
    } else {
      Issue.record("Expected .removed, got \(result)")
    }
  }

  @Test func swiftlintRemovedRule() {
    let result = RuleMapping.swiftlint("weak_computed_property")
    if case .removed(let reason) = result {
      #expect(reason.contains("computed properties"))
    } else {
      Issue.record("Expected .removed, got \(result)")
    }
  }

  @Test func swiftlintUnmappedRule() {
    let result = RuleMapping.swiftlint("completely_fake_rule_xyz")
    #expect(result == .unmapped)
  }

  @Test func swiftlintMappedRuleHasID() {
    #expect(RuleMapping.swiftlint("force_cast").swiftiomaticID == "force_cast")
    #expect(RuleMapping.swiftlint("empty_count").swiftiomaticID == "empty_count")
    #expect(RuleMapping.swiftlint("completely_fake_rule_xyz").swiftiomaticID == nil)
  }

  // MARK: - SwiftFormat Mapping

  @Test func swiftformatKnownMapping() {
    let result = RuleMapping.swiftformat("redundantSelf")
    #expect(result == .renamed(old: "redundantSelf", new: "explicit_self"))
  }

  @Test func swiftformatTrailingCommas() {
    let result = RuleMapping.swiftformat("trailingCommas")
    #expect(result == .renamed(old: "trailingCommas", new: "trailing_comma"))
  }

  @Test func swiftformatSortImports() {
    let result = RuleMapping.swiftformat("sortImports")
    #expect(result == .renamed(old: "sortImports", new: "sort_imports"))
  }

  @Test func swiftformatLinebreakAtEndOfFileMapsToTrailingNewline() {
    let result = RuleMapping.swiftformat("linebreakAtEndOfFile")
    #expect(result == .renamed(old: "linebreakAtEndOfFile", new: "trailing_newline"))
  }

  @Test func swiftformatIndentNotMappedToIndentationWidth() {
    // SwiftFormat's indent is a full indentation engine; our IndentationWidthRule
    // only checks width — different semantics, so .removed not .renamed
    let result = RuleMapping.swiftformat("indent")
    if case .removed = result {} else {
      Issue.record("Expected .removed for indent, got \(result)")
    }
  }

  @Test func swiftformatBraceRulesNotMappedToBrackets() {
    // spaceAroundBraces/spaceInsideBraces handle { } — NOT [ ]
    // They must not map to our bracket rules
    let around = RuleMapping.swiftformat("spaceAroundBraces")
    if case .removed = around {} else {
      Issue.record("Expected .removed for spaceAroundBraces, got \(around)")
    }
    let inside = RuleMapping.swiftformat("spaceInsideBraces")
    if case .removed = inside {} else {
      Issue.record("Expected .removed for spaceInsideBraces, got \(inside)")
    }
  }

  @Test func swiftformatUnmappedRule() {
    let result = RuleMapping.swiftformat("completelyFakeRule")
    #expect(result == .unmapped)
  }

  @Test func swiftformatCamelCaseAutoConversion() {
    // Rules whose camelCase → snake_case matches a Swiftiomatic rule directly
    let result = RuleMapping.swiftformat("consecutiveSpaces")
    #expect(result.swiftiomaticID == "consecutive_spaces")
  }

  // MARK: - MappedRule Properties

  @Test func mappedRuleSwiftiomaticID() {
    #expect(MappedRule.exact("foo").swiftiomaticID == "foo")
    #expect(MappedRule.renamed(old: "bar", new: "baz").swiftiomaticID == "baz")
    #expect(MappedRule.removed(reason: "gone").swiftiomaticID == nil)
    #expect(MappedRule.unmapped.swiftiomaticID == nil)
  }
}
