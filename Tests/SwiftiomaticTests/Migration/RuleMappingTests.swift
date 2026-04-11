import Foundation
import Testing

@testable import SwiftiomaticKit

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

  @Test func swiftlintRenamedRule() {
    let result = RuleMapping.swiftlint("empty_count")
    #expect(result == .renamed(old: "empty_count", new: "empty_collection_literal"))
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
    #expect(
      RuleMapping.swiftlint("empty_count").swiftiomaticID == "empty_collection_literal")
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
    #expect(result == .renamed(old: "sortImports", new: "sorted_imports"))
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
