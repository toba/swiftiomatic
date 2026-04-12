import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered)
struct SingleLineBodyRuleTests {
  // MARK: - Non-triggering (already single-line or ineligible)

  @Test func alreadySingleLineGuard() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      func foo() {
          guard let x = y else { return }
          print(x)
      }
      """)
  }

  @Test func alreadySingleLineComputedProperty() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      struct Foo {
          var count: Int { items.count }
          var name: String { label }
      }
      """)
  }

  @Test func alreadySingleLineFunction() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      "func greeting() -> String { \"Hello\" }")
  }

  @Test func multipleStatements() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      func foo() {
          let x = compute()
          return x
      }
      """)
  }

  @Test func commentInBody() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      func foo() {
          guard let x = y else {
              // important reason
              return
          }
          print(x)
      }
      """)
  }

  @Test func emptyBody() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      "func foo() {}")
  }

  @Test func exceedsMaxWidth() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      func someVeryLongFunctionName(parameter: SomeVeryLongTypeName) -> ReturnType {
          expression
      }
      """,
      configuration: ["max_width": 40])
  }

  // MARK: - Triggering (should condense)

  @Test func condensesGuard() async {
    await assertViolates(
      SingleLineBodyRule.self,
      """
      func foo() {
          guard let x = y else {
              return
          }
          print(x)
      }
      """)
  }

  @Test func condensesComputedProperty() async {
    await assertViolates(
      SingleLineBodyRule.self,
      """
      struct Foo {
          var count: Int {
              items.count
          }
          var name: String { label }
      }
      """)
  }

  @Test func condensesFunction() async {
    await assertViolates(
      SingleLineBodyRule.self,
      """
      func greeting() -> String {
          "Hello"
      }
      """)
  }

  @Test func condensesClosure() async {
    await assertViolates(
      SingleLineBodyRule.self,
      """
      let items = [1, 2, 3]
      let x = items.map {
          $0 * 2
      }
      """)
  }

  // MARK: - Corrections

  @Test func correctsGuard() async {
    await assertFormatting(
      SingleLineBodyRule.self,
      input: """
        func foo() {
            guard let x = y else {
                return
            }
            print(x)
        }
        """,
      expected: """
        func foo() {
            guard let x = y else { return }
            print(x)
        }
        """)
  }

  @Test func correctsComputedProperty() async {
    await assertFormatting(
      SingleLineBodyRule.self,
      input: """
        struct Foo {
            var count: Int {
                items.count
            }
            var name: String { label }
        }
        """,
      expected: """
        struct Foo {
            var count: Int { items.count }
            var name: String { label }
        }
        """)
  }

  @Test func correctsFunction() async {
    await assertFormatting(
      SingleLineBodyRule.self,
      input: """
        func greeting() -> String {
            "Hello"
        }
        """,
      expected: """
        func greeting() -> String { "Hello" }
        """)
  }

  @Test func correctsClosure() async {
    await assertFormatting(
      SingleLineBodyRule.self,
      input: """
        let items = [1, 2, 3]
        let x = items.map {
            $0 * 2
        }
        """,
      expected: """
        let items = [1, 2, 3]
        let x = items.map { $0 * 2 }
        """)
  }

  @Test func correctsIfStatement() async {
    await assertFormatting(
      SingleLineBodyRule.self,
      input: """
        func foo() {
            if condition {
                return
            }
            doWork()
        }
        """,
      expected: """
        func foo() {
            if condition { return }
            doWork()
        }
        """)
  }

  @Test func respectsMaxWidth() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      func foo() {
          guard let value = optional else {
              return
          }
          print(value)
      }
      """,
      configuration: ["max_width": 30])
  }

  // MARK: - Nesting depth (column position)

  @Test func nestedGuardFitsWidth() async {
    await assertViolates(
      SingleLineBodyRule.self,
      """
      struct Foo {
          func bar() {
              guard let x = y else {
                  return
              }
              print(x)
          }
      }
      """)
  }

  @Test func nestedGuardExceedsWidth() async {
    await assertNoViolation(
      SingleLineBodyRule.self,
      """
      struct Foo {
          func bar() {
              guard let x = y else {
                  return
              }
              print(x)
          }
      }
      """,
      configuration: ["max_width": 35])
  }

  // MARK: - Cascading collapse

  @Test func cascadesWhenSingleStatement() async {
    // A function with only one statement (the guard) should collapse fully
    await assertFormatting(
      SingleLineBodyRule.self,
      input: """
        func validate() {
            guard isValid else {
                return
            }
        }
        """,
      expected: """
        func validate() { guard isValid else { return } }
        """)
  }
}
