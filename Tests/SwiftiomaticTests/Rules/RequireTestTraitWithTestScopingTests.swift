@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireTestTraitWithTestScopingTests: RuleTesting {
  private static let message =
    "add 'TestTrait' to this 'SuiteTrait' that conforms to 'TestScoping'; the test runner crashes without it"

  @Test func structWithSuiteTraitLastGetsTestTrait() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        struct Fixture: TestScoping, 1️⃣SuiteTrait {
          func provideScope() {}
        }
        """,
      expected: """
        struct Fixture: TestScoping, SuiteTrait, TestTrait {
          func provideScope() {}
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)])
  }

  @Test func structWithSuiteTraitFirstGetsTestTrait() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        struct Fixture: 1️⃣SuiteTrait, TestScoping {}
        """,
      expected: """
        struct Fixture: SuiteTrait, TestTrait, TestScoping {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)])
  }

  @Test func classActorAndEnumAreFlagged() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        final class A: 1️⃣SuiteTrait, TestScoping {}
        actor B: TestScoping, 2️⃣SuiteTrait {}
        enum C: Sendable, 3️⃣SuiteTrait, TestScoping {}
        """,
      expected: """
        final class A: SuiteTrait, TestTrait, TestScoping {}
        actor B: TestScoping, SuiteTrait, TestTrait {}
        enum C: Sendable, SuiteTrait, TestTrait, TestScoping {}
        """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
        FindingSpec("3️⃣", message: Self.message),
      ])
  }

  @Test func qualifiedNamesAreMatched() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        struct Fixture: Testing.TestScoping, 1️⃣Testing.SuiteTrait {}
        """,
      expected: """
        struct Fixture: Testing.TestScoping, Testing.SuiteTrait, TestTrait {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)])
  }

  @Test func multilineInheritanceKeepsLayout() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        struct Fixture:
          1️⃣SuiteTrait,
          TestScoping
        {}
        """,
      expected: """
        struct Fixture:
          SuiteTrait,
          TestTrait,
          TestScoping
        {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)])
  }

  @Test func extensionNamingBothIsFlagged() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        extension Fixture: TestScoping, 1️⃣SuiteTrait {}
        """,
      expected: """
        extension Fixture: TestScoping, SuiteTrait, TestTrait {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)])
  }

  @Test func alreadyHasTestTraitUnchanged() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        struct A: SuiteTrait, TestTrait, TestScoping {}
        struct B: TestScoping, SuiteTrait, Testing.TestTrait {}
        extension C: SuiteTrait, TestTrait, TestScoping {}
        """,
      expected: """
        struct A: SuiteTrait, TestTrait, TestScoping {}
        struct B: TestScoping, SuiteTrait, Testing.TestTrait {}
        extension C: SuiteTrait, TestTrait, TestScoping {}
        """)
  }

  @Test func nearMissesUnchanged() {
    assertFormatting(
      RequireTestTraitWithTestScoping.self,
      input: """
        struct A: SuiteTrait {}
        struct B: TestScoping {}
        struct C: TestTrait, TestScoping {}
        protocol D: SuiteTrait, TestScoping {}
        extension E: SuiteTrait {}
        """,
      expected: """
        struct A: SuiteTrait {}
        struct B: TestScoping {}
        struct C: TestTrait, TestScoping {}
        protocol D: SuiteTrait, TestScoping {}
        extension E: SuiteTrait {}
        """)
  }
}
