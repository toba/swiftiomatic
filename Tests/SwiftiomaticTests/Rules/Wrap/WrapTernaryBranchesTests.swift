@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapTernaryBranchesTests: RuleTesting {

  /// Bug repro: `wrapTernaryBranches` emits a finding for a ternary that is already wrapped (both
  /// `?` and `:` on their own lines), when running with multiple rules enabled (as CLI does).
  /// Format correctly leaves the source unchanged, but lint produces a spurious warning.
  @Test func alreadyWrappedTernaryEmitsNoFindingWithMultipleRulesEnabled() {
    var config = Configuration.forTesting
    // Enable WrapTernaryBranches plus a couple of other rules that may modify trivia near the operator.
    config.disableAllRules()
    config.enableRule(named: "wrapTernaryBranches")
    config.enableRule(named: "breakBeforeLeadingDot")
    config.enableRule(named: "useIfElseNotSwitchOnBool")
    config.enableRule(named: "respectExistingLineBreaks")
    assertFormatting(
      WrapTernaryBranches.self,
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

  /// Sanity: same input with only WrapTernaryBranches enabled does not warn (already passes today).
  @Test func alreadyWrappedTernaryEmitsNoFinding_singleRule() {
    assertFormatting(
      WrapTernaryBranches.self,
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
      WrapTernaryBranches.self,
      input: """
        let s = b ? "true" : "false"
        """,
      expected: """
        let s = b ? "true" : "false"
        """,
      findings: [])
  }

  /// Bug repro (issue 3aq-p4v): a ternary inside a single-line string interpolation must
  /// not be wrapped — inserting newlines inside `\\(...)` of a single-line literal produces
  /// invalid Swift.
  @Test func ternaryInsideSingleLineStringInterpolationNotWrapped() {
    assertFormatting(
      WrapTernaryBranches.self,
      input: #"""
        let s = "\(result.summary.linkerErrors) linker error\(result.summary.linkerErrors == 1 ? "" : "s")"
        """#,
      expected: #"""
        let s = "\(result.summary.linkerErrors) linker error\(result.summary.linkerErrors == 1 ? "" : "s")"
        """#,
      findings: [])
  }

  /// Bug repro (issue 83k-hv9): a ternary whose else-branch is consumed by a lower-precedence
  /// operator (e.g. `isEmpty ? "" : "?" + map { ... }.joined(...)`) parses as
  /// `isEmpty ? "" : ("?" + map { ... }.joined(...))`. The else branch is a multi-line chain.
  /// The ternary itself (`isEmpty ? "" : "?"` worth of source on the line carrying `?` and `:`)
  /// fits comfortably; the rule must not force it to wrap just because a downstream operand chain
  /// pushed the collapsed-to-one-line description over the print width.
  @Test func ternaryWithMultiLineRHSOperandNotWrapped() {
    assertFormatting(
      WrapTernaryBranches.self,
      input: """
        var urlEncoded: String {
            isEmpty ? "" : "?"
                + map { key, value in "\\(key)=\\(value.description.urlEncoded)" }
                .joined(separator: "&")
        }
        """,
      expected: """
        var urlEncoded: String {
            isEmpty ? "" : "?"
                + map { key, value in "\\(key)=\\(value.description.urlEncoded)" }
                .joined(separator: "&")
        }
        """,
      findings: [])
  }

}
