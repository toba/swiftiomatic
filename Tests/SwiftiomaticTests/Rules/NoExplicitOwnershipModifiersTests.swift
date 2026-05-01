@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoExplicitOwnershipModifiersTests: RuleTesting {

  @Test func removesOwnershipFromFunc() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        1️⃣consuming func move() -> Self {}
        """,
      expected: """
        func move() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func removesBorrowingFromFunc() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        1️⃣borrowing func copy() -> Self {}
        """,
      expected: """
        func copy() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }

  @Test func removesOwnershipFromParameterType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ bar: 1️⃣consuming Bar) {}
        """,
      expected: """
        func foo(_ bar: Bar) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func removesBorrowingFromParameterType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ bar: 1️⃣borrowing Bar) {}
        """,
      expected: """
        func foo(_ bar: Bar) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }

  @Test func removesFromClosureParameter() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        foos.map { (foo: 1️⃣consuming Foo) in
          foo.bar
        }
        """,
      expected: """
        foos.map { (foo: Foo) in
          foo.bar
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func removesFromFunctionType() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        let f: (1️⃣consuming Foo) -> Bar
        """,
      expected: """
        let f: (Foo) -> Bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }

  @Test func multipleParametersWithOwnership() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ a: 1️⃣consuming Foo, _ b: 2️⃣borrowing Bar) {}
        """,
      expected: """
        func foo(_ a: Foo, _ b: Bar) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
        FindingSpec("2️⃣", message: "remove explicit 'borrowing' ownership modifier"),
      ]
    )
  }

  @Test func noOwnershipModifiersUnchanged() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        func foo(_ bar: Bar) {}
        """,
      expected: """
        func foo(_ bar: Bar) {}
        """,
      findings: []
    )
  }

  @Test func preservesOtherModifiers() {
    assertFormatting(
      NoExplicitOwnershipModifiers.self,
      input: """
        public 1️⃣consuming func move() -> Self {}
        """,
      expected: """
        public func move() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'consuming' ownership modifier"),
      ]
    )
  }
}
