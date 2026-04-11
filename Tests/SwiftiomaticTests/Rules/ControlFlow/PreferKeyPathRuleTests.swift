import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct PreferKeyPathRuleTests {
  private static let extendedMode: [String: any Sendable] = [
    "restrict_to_standard_functions": false
  ]
  private static let ignoreIdentity: [String: any Sendable] = [
    "ignore_identity_closures": true
  ]
  private static let extendedModeAndIgnoreIdentity: [String: any Sendable] = [
    "restrict_to_standard_functions": false,
    "ignore_identity_closures": true,
  ]

  // MARK: - Non-triggering (default config)

  @Test func emptyClosureDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f {}")
  }

  @Test func identityClosureDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f { $0 }")
  }

  @Test func singlePropertyAccessDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f { $0.a }")
  }

  @Test func closureCallDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "let f = { $0.a }(b)")
  }

  @Test func multiArgFilterDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f.map(1) { $0.a }")
  }

  @Test func closureAsNonTrailingArgDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f.filter({ $0.a }, x)")
  }

  @Test func predicateMacroDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "#Predicate { $0.a }")
  }

  @Test func nilCoalescingClosureDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self,
      "let transform: (Int) -> Int = nil ?? { $0.a }"
    )
  }

  // MARK: - Non-triggering (extended mode)

  @Test func emptyClosureInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f {}", configuration: Self.extendedMode)
  }

  @Test func functionCallClosureInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f() { g() }",
      configuration: Self.extendedMode
    )
  }

  @Test func nonParameterAccessInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f { a.b.c }",
      configuration: Self.extendedMode
    )
  }

  @Test func multiParamClosureInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f { a, b in a.b }",
      configuration: Self.extendedMode
    )
  }

  @Test func tupleParamClosureInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f { (a, b) in a.b }",
      configuration: Self.extendedMode
    )
  }

  @Test func multiTrailingClosuresInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f { $0.a } g: { $0.b }",
      configuration: Self.extendedMode
    )
  }

  @Test func reduceClosureInExtendedModeDoesNotTrigger() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "[1, 2, 3].reduce(1) { $0 + $1 }",
      configuration: Self.extendedMode
    )
  }

  // MARK: - Non-triggering (identity closures ignored)

  @Test func identityClosureIgnoredInExtendedMode() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f { $0 }",
      configuration: Self.extendedModeAndIgnoreIdentity
    )
  }

  @Test func identityMapClosureIgnored() async {
    await assertNoViolation(
      PreferKeyPathRule.self, "f.map { $0 }",
      configuration: Self.ignoreIdentity
    )
  }

  // MARK: - Triggering (default config)

  @Test func mapPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.map 1️⃣{ $0.a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func filterPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.filter 1️⃣{ $0.a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func firstPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.first 1️⃣{ $0.a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func containsPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.contains 1️⃣{ $0.a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func containsWherePropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.contains(where: 1️⃣{ $0.a })",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func namedParamPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.map 1️⃣{ a in a.b.c }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func typedParamPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.allSatisfy 1️⃣{ (a: A) in a.b }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func secondNameParamPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.first 1️⃣{ (a b: A) in b.c }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func tupleAccessPropertyTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.contains 1️⃣{ $0.0.a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func deepPropertyChainTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.compactMap 1️⃣{ $0.a.b.c.d }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func flatMapPropertyAccessTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f.flatMap 1️⃣{ $0.a.b }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func assignmentClosureTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "transform = 1️⃣{ $0.a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - Triggering (extended mode)

  @Test func freeClosureInExtendedModeTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f(1️⃣{ $0.a })",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  @Test func labeledClosureInExtendedModeTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f(a: 1️⃣{ $0.b })",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  @Test func namedParamClosureInExtendedModeTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "f(a: 1️⃣{ a in a.b }, x)",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  @Test func typeAnnotatedClosureInExtendedModeTriggersViolation() async {
    await assertLint(
      PreferKeyPathRule.self, "let f: (Int) -> Int = 1️⃣{ $0.bigEndian }",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  // MARK: - Corrections (default config)

  @Test func correctsMapPropertyAccess() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.map 1️⃣{ $0.a }",
      expected: "f.map(\\.a)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsMapPropertyAccessWithComments() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: """
        // begin
        f.map 1️⃣{ $0.a } // end
        """,
      expected: """
        // begin
        f.map(\\.a) // end
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsMapParenthesizedClosure() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.map(1️⃣{ $0.a })",
      expected: "f.map(\\.a)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsPartitionWithLabeledArg() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.partition 1️⃣{ $0.a.b }",
      expected: "f.partition(by: \\.a.b)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsContainsWithWhereLabel() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.contains 1️⃣{ $0.a.b }",
      expected: "f.contains(where: \\.a.b)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsFirstWithWhereLabel() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.first 1️⃣{ element in element.a }",
      expected: "f.first(where: \\.a)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsDropWithWhileLabel() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.drop 1️⃣{ element in element.a }",
      expected: "f.drop(while: \\.a)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsCompactMapDeepChain() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.compactMap 1️⃣{ $0.a.b.c.d }",
      expected: "f.compactMap(\\.a.b.c.d)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func closureCallNotCorrected() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "let f = { $0.a }(b)",
      expected: "let f = { $0.a }(b)"
    )
  }

  // MARK: - Corrections (extended mode)

  @Test func correctsLabeledArgInExtendedMode() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f(a: 1️⃣{ $0.a })",
      expected: "f(a: \\.a)",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  @Test func correctsPositionalArgInExtendedMode() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f(1️⃣{ $0.a })",
      expected: "f(\\.a)",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  @Test func correctsLetAssignmentWithCommentsInExtendedMode() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "let f = /* begin */ 1️⃣{ $0.a } // end",
      expected: "let f = /* begin */ \\.a // end",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  @Test func correctsTypeAnnotatedClosureInExtendedMode() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "let f: (Int) -> Int = 1️⃣{ $0.bigEndian }",
      expected: "let f: (Int) -> Int = \\.bigEndian",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }

  // MARK: - Identity closures (Swift 6+)

  @Test func identityClosureNotCorrectedWhenIgnored() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f { $0 }",
      expected: "f { $0 }",
      configuration: Self.extendedModeAndIgnoreIdentity
    )
  }

  @Test func identityMapClosureNotCorrectedWhenIgnored() async {
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.map { $0 }",
      expected: "f.map { $0 }",
      configuration: Self.ignoreIdentity
    )
  }

  @Test func compactMapIdentityTriggersViolation() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertLint(
      PreferKeyPathRule.self, "f.compactMap 1️⃣{ $0 }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func mapIdentityTriggersViolation() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertLint(
      PreferKeyPathRule.self, "f.map 1️⃣{ a in a }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func nonStandardIdentityDoesNotTriggerWithExtendedAndIgnore() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertNoViolation(
      PreferKeyPathRule.self, "f { $0 }",
      configuration: Self.extendedModeAndIgnoreIdentity
    )
  }

  @Test func standardIdentityDoesNotTriggerWithIgnore() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertNoViolation(
      PreferKeyPathRule.self, "f.map { $0 }",
      configuration: Self.ignoreIdentity
    )
  }

  @Test func nonStandardSecondParamDoesNotTrigger() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertNoViolation(
      PreferKeyPathRule.self, "f.g { $1 }",
      configuration: Self.extendedMode
    )
  }

  @Test func nonStandardNonMemberClosureDoesNotTrigger() async {
    await assertNoViolation(PreferKeyPathRule.self, "f.filter { a in b }")
  }

  @Test func correctsMapIdentityToSelf() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.map 1️⃣{ $0 }",
      expected: "f.map(\\.self)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsNonStandardIdentityInExtendedMode() async {
    guard SwiftVersion.current >= .v6 else { return }
    await assertFormatting(
      PreferKeyPathRule.self,
      input: "f.g 1️⃣{ $0 }",
      expected: "f.g(\\.self)",
      findings: [FindingSpec("1️⃣")],
      configuration: Self.extendedMode
    )
  }
}
