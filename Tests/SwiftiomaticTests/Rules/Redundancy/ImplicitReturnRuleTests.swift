import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ImplicitReturnRuleTests {
  // MARK: - Closure kind only

  @Test func closureWithoutReturnDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self, "foo.map { $0 + 1 }",
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureParensWithoutReturnDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self, "foo.map({ $0 + 1 })",
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureNamedParamWithoutReturnDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self, "foo.map { value in value + 1 }",
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureWithReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      foo.map { value in
          1️⃣return value + 1
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureWithReturnDollarArgTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      foo.map {
          1️⃣return $0 + 1
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureInlineReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      "foo.map({ 1️⃣return $0 + 1})",
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureReturnCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: """
        foo.map {
            return $0 + 1
        }
        """,
      expected: """
        foo.map {
            $0 + 1
        }
        """,
      configuration: ["included": ["closure"]]
    )
  }

  @Test func closureInlineReturnCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: "foo.map({ return $0 + 1 })",
      expected: "foo.map({ $0 + 1 })",
      configuration: ["included": ["closure"]]
    )
  }

  @Test func functionReturnDoesNotTriggerWhenOnlyClosureIncluded() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      func foo() -> Int {
          return 0
      }
      """,
      configuration: ["included": ["closure"]]
    )
  }

  // MARK: - Function kind only

  @Test func functionWithImplicitReturnDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      func foo() -> Int {
          0
      }
      """,
      configuration: ["included": ["function"]]
    )
  }

  @Test func functionWithMultipleStatementsDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      func f() -> Int {
          let i = 4
          return i
      }
      """,
      configuration: ["included": ["function"]]
    )
  }

  @Test func functionReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      func foo() -> Int {
          1️⃣return 0
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["function"]]
    )
  }

  @Test func classMethodReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      class Foo {
          func foo() -> Int { 1️⃣return 0 }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["function"]]
    )
  }

  @Test func voidFunctionReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      "func f() { 1️⃣return }",
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["function"]]
    )
  }

  @Test func functionReturnCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: """
        func foo() -> Int {
            return 0
        }
        """,
      expected: """
        func foo() -> Int {
            0
        }
        """,
      configuration: ["included": ["function"]]
    )
  }

  @Test func closureReturnDoesNotTriggerWhenOnlyFunctionIncluded() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      foo.map { value in
          return value + 1
      }
      """,
      configuration: ["included": ["function"]]
    )
  }

  // MARK: - Getter kind only

  @Test func getterWithImplicitReturnDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self, "var foo: Bool { true }",
      configuration: ["included": ["getter"]]
    )
  }

  @Test func getterReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      "var foo: Bool { 1️⃣return true }",
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["getter"]]
    )
  }

  @Test func explicitGetReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      class Foo {
          var bar: Int {
              get {
                  1️⃣return 0
              }
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["getter"]]
    )
  }

  @Test func staticVarReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      class Foo {
          static var bar: Int {
              1️⃣return 0
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["getter"]]
    )
  }

  @Test func getterReturnCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: "var foo: Bool { return true }",
      expected: "var foo: Bool { true }",
      configuration: ["included": ["getter"]]
    )
  }

  // MARK: - Initializer kind only

  @Test func initializerWithEarlyReturnDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      class C {
          let i: Int
          init(i: Int) {
              if i < 3 {
                  self.i = 1
                  return
              }
              self.i = 2
          }
      }
      """,
      configuration: ["included": ["initializer"]]
    )
  }

  @Test func failableInitWithMultipleStatementsDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      class C {
          init?() {
              let i = 1
              return nil
          }
      }
      """,
      configuration: ["included": ["initializer"]]
    )
  }

  @Test func initVoidReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      class C {
          init() {
              1️⃣return
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["initializer"]]
    )
  }

  @Test func failableInitReturnNilTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      class C {
          init?() {
              1️⃣return nil
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["initializer"]]
    )
  }

  @Test func failableInitReturnNilCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: """
        class C {
            init?() {
                return nil
            }
        }
        """,
      expected: """
        class C {
            init?() {
                nil
            }
        }
        """,
      configuration: ["included": ["initializer"]]
    )
  }

  // MARK: - Subscript kind only

  @Test func subscriptWithMultipleStatementsDoesNotTrigger() async {
    await assertNoViolation(
      ImplicitReturnRule.self,
      """
      class C {
          subscript(i: Int) -> Int {
              let res = i
              return res
          }
      }
      """,
      configuration: ["included": ["subscript"]]
    )
  }

  @Test func subscriptReturnTriggers() async {
    await assertLint(
      ImplicitReturnRule.self,
      """
      class C {
          subscript(i: Int) -> Int {
              1️⃣return i
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["included": ["subscript"]]
    )
  }

  @Test func subscriptReturnCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: """
        class C {
            subscript(i: Int) -> Int {
                return i
            }
        }
        """,
      expected: """
        class C {
            subscript(i: Int) -> Int {
                i
            }
        }
        """,
      configuration: ["included": ["subscript"]]
    )
  }

  // MARK: - Mixed kinds (all)

  @Test func mixedNestedReturnsCorrected() async {
    await assertFormatting(
      ImplicitReturnRule.self,
      input: """
        func foo() -> Int {
            return [1, 2].first(where: {
                return true
            })
        }
        """,
      expected: """
        func foo() -> Int {
            [1, 2].first(where: {
                true
            })
        }
        """
    )
  }
}
