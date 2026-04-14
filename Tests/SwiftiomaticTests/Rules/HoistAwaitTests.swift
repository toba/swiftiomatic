@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct HoistAwaitTests: RuleTesting {
  @Test func awaitInsideArgument() {
    assertFormatting(
      HoistAwait.self,
      input: """
        foo(1️⃣await bar())
        """,
      expected: """
        await foo(bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func multipleAwaitArguments() {
    assertFormatting(
      HoistAwait.self,
      input: """
        foo(1️⃣await bar(), await baz())
        """,
      expected: """
        await foo(bar(), baz())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func awaitAlreadyHoisted() {
    assertFormatting(
      HoistAwait.self,
      input: """
        await foo(bar(), baz())
        """,
      expected: """
        await foo(bar(), baz())
        """,
      findings: []
    )
  }

  @Test func noAwaitInArguments() {
    assertFormatting(
      HoistAwait.self,
      input: """
        foo(bar(), baz())
        """,
      expected: """
        foo(bar(), baz())
        """,
      findings: []
    )
  }

  @Test func tryAwaitInsideArgument() {
    assertFormatting(
      HoistAwait.self,
      input: """
        foo(try 1️⃣await bar())
        """,
      expected: """
        await foo(try bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func awaitWrappedInOuterAwait() {
    assertFormatting(
      HoistAwait.self,
      input: """
        await foo(await bar())
        """,
      expected: """
        await foo(await bar())
        """,
      findings: []
    )
  }

  @Test func awaitInsideInitializer() {
    assertFormatting(
      HoistAwait.self,
      input: """
        let x = String(1️⃣await getFoo())
        """,
      expected: """
        let x = await String(getFoo())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func hoistAwaitOnlyOneArg() {
    assertFormatting(
      HoistAwait.self,
      input: """
        greet(name, 1️⃣await surname)
        """,
      expected: """
        await greet(name, surname)
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func hoistAwaitInsideTryParent() {
    // `try foo(await bar())` → `try await foo(bar())`
    assertFormatting(
      HoistAwait.self,
      input: """
        try foo(1️⃣await bar())
        """,
      expected: """
        try await foo(bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func awaitInsideTryAwaitArgument() {
    assertFormatting(
      HoistAwait.self,
      input: """
        array.append(contentsOf: try 1️⃣await asyncFunction(param1: param1))
        """,
      expected: """
        await array.append(contentsOf: try asyncFunction(param1: param1))
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func awaitDoesNothing() {
    assertFormatting(
      HoistAwait.self,
      input: """
        await greet(name, surname)
        """,
      expected: """
        await greet(name, surname)
        """,
      findings: []
    )
  }
}
