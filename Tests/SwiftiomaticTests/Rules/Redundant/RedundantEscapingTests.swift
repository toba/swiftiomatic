@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantEscapingTests: RuleTesting {
  @Test func nonEscapingClosureFlagged() {
    assertFormatting(
      RedundantEscaping.self,
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
      RedundantEscaping.self,
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
      RedundantEscaping.self,
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
      RedundantEscaping.self,
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
      RedundantEscaping.self,
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
      RedundantEscaping.self,
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
      RedundantEscaping.self,
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
