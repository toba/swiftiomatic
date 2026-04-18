@testable import Swiftiomatic
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

  // MARK: - Adapted from SwiftFormat reference tests

  @Test func hoistAwaitWithReturn() {
    assertFormatting(
      HoistAwait.self,
      input: """
        return .enumCase(try 1️⃣await service.greet())
        """,
      expected: """
        return await .enumCase(try service.greet())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func hoistAwaitWithInitAssignment() {
    assertFormatting(
      HoistAwait.self,
      input: """
        let variable = String(try 1️⃣await asyncFunction())
        """,
      expected: """
        let variable = await String(try asyncFunction())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func forAwaitNotHoisted() {
    // `for await` is different syntax — not a function call argument
    assertFormatting(
      HoistAwait.self,
      input: """
        for await _ in asyncSequence() {}
        """,
      expected: """
        for await _ in asyncSequence() {}
        """,
      findings: []
    )
  }

  @Test func macroArgumentNotHoisted() {
    // Macro expressions are not FunctionCallExprSyntax
    assertFormatting(
      HoistAwait.self,
      input: """
        #expect(await monitor.isAvailable == false)
        """,
      expected: """
        #expect(await monitor.isAvailable == false)
        """,
      findings: []
    )
  }

  @Test func hoistAwaitOnLineBeginningWithInfixDot() {
    assertFormatting(
      HoistAwait.self,
      input: """
        let foo = bar()
            .baz(1️⃣await quux())
        """,
      expected: """
        let foo = await bar()
            .baz(quux())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func hoistAwaitInsideGenericInit() {
    assertFormatting(
      HoistAwait.self,
      input: """
        return Target<T>(
            file: 1️⃣await parseFile(path: $0)
        )
        """,
      expected: """
        return await Target<T>(
            file: parseFile(path: $0)
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func hoistAwaitAfterSubscript() {
    assertFormatting(
      HoistAwait.self,
      input: """
        if foo[5].bar(1️⃣await baz()) {}
        """,
      expected: """
        if await foo[5].bar(baz()) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func hoistAwaitInsideOptionalFunction() {
    assertFormatting(
      HoistAwait.self,
      input: """
        foo?(1️⃣await bar())
        """,
      expected: """
        await foo?(bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }

  @Test func hoistAwaitAfterGenericType() {
    assertFormatting(
      HoistAwait.self,
      input: """
        let foo = Tree<T>.Foo(bar: 1️⃣await baz())
        """,
      expected: """
        let foo = await Tree<T>.Foo(bar: baz())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'await' to the start of the expression"),
      ]
    )
  }
}
