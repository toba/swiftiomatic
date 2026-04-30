@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferEmptyCollectionForArrayArgsTests: RuleTesting {
  @Test func emptyArrayLiteralArgument() {
    assertLint(
      PreferEmptyCollectionForArrayArgs.self,
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
      PreferEmptyCollectionForArrayArgs.self,
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
      PreferEmptyCollectionForArrayArgs.self,
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
      PreferEmptyCollectionForArrayArgs.self,
      """
      consume([1, 2, 3])
      """,
      findings: []
    )
  }

  @Test func arrayLiteralOutsideCallUntouched() {
    assertLint(
      PreferEmptyCollectionForArrayArgs.self,
      """
      let xs = []
      let ys: [Int] = [42]
      """,
      findings: []
    )
  }

  @Test func arrayLiteralInVarAssignmentUntouched() {
    assertLint(
      PreferEmptyCollectionForArrayArgs.self,
      """
      var xs: [Int] = []
      xs = [1]
      """,
      findings: []
    )
  }
}
