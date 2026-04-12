import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct FunctionParameterCountRuleTests {
  // MARK: - Helpers

  private static func params(_ count: Int, defaultValue: Bool = false) -> String {
    let suffix = defaultValue ? " = 0" : ""
    return (0..<count).map { "p\($0): Int\(suffix)" }.joined(separator: ", ")
  }

  // MARK: - Non-triggering (default config: warning at 5, ignores_default_parameters: true)

  @Test func fewParametersDoesNotTrigger() async {
    await assertNoViolation(
      FunctionParameterCountRule.self,
      "func f2(p1: Int, p2: Int) { }")
  }

  @Test func fiveParametersDoesNotTrigger() async {
    // Exactly at the threshold (5) -- not over
    await assertNoViolation(
      FunctionParameterCountRule.self,
      "func f(a: Int, b: Int, c: Int, d: Int, e: Int) {}")
  }

  @Test func defaultParametersIgnoredByDefault() async {
    // 5 regular + 1 default = 6 total, but default is ignored so effective count is 5
    await assertNoViolation(
      FunctionParameterCountRule.self,
      "func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}")
  }

  @Test func initExcluded() async {
    // init is not checked by this rule (6 params)
    await assertNoViolation(
      FunctionParameterCountRule.self,
      "init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}")
  }

  @Test func overrideExcluded() async {
    await assertNoViolation(
      FunctionParameterCountRule.self,
      "override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}")
  }

  @Test func closureInBodyDoesNotAffectCount() async {
    await assertNoViolation(
      FunctionParameterCountRule.self,
      """
      func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
          let s = a.flatMap { $0 as? [String: Int] } ?? []}}
      """)
  }

  // MARK: - Triggering (default config: warning at 5)

  @Test func sixParametersTriggers() async {
    await assertLint(
      FunctionParameterCountRule.self,
      "1️⃣func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func functionNamedLikeInitStillTriggers() async {
    await assertLint(
      FunctionParameterCountRule.self,
      "1️⃣func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func privateWithDefaultParamsTriggers() async {
    // 7 total params, 1 default ignored = 6 effective, still over 5
    await assertLint(
      FunctionParameterCountRule.self,
      "private 1️⃣func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func funcInStructTriggersButInitDoesNot() async {
    await assertLint(
      FunctionParameterCountRule.self,
      """
      struct Foo {
          init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
          1️⃣func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
      """,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Configuration: ignores_default_parameters = false

  @Test func fourParamsDoesNotTriggerIgnoringDefaults() async {
    // 4 regular params = under threshold
    await assertNoViolation(
      FunctionParameterCountRule.self,
      "func f(\(Self.params(4))) {}",
      configuration: ["ignores_default_parameters": false])
  }

  @Test func defaultParametersCountWhenNotIgnored() async {
    // 3 regular + 3 default = 6 total, all counted, exceeds threshold of 5
    let regularParams = Self.params(3)
    let defaultParams = Self.params(3, defaultValue: true)
    await assertViolates(
      FunctionParameterCountRule.self,
      "func f(\(regularParams), \(defaultParams)) {}",
      configuration: ["ignores_default_parameters": false])
  }
}
