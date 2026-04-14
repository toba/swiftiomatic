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
}
