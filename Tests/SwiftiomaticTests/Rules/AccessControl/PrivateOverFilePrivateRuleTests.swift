import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct PrivateOverFilePrivateRuleTests {
  // MARK: - Non-triggering (default: validate_extensions = false)

  @Test func plainExtensionDoesNotTrigger() async {
    await assertNoViolation(PrivateOverFilePrivateRule.self, "extension String {}")
  }

  @Test func privateExtensionDoesNotTrigger() async {
    await assertNoViolation(PrivateOverFilePrivateRule.self, "private extension String {}")
  }

  @Test func publicProtocolDoesNotTrigger() async {
    await assertNoViolation(PrivateOverFilePrivateRule.self, "public protocol P {}")
  }

  @Test func openExtensionDoesNotTrigger() async {
    await assertNoViolation(PrivateOverFilePrivateRule.self, "open extension \n String {}")
  }

  @Test func internalExtensionDoesNotTrigger() async {
    await assertNoViolation(PrivateOverFilePrivateRule.self, "internal extension String {}")
  }

  @Test func packageTypealiasDoesNotTrigger() async {
    await assertNoViolation(PrivateOverFilePrivateRule.self, "package typealias P = Int")
  }

  @Test func fileprivateInsideExtensionDoesNotTrigger() async {
    await assertNoViolation(
      PrivateOverFilePrivateRule.self,
      """
      extension String {
        fileprivate func Something(){}
      }
      """
    )
  }

  @Test func fileprivateInsideClassDoesNotTrigger() async {
    await assertNoViolation(
      PrivateOverFilePrivateRule.self,
      """
      class MyClass {
        fileprivate let myInt = 4
      }
      """
    )
  }

  @Test func fileprivateInsideActorDoesNotTrigger() async {
    await assertNoViolation(
      PrivateOverFilePrivateRule.self,
      """
      actor MyActor {
        fileprivate let myInt = 4
      }
      """
    )
  }

  @Test func fileprivateSetDoesNotTrigger() async {
    await assertNoViolation(
      PrivateOverFilePrivateRule.self,
      """
      class MyClass {
        fileprivate(set) var myInt = 4
      }
      """
    )
  }

  @Test func fileprivateNestedStructDoesNotTrigger() async {
    await assertNoViolation(
      PrivateOverFilePrivateRule.self,
      """
      struct Outer {
        struct Inter {
          fileprivate struct Inner {}
        }
      }
      """
    )
  }

  @Test func fileprivateExtensionDoesNotTriggerWhenNotValidatingExtensions() async {
    await assertNoViolation(
      PrivateOverFilePrivateRule.self,
      "fileprivate extension String {}",
      configuration: ["validate_extensions": false]
    )
  }

  // MARK: - Triggering (default: validate_extensions = false)

  @Test func fileprivateEnumTriggers() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      "1️⃣fileprivate enum MyEnum {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func fileprivateClassWithFileprivateSetTriggers() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      """
      1️⃣fileprivate class MyClass {
        fileprivate(set) var myInt = 4
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func fileprivateActorTriggers() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      """
      1️⃣fileprivate actor MyActor {
        fileprivate let myInt = 4
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func multipleFileprivateDeclarationsTrigger() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      """
          1️⃣fileprivate func f() {}
          2️⃣fileprivate var x = 0
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")]
    )
  }

  // MARK: - Corrections

  @Test func correctsFileprivateEnumToPrivate() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate enum MyEnum {}",
      expected: "private enum MyEnum {}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsFileprivateEnumPreservesNestedFileprivate() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate enum MyEnum { fileprivate class A {} }",
      expected: "private enum MyEnum { fileprivate class A {} }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsFileprivateClassPreservesFileprivateSet() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate class MyClass { fileprivate(set) var myInt = 4 }",
      expected: "private class MyClass { fileprivate(set) var myInt = 4 }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsFileprivateActorPreservesFileprivateSet() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate actor MyActor { fileprivate(set) var myInt = 4 }",
      expected: "private actor MyActor { fileprivate(set) var myInt = 4 }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - validate_extensions = true

  @Test func fileprivateExtensionTriggersWhenValidatingExtensions() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      "1️⃣fileprivate extension String {}",
      findings: [FindingSpec("1️⃣")],
      configuration: ["validate_extensions": true]
    )
  }

  @Test func fileprivateExtensionWithNewlineTriggersWhenValidatingExtensions() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      "1️⃣fileprivate \n extension String {}",
      findings: [FindingSpec("1️⃣")],
      configuration: ["validate_extensions": true]
    )
  }

  @Test func fileprivateExtensionWithNewlineAfterExtensionTriggersWhenValidatingExtensions() async {
    await assertLint(
      PrivateOverFilePrivateRule.self,
      "1️⃣fileprivate extension \n String {}",
      findings: [FindingSpec("1️⃣")],
      configuration: ["validate_extensions": true]
    )
  }

  @Test func correctsFileprivateExtensionToPrivate() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate extension String {}",
      expected: "private extension String {}",
      findings: [FindingSpec("1️⃣")],
      configuration: ["validate_extensions": true]
    )
  }

  @Test func correctsFileprivateExtensionWithNewlineToPrivate() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate \n extension String {}",
      expected: "private \n extension String {}",
      findings: [FindingSpec("1️⃣")],
      configuration: ["validate_extensions": true]
    )
  }

  @Test func correctsFileprivateExtensionWithNewlineAfterExtensionToPrivate() async {
    await assertFormatting(
      PrivateOverFilePrivateRule.self,
      input: "1️⃣fileprivate extension \n String {}",
      expected: "private extension \n String {}",
      findings: [FindingSpec("1️⃣")],
      configuration: ["validate_extensions": true]
    )
  }
}
