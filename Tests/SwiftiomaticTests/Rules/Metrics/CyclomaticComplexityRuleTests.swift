import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct CyclomaticComplexityRuleTests {
  // MARK: - Helpers

  /// Build a function with the given number of `if` branches to exceed complexity thresholds.
  private static func functionWithIfBranches(count: Int, name: String = "f") -> String {
    var lines = ["func \(name)() {"]
    for i in 0..<count {
      lines.append("    if condition\(i) { print(\(i)) }")
    }
    lines.append("}")
    return lines.joined(separator: "\n")
  }

  /// Build a function with a switch statement having the given number of cases.
  private static func functionWithSwitchCases(
    count: Int, keyword: String = "func switcheroo()"
  ) -> String {
    var lines = ["\(keyword) {", "    switch foo {"]
    for i in 0..<count {
      lines.append("    case \(i): print(\"\(i)\")")
    }
    lines.append("    }")
    lines.append("}")
    return lines.joined(separator: "\n")
  }

  // MARK: - Non-triggering (default config: warning at 10)

  @Test func simpleFunctionDoesNotTrigger() async {
    await assertNoViolation(
      CyclomaticComplexityRule.self,
      """
      func f1() {
          if true {
              for _ in 1..5 { }
          }
          if false { }
      }
      """)
  }

  @Test func switchWithFallthroughDoesNotTrigger() async {
    // 10 cases but fallthrough reduces effective complexity
    await assertNoViolation(
      CyclomaticComplexityRule.self,
      """
      func f(code: Int) -> Int {
          switch code {
          case 0: fallthrough
          case 1: return 1
          case 2: return 1
          case 3: return 1
          case 4: return 1
          case 5: return 1
          case 6: return 1
          case 7: return 1
          case 8: return 1
          default: return 1
          }
      }
      """)
  }

  @Test func nestedFunctionsCountSeparately() async {
    // Each function's complexity is counted independently
    await assertNoViolation(
      CyclomaticComplexityRule.self,
      """
      func f1() {
          if true {}; if true {}; if true {}; if true {}; if true {}; if true {}
          func f2() {
              if true {}; if true {}; if true {}; if true {}; if true {}
          }
      }
      """)
  }

  // MARK: - Triggering (default config: warning at 10)

  @Test func highComplexityFunctionTriggers() async {
    // 11 branches exceeds the warning threshold of 10
    await assertLint(
      CyclomaticComplexityRule.self,
      """
      1️⃣func f1() {
          if true {
              if true {
                  if false {}
              }
          }
          if false {}
          let i = 0
          switch i {
              case 1: break
              case 2: break
              case 3: break
              case 4: break
              default: break
          }
          for _ in 1...5 {
              guard true else {
                  return
              }
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Configuration: ignores_case_statements

  @Test func switchCasesIgnoredWhenConfigured() async {
    // 31 switch cases would normally exceed threshold, but are ignored
    let source = Self.functionWithSwitchCases(count: 31)
    await assertNoViolation(
      CyclomaticComplexityRule.self,
      source,
      configuration: ["ignores_case_statements": true])
  }

  @Test func ifBranchesStillCountWhenCasesIgnored() async {
    // 11 if-branches exceed threshold even when case statements are ignored
    let source = Self.functionWithIfBranches(count: 11)
    await assertViolates(
      CyclomaticComplexityRule.self,
      source,
      configuration: ["ignores_case_statements": true])
  }

  @Test func switchCasesCountWhenNotIgnored() async {
    // 31 switch cases exceed threshold when case statements are NOT ignored
    let source = Self.functionWithSwitchCases(count: 31)
    await assertViolates(
      CyclomaticComplexityRule.self,
      source,
      configuration: ["ignores_case_statements": false])
  }

  @Test func switchCasesInInitCountWhenNotIgnored() async {
    // Switch cases in init also count
    let source = Self.functionWithSwitchCases(count: 31, keyword: "init()")
    await assertViolates(
      CyclomaticComplexityRule.self,
      source,
      configuration: ["ignores_case_statements": false])
  }
}
