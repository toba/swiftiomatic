@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantPropertyTests: RuleTesting {
  @Test func basicLetThenReturn() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        1️⃣let result = 42
        return result
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'result' property; return the expression directly"),
      ]
    )
  }

  @Test func expressionInitializer() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> String {
        1️⃣let text = bar() + baz()
        return text
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'text' property; return the expression directly"),
      ]
    )
  }

  @Test func differentNameNotFlagged() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        let result = 42
        return other
      }
      """,
      findings: []
    )
  }

  @Test func varNotFlagged() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        var result = 42
        return result
      }
      """,
      findings: []
    )
  }

  @Test func withTypeAnnotationNotFlagged() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        let result: Int = 42
        return result
      }
      """,
      findings: []
    )
  }

  @Test func nonConsecutiveNotFlagged() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        let result = 42
        print(result)
        return result
      }
      """,
      findings: []
    )
  }

  @Test func returnWithoutLetNotFlagged() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        return 42
      }
      """,
      findings: []
    )
  }

  @Test func multipleBindingsNotFlagged() {
    assertLint(
      RedundantProperty.self,
      """
      func foo() -> Int {
        let a = 1, b = 2
        return a
      }
      """,
      findings: []
    )
  }
}
