@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapTernaryTests: RuleTesting {

  /// Bug repro: `wrapTernary` emits a finding for a ternary that is already wrapped (both `?`
  /// and `:` on their own lines), when running with multiple rules enabled (as CLI does).
  /// Format correctly leaves the source unchanged, but lint produces a spurious warning.
  @Test func alreadyWrappedTernaryEmitsNoFindingWithMultipleRulesEnabled() {
    var config = Configuration.forTesting
    // Enable WrapTernary plus a couple of other rules that may modify trivia near the operator.
    config.disableAllRules()
    config.enableRule(named: "wrapTernary")
    config.enableRule(named: "leadingDotOperators")
    config.enableRule(named: "preferIfElseChain")
    config.enableRule(named: "respectExistingLineBreaks")
    assertFormatting(
      WrapTernary.self,
      input: """
        let x = forcedBreakingClosures.remove(node.id) != nil || node.statements.count > 1
            ? .soft
            : .elective
        """,
      expected: """
        let x = forcedBreakingClosures.remove(node.id) != nil || node.statements.count > 1
            ? .soft
            : .elective
        """,
      findings: [],
      configuration: config)
  }

  /// Sanity: same input with only WrapTernary enabled does not warn (already passes today).
  @Test func alreadyWrappedTernaryEmitsNoFinding_singleRule() {
    assertFormatting(
      WrapTernary.self,
      input: """
        let x = forcedBreakingClosures.remove(node.id) != nil || node.statements.count > 1
            ? .soft
            : .elective
        """,
      expected: """
        let x = forcedBreakingClosures.remove(node.id) != nil || node.statements.count > 1
            ? .soft
            : .elective
        """,
      findings: [])
  }

  /// Sanity: short ternaries that fit on one line are not wrapped and emit no finding.
  @Test func shortTernaryNotWrapped() {
    assertFormatting(
      WrapTernary.self,
      input: """
        let s = b ? "true" : "false"
        """,
      expected: """
        let s = b ? "true" : "false"
        """,
      findings: [])
  }

}
