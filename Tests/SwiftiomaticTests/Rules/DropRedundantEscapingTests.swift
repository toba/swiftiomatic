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
