import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ImplicitlyUnwrappedOptionalRuleTests {
  // MARK: - Default configuration

  @Test func defaultConfigIsAllExceptIBOutlets() {
    let rule = ImplicitlyUnwrappedOptionalRule()
    #expect(rule.options.mode == .allExceptIBOutlets)
    #expect(rule.options.severity == .warning)
  }

  // MARK: - Non-triggering (default: allExceptIBOutlets)

  @Test func allowsIBOutletPrivateVar() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "@IBOutlet private var label: UILabel!")
  }

  @Test func allowsIBOutletVar() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "@IBOutlet var label: UILabel!")
  }

  @Test func allowsNegationOperator() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "if !boolean {}")
  }

  @Test func allowsOptionalType() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "let int: Int? = 42")
  }

  @Test func allowsIBOutletWithWeakInDefaultMode() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      """
      class MyClass {
          @IBOutlet
          weak var bar: SomeObject!
      }
      """)
  }

  // MARK: - Triggering (default: allExceptIBOutlets)

  @Test func detectsImplicitlyUnwrappedLet() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "let label: 1️⃣UILabel!",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedNamedIBOutlet() async {
    // Variable named IBOutlet (not the attribute) should still trigger
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "let IBOutlet: 1️⃣UILabel!",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedInArray() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "let labels: [1️⃣UILabel!]",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedVar() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "var ints: [1️⃣Int!] = [42, nil, 42]",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedLetWithInit() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "let int: 1️⃣Int! = 42",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedInGeneric() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "let collection: AnyCollection<1️⃣Int!>",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedFuncParam() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "func foo(int: 1️⃣Int!) {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsImplicitlyUnwrappedWeakVar() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      """
      class MyClass {
          weak var bar: 1️⃣SomeObject!
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Mode: all

  @Test func allModeDetectsIBOutlets() async {
    await assertViolates(
      ImplicitlyUnwrappedOptionalRule.self,
      "@IBOutlet private var label: UILabel!",
      configuration: ["mode": "all"])
  }

  @Test func allModeDetectsPlainLet() async {
    await assertViolates(
      ImplicitlyUnwrappedOptionalRule.self,
      "let int: Int!",
      configuration: ["mode": "all"])
  }

  @Test func allModeAllowsNegation() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "if !boolean {}",
      configuration: ["mode": "all"])
  }

  // MARK: - Mode: weak_except_iboutlets

  @Test func weakModeDetectsWeakVar() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "private weak var label: 1️⃣UILabel!",
      findings: [FindingSpec("1️⃣")],
      configuration: ["mode": "weak_except_iboutlets"])
  }

  @Test func weakModeDetectsObjcWeakVar() async {
    await assertLint(
      ImplicitlyUnwrappedOptionalRule.self,
      "weak var label: 1️⃣UILabel!",
      findings: [FindingSpec("1️⃣")],
      configuration: ["mode": "weak_except_iboutlets"])
  }

  @Test func weakModeAllowsIBOutlet() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "@IBOutlet private var label: UILabel!",
      configuration: ["mode": "weak_except_iboutlets"])
  }

  @Test func weakModeAllowsIBOutletWeak() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "@IBOutlet weak var label: UILabel!",
      configuration: ["mode": "weak_except_iboutlets"])
  }

  @Test func weakModeAllowsNonWeakVar() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "var label: UILabel!",
      configuration: ["mode": "weak_except_iboutlets"])
  }

  @Test func weakModeAllowsPlainLet() async {
    await assertNoViolation(
      ImplicitlyUnwrappedOptionalRule.self,
      "let int: Int!",
      configuration: ["mode": "weak_except_iboutlets"])
  }
}
