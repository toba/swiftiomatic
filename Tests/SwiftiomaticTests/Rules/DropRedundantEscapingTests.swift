@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantEscapingTests: RuleTesting {
  @Test func nonEscapingClosureFlagged() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func run(_ body: 1️⃣@escaping () -> Void) {
          body()
        }
        """,
      expected: """
        func run(_ body: () -> Void) {
          body()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@escaping' from 'body'; the closure does not escape"),
      ]
    )
  }

  @Test func escapingClosureKept() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        var stored: (() -> Void)?
        func store(_ body: @escaping () -> Void) {
          stored = body
        }
        """,
      expected: """
        var stored: (() -> Void)?
        func store(_ body: @escaping () -> Void) {
          stored = body
        }
        """,
      findings: []
    )
  }

  @Test func returnedClosureKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func make(_ body: @escaping () -> Void) -> () -> Void {
          return body
        }
        """,
      expected: """
        func make(_ body: @escaping () -> Void) -> () -> Void {
          return body
        }
        """,
      findings: []
    )
  }

  @Test func passedToFunctionKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func dispatch(_ body: @escaping () -> Void) {
          DispatchQueue.main.async(execute: body)
        }
        """,
      expected: """
        func dispatch(_ body: @escaping () -> Void) {
          DispatchQueue.main.async(execute: body)
        }
        """,
      findings: []
    )
  }

  @Test func usedInNestedClosureKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func wrap(_ body: @escaping () -> Void) {
          DispatchQueue.main.async {
            body()
          }
        }
        """,
      expected: """
        func wrap(_ body: @escaping () -> Void) {
          DispatchQueue.main.async {
            body()
          }
        }
        """,
      findings: []
    )
  }

  @Test func protocolMethodNotFlagged() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        protocol P {
          func run(_ body: @escaping () -> Void)
        }
        """,
      expected: """
        protocol P {
          func run(_ body: @escaping () -> Void)
        }
        """,
      findings: []
    )
  }

  // Tuple taint — closure passed inside a tuple to another function escapes.
  @Test func passedInsideTupleKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func outer(closure: @escaping () -> String) {
          inner(tuple: (closure, 42))
        }
        """,
      expected: """
        func outer(closure: @escaping () -> String) {
          inner(tuple: (closure, 42))
        }
        """,
      findings: []
    )
  }

  // Tuple taint — destructuring binding from a tuple containing the closure
  // taints the local, which then escapes via assignment to a non-local.
  @Test func tupleDestructuringToNonLocalKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func assignToLocal(completion: @escaping () -> Void) {
          let (local, _) = (completion, 17)
          self.local = local
        }
        """,
      expected: """
        func assignToLocal(completion: @escaping () -> Void) {
          let (local, _) = (completion, 17)
          self.local = local
        }
        """,
      findings: []
    )
  }

  // Tuple taint — whole-tuple binding then escape of the tuple.
  @Test func wholeTupleAssignedToNonLocalKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func assignToLocal(completion: @escaping () -> Void) {
          let local = (completion, 17)
          self.local = local
        }
        """,
      expected: """
        func assignToLocal(completion: @escaping () -> Void) {
          let local = (completion, 17)
          self.local = local
        }
        """,
      findings: []
    )
  }

  // Tuple taint — chained: tainted tuple destructured into a local that escapes.
  @Test func chainedTupleDestructuringKeepsEscaping() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func assignToLocal(completion: @escaping () -> Void) {
          let local = (completion, 17)
          let (c, n) = local
          self.c = c
        }
        """,
      expected: """
        func assignToLocal(completion: @escaping () -> Void) {
          let local = (completion, 17)
          let (c, n) = local
          self.c = c
        }
        """,
      findings: []
    )
  }

  @Test func multipleAttributesPreservesAutoclosure() {
    assertFormatting(
      DropRedundantEscaping.self,
      input: """
        func run(_ body: @autoclosure 1️⃣@escaping () -> Void) {
          body()
        }
        """,
      expected: """
        func run(_ body: @autoclosure () -> Void) {
          body()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@escaping' from 'body'; the closure does not escape"),
      ]
    )
  }
}
