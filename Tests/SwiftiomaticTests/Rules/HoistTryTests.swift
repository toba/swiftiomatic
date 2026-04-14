@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct HoistTryTests: RuleTesting {
  @Test func tryInsideArgument() {
    assertFormatting(
      HoistTry.self,
      input: """
        foo(1️⃣try bar())
        """,
      expected: """
        try foo(bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func multipleTryArguments() {
    assertFormatting(
      HoistTry.self,
      input: """
        foo(1️⃣try bar(), try baz())
        """,
      expected: """
        try foo(bar(), baz())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func tryAlreadyHoisted() {
    assertFormatting(
      HoistTry.self,
      input: """
        try foo(bar(), baz())
        """,
      expected: """
        try foo(bar(), baz())
        """,
      findings: []
    )
  }

  @Test func tryAtOuterLevel() {
    assertFormatting(
      HoistTry.self,
      input: """
        let x = try foo(bar())
        """,
      expected: """
        let x = try foo(bar())
        """,
      findings: []
    )
  }

  @Test func noTryInArguments() {
    assertFormatting(
      HoistTry.self,
      input: """
        foo(bar(), baz())
        """,
      expected: """
        foo(bar(), baz())
        """,
      findings: []
    )
  }

  @Test func tryInsideInitializer() {
    assertFormatting(
      HoistTry.self,
      input: """
        let x = String(1️⃣try getFoo())
        """,
      expected: """
        let x = try String(getFoo())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func awaitTryInsideArgument() {
    assertFormatting(
      HoistTry.self,
      input: """
        foo(await 1️⃣try bar())
        """,
      expected: """
        try foo(await bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func tryWrappedInOuterTry() {
    // Inner try is redundant but not this rule's concern
    assertFormatting(
      HoistTry.self,
      input: """
        try foo(try bar())
        """,
      expected: """
        try foo(try bar())
        """,
      findings: []
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func hoistTryWithOptionalTry() {
    // try? in argument should be preserved (different semantics)
    assertFormatting(
      HoistTry.self,
      input: """
        greet(1️⃣try name(), try? surname())
        """,
      expected: """
        try greet(name(), try? surname())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryOnlyOneArg() {
    assertFormatting(
      HoistTry.self,
      input: """
        greet(name, 1️⃣try surname())
        """,
      expected: """
        try greet(name, surname())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryPlacedBeforeAwait() {
    assertFormatting(
      HoistTry.self,
      input: """
        let foo = await bar(contentsOf: 1️⃣try baz())
        """,
      expected: """
        let foo = try await bar(contentsOf: baz())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func noHoistTryAfterOptionalTry() {
    // `try? bar(try baz())` — outer is try?, should not hoist inner
    assertFormatting(
      HoistTry.self,
      input: """
        let foo = try? bar(try baz())
        """,
      expected: """
        let foo = try? bar(try baz())
        """,
      findings: []
    )
  }

  @Test func tryInsideTupleNotHoisted() {
    // try inside a tuple expression (not a direct argument) is not hoisted
    assertFormatting(
      HoistTry.self,
      input: """
        array.append((value: try compute()))
        """,
      expected: """
        array.append((value: try compute()))
        """,
      findings: []
    )
  }

  @Test func optionalTryDoesNothing() {
    assertFormatting(
      HoistTry.self,
      input: """
        try? greet(name, surname)
        """,
      expected: """
        try? greet(name, surname)
        """,
      findings: []
    )
  }

  @Test func hoistTryWithReturn() {
    assertFormatting(
      HoistTry.self,
      input: """
        return .enumCase(1️⃣try service.greet())
        """,
      expected: """
        return try .enumCase(service.greet())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat reference tests

  @Test func hoistTryInsideOptionalFunction() {
    assertFormatting(
      HoistTry.self,
      input: """
        foo?(1️⃣try bar())
        """,
      expected: """
        try foo?(bar())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryAfterGenericType() {
    assertFormatting(
      HoistTry.self,
      input: """
        let foo = Tree<T>.Foo(bar: 1️⃣try baz())
        """,
      expected: """
        let foo = try Tree<T>.Foo(bar: baz())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryAfterArrayLiteral() {
    assertFormatting(
      HoistTry.self,
      input: """
        if [.first, .second].contains(1️⃣try foo()) {}
        """,
      expected: """
        if try [.first, .second].contains(foo()) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryAfterSubscript() {
    assertFormatting(
      HoistTry.self,
      input: """
        if foo[5].bar(1️⃣try baz()) {}
        """,
      expected: """
        if try foo[5].bar(baz()) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryInsideGenericInit() {
    assertFormatting(
      HoistTry.self,
      input: """
        return Target<T>(
            file: 1️⃣try parseFile(path: $0)
        )
        """,
      expected: """
        return try Target<T>(
            file: parseFile(path: $0)
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryOnLineBeginningWithInfixDot() {
    assertFormatting(
      HoistTry.self,
      input: """
        let foo = bar()
            .baz(1️⃣try quux())
        """,
      expected: """
        let foo = try bar()
            .baz(quux())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryWithAwaitOnDifferentStatement() {
    assertFormatting(
      HoistTry.self,
      input: """
        let asyncVariable = try await performSomething()
        return Foo(param1: 1️⃣try param1())
        """,
      expected: """
        let asyncVariable = try await performSomething()
        return try Foo(param1: param1())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryWithInitAssignment() {
    assertFormatting(
      HoistTry.self,
      input: """
        let variable = String(1️⃣try await asyncFunction())
        """,
      expected: """
        let variable = try String(await asyncFunction())
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryAfterString() {
    assertFormatting(
      HoistTry.self,
      input: """
        let json = "{}"

        someFunction(1️⃣try parse(json), "someKey")
        """,
      expected: """
        let json = "{}"

        try someFunction(parse(json), "someKey")
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryInsideArraySubscriptCall() {
    assertFormatting(
      HoistTry.self,
      input: """
        foo[bar](1️⃣try parseFile(path: $0))
        """,
      expected: """
        try foo[bar](parseFile(path: $0))
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }

  @Test func hoistTryInsideArgument() {
    assertFormatting(
      HoistTry.self,
      input: """
        array.append(contentsOf: 1️⃣try await asyncFunction(param1: param1))
        """,
      expected: """
        try array.append(contentsOf: await asyncFunction(param1: param1))
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'try' to the start of the expression"),
      ]
    )
  }
}
