@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseEmptyArrayLiteralForArgsTests: RuleTesting {
  @Test func emptyArrayLiteralArgument() {
    assertLint(
      UseEmptyArrayLiteralForArgs.self,
      """
      consume(1️⃣[])
      """,
      findings: [
        FindingSpec("1️⃣", message: "argument is an empty array literal — prefer 'EmptyCollection()' if the parameter accepts 'some Collection' / 'some Sequence'"),
      ]
    )
  }

  @Test func singleElementArrayLiteralArgument() {
    assertLint(
      UseEmptyArrayLiteralForArgs.self,
      """
      consume(1️⃣[42])
      """,
      findings: [
        FindingSpec("1️⃣", message: "argument is a single-element array literal — prefer 'CollectionOfOne(x)' if the parameter accepts 'some Collection' / 'some Sequence'"),
      ]
    )
  }

  @Test func labeledArgument() {
    assertLint(
      UseEmptyArrayLiteralForArgs.self,
      """
      configure(items: 1️⃣[])
      """,
      findings: [
        FindingSpec("1️⃣", message: "argument is an empty array literal — prefer 'EmptyCollection()' if the parameter accepts 'some Collection' / 'some Sequence'"),
      ]
    )
  }

  @Test func multiElementArrayUntouched() {
    assertLint(
      UseEmptyArrayLiteralForArgs.self,
      """
      consume([1, 2, 3])
      """,
      findings: []
    )
  }

  @Test func arrayLiteralOutsideCallUntouched() {
    assertLint(
      UseEmptyArrayLiteralForArgs.self,
      """
      let xs = []
      let ys: [Int] = [42]
      """,
      findings: []
    )
  }

  @Test func arrayLiteralInVarAssignmentUntouched() {
    assertLint(
      UseEmptyArrayLiteralForArgs.self,
      """
      var xs: [Int] = []
      xs = [1]
      """,
      findings: []
    )
  }
}
