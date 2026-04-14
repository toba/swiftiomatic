@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoExplicitOwnershipTests: RuleTesting {

  @Test func removesOwnershipFromFunc() {
    assertFormatting(
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
      NoExplicitOwnership.self,
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
