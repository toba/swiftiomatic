import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct UnusedOptionalBindingRuleTests {
  // MARK: - Non-triggering

  @Test func namedBindingDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if let bar = Foo.optionalValue {}"
    )
  }

  @Test func tupleBindingWithNameDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if let (_, second) = getOptionalTuple() {}"
    )
  }

  @Test func mixedTupleBindingDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"
    )
  }

  @Test func letUnderscoreInBodyDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if foo() { let _ = bar() }"
    )
  }

  @Test func assignmentInBodyDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if foo() { _ = bar() }"
    )
  }

  @Test func caseSomeDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if case .some(_) = self {}"
    )
  }

  @Test func closureInFindDoesNotTrigger() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "if let point = state.find({ _ in true }) {}"
    )
  }

  // MARK: - Triggering (default: ignore_optional_try = false)

  @Test func letUnderscoreTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "if let 1️⃣_ = Foo.optionalValue {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func secondBindingLetUnderscoreTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "if let a = Foo.optionalValue, let 1️⃣_ = Foo.optionalValue2 {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func guardLetUnderscoreTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "guard let a = Foo.optionalValue, let 1️⃣_ = Foo.optionalValue2 {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func letUnderscoreAfterTupleBindingTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "if let (first, second) = getOptionalTuple(), let 1️⃣_ = Foo.optionalValue {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func letUnderscoreAfterPartialTupleBindingTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "if let (first, _) = getOptionalTuple(), let 1️⃣_ = Foo.optionalValue {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func letUnderscoreAfterWildcardTupleBindingTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "if let (_, second) = getOptionalTuple(), let 1️⃣_ = Foo.optionalValue {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func allWildcardTupleBindingTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "if let 1️⃣(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func letUnderscoreInFunctionTriggers() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "func foo() { if let 1️⃣_ = bar {} }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func optionalTryLetUnderscoreTriggersByDefault() async {
    await assertLint(
      UnusedOptionalBindingRule.self,
      "guard let 1️⃣_ = try? alwaysThrows() else { return }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - ignore_optional_try = true

  @Test func optionalTryLetUnderscoreDoesNotTriggerWhenIgnored() async {
    await assertNoViolation(
      UnusedOptionalBindingRule.self,
      "guard let _ = try? alwaysThrows() else { return }",
      configuration: ["ignore_optional_try": true]
    )
  }
}
