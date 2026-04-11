import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ExplicitInitRuleTests {
  // MARK: - Non-triggering (default: include_bare_init = false)

  @Test func superInitDoesNotTrigger() async {
    await assertNoViolation(
      ExplicitInitRule.self,
      """
      import Foundation
      class C: NSObject {
          override init() {
              super.init()
          }
      }
      """
    )
  }

  @Test func selfInitDoesNotTrigger() async {
    await assertNoViolation(
      ExplicitInitRule.self,
      """
      struct S {
          let n: Int
      }
      extension S {
          init() {
              self.init(n: 1)
          }
      }
      """
    )
  }

  @Test func initAsClosureDoesNotTrigger() async {
    await assertNoViolation(ExplicitInitRule.self, "[1].flatMap(String.init)")
  }

  @Test func metatypeInitDoesNotTrigger() async {
    await assertNoViolation(ExplicitInitRule.self, "[String.self].map { $0.init(1) }")
  }

  @Test func metatypeInitNamedParamDoesNotTrigger() async {
    await assertNoViolation(
      ExplicitInitRule.self,
      "[String.self].map { type in type.init(1) }"
    )
  }

  @Test func initAsResultSelectorDoesNotTrigger() async {
    await assertNoViolation(
      ExplicitInitRule.self,
      "Observable.zip(obs1, obs2, resultSelector: MyType.init).asMaybe()"
    )
  }

  @Test func multiComponentInitDoesNotTrigger() async {
    await assertNoViolation(
      ExplicitInitRule.self,
      "_ = GleanMetrics.Tabs.someType.init()"
    )
  }

  // MARK: - Triggering (default: include_bare_init = false)

  @Test func typeInitInClosureTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      "[1].flatMap{String1️⃣.init($0)}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func capitalNamedParamInitTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      "[String.self].map { Type in Type1️⃣.init(1) }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func nestedFunctionInitTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      """
      func foo() -> [String] {
          return [1].flatMap { String1️⃣.init($0) }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func multiComponentTypeInitTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      "_ = GleanMetrics.Tabs.GroupedTabExtra1️⃣.init()",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func genericTypeInitTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      "_ = Set<KsApi.Category>1️⃣.init()",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func initInResultSelectorClosureTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      """
      Observable.zip(
        obs1,
        obs2,
        resultSelector: { MyType1️⃣.init($0, $1) }
      ).asMaybe()
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - Corrections (default: include_bare_init = false)

  @Test func correctsTypeInitInClosure() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: "[1].flatMap{String1️⃣.init($0)}",
      expected: "[1].flatMap{String($0)}",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsNestedFunctionInit() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: """
        func foo() -> [String] {
            return [1].flatMap { String1️⃣.init($0) }
        }
        """,
      expected: """
        func foo() -> [String] {
            return [1].flatMap { String($0) }
        }
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsMultiComponentTypeInit() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: "_ = GleanMetrics.Tabs.GroupedTabExtra1️⃣.init()",
      expected: "_ = GleanMetrics.Tabs.GroupedTabExtra()",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsGenericTypeInit() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: "_ = Set<KsApi.Category>1️⃣.init()",
      expected: "_ = Set<KsApi.Category>()",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsMultilineInit() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: """
        let int = Int1️⃣
        .init(1.0)
        """,
      expected: """
        let int = Int(1.0)
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsMultilineInitWithBlankLines() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: """
        let int = Int1️⃣


        .init(1.0)
        """,
      expected: """
        let int = Int(1.0)
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsInitWithCommentAbove() async {
    await assertFormatting(
      ExplicitInitRule.self,
      input: """
        f { e in
            // comment
            A1️⃣.init(e: e)
        }
        """,
      expected: """
        f { e in
            // comment
            A(e: e)
        }
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - include_bare_init = true

  @Test func bareInitDoesNotTriggerByDefault() async {
    await assertNoViolation(ExplicitInitRule.self, "let foo = Foo()")
  }

  @Test func plainInitCallDoesNotTriggerWithBareInit() async {
    await assertNoViolation(
      ExplicitInitRule.self, "let foo = init()",
      configuration: ["include_bare_init": true]
    )
  }

  @Test func bareInitTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      "let foo: Foo = 1️⃣.init()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["include_bare_init": true]
    )
  }

  @Test func multipleBareInitsTrigger() async {
    await assertLint(
      ExplicitInitRule.self,
      "let foo: [Foo] = [1️⃣.init(), 2️⃣.init()]",
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["include_bare_init": true]
    )
  }

  @Test func bareInitInFunctionCallTriggers() async {
    await assertLint(
      ExplicitInitRule.self,
      "foo(1️⃣.init())",
      findings: [FindingSpec("1️⃣")],
      configuration: ["include_bare_init": true]
    )
  }
}
