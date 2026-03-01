import Testing

@testable import Swiftiomatic

@Suite struct HoistAwaitTests {
  @Test func hoistAwait() {
    let input = """
      greet(await name, await surname)
      """
    let output = """
      await greet(name, surname)
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitInsideIf() {
    let input = """
      if !(await isSomething()) {}
      """
    let output = """
      if await !(isSomething()) {}
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
      exclude: [.redundantParens],
    )
  }

  @Test func hoistAwaitInsideArgument() {
    let input = """
      array.append(contentsOf: try await asyncFunction(param1: param1))
      """
    let output = """
      await array.append(contentsOf: try asyncFunction(param1: param1))
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry],
    )
  }

  @Test func hoistAwaitInsideStringInterpolation() {
    let input = """
      \"\\(replace(regex: await something()))\"
      """
    let output = """
      await \"\\(replace(regex: something()))\"
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitInsideStringInterpolation2() {
    let input = """
      "Hello \\(try await someValue())"
      """
    let output = """
      await "Hello \\(try someValue())"
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry],
    )
  }

  @Test func noHoistAwaitInsideDo() {
    let input = """
      do {
          rg.box.seal(.fulfilled(await body(error)))
      }
      """
    let output = """
      do {
          await rg.box.seal(.fulfilled(body(error)))
      }
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func noHoistAwaitInsideDoThrows() {
    let input = """
      do throws(Foo) {
          rg.box.seal(.fulfilled(await body(error)))
      }
      """
    let output = """
      do throws(Foo) {
          await rg.box.seal(.fulfilled(body(error)))
      }
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitInExpressionWithNoSpaces() {
    let input = """
      let foo=bar(contentsOf:await baz())
      """
    let output = """
      let foo=await bar(contentsOf:baz())
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.spaceAroundOperators],
    )
  }

  @Test func hoistAwaitInExpressionWithExcessSpaces() {
    let input = """
      let foo = bar ( contentsOf: await baz() )
      """
    let output = """
      let foo = await bar ( contentsOf: baz() )
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
      exclude: [.spaceAroundParens, .spaceInsideParens],
    )
  }

  @Test func hoistAwaitWithReturn() {
    let input = """
      return .enumCase(try await service.greet())
      """
    let output = """
      return await .enumCase(try service.greet())
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry],
    )
  }

  @Test func hoistDeeplyNestedAwaits() {
    let input = """
      let foo = (bar: (5, (await quux(), 6)), baz: (7, quux: await quux()))
      """
    let output = """
      let foo = await (bar: (5, (quux(), 6)), baz: (7, quux: quux()))
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func awaitNotHoistedOutOfClosure() {
    let input = """
      let foo = { (await bar(), 5) }
      """
    let output = """
      let foo = { await (bar(), 5) }
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func awaitNotHoistedOutOfClosureWithArguments() {
    let input = """
      let foo = { bar in (await baz(bar), 5) }
      """
    let output = """
      let foo = { bar in await (baz(bar), 5) }
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func awaitNotHoistedOutOfForCondition() {
    let input = """
      for foo in bar(await baz()) {}
      """
    let output = """
      for foo in await bar(baz()) {}
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func awaitNotHoistedOutOfForIndex() {
    let input = """
      for await foo in asyncSequence() {}
      """
    testFormatting(
      for: input, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitWithInitAssignment() {
    let input = """
      let variable = String(try await asyncFunction())
      """
    let output = """
      let variable = await String(try asyncFunction())
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry],
    )
  }

  @Test func hoistAwaitWithAssignment() {
    let input = """
      let variable = (try await asyncFunction())
      """
    let output = """
      let variable = await (try asyncFunction())
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry],
    )
  }

  @Test func hoistAwaitInRedundantScopePriorToNumber() {
    let input = """
      let identifiersTypes = 1
      (try? await asyncFunction(param1: param1))
      """
    let output = """
      let identifiersTypes = 1
      await (try? asyncFunction(param1: param1))
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitOnlyOne() {
    let input = """
      greet(name, await surname)
      """
    let output = """
      await greet(name, surname)
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitRedundantAwait() {
    let input = """
      await greet(await name, await surname)
      """
    let output = """
      await greet(name, surname)
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitDoesNothing() {
    let input = """
      await greet(name, surname)
      """
    testFormatting(
      for: input, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func noHoistAwaitBeforeTry() {
    let input = """
      try foo(await bar())
      """
    let output = """
      try await foo(bar())
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func noHoistAwaitInCapturingFunction() {
    let input = """
      foo(await bar)
      """
    testFormatting(
      for: input, rule: .hoistAwait,
      options: FormatOptions(asyncCapturing: ["foo"], swiftVersion: "5.5"),
    )
  }

  @Test func noHoistSecondArgumentAwaitInCapturingFunction() {
    let input = """
      foo(bar, await baz)
      """
    testFormatting(
      for: input, rule: .hoistAwait,
      options: FormatOptions(asyncCapturing: ["foo"], swiftVersion: "5.5"),
    )
  }

  @Test func hoistAwaitAfterOrdinaryOperator() {
    let input = """
      let foo = bar + (await baz)
      """
    let output = """
      let foo = await bar + (baz)
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.redundantParens],
    )
  }

  @Test func hoistAwaitAfterUnknownOperator() {
    let input = """
      let foo = bar ??? (await baz)
      """
    let output = """
      let foo = await bar ??? (baz)
      """
    testFormatting(
      for: input, output, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.redundantParens],
    )
  }

  @Test func noHoistAwaitAfterCapturingOperator() {
    let input = """
      let foo = await bar ??? (await baz)
      """
    testFormatting(
      for: input, rule: .hoistAwait,
      options: FormatOptions(asyncCapturing: ["???"], swiftVersion: "5.5"),
    )
  }

  @Test func noHoistAwaitInMacroArgument() {
    let input = """
      #expect (await monitor.isAvailable == false)
      """
    testFormatting(
      for: input, rule: .hoistAwait,
      options: FormatOptions(swiftVersion: "5.5"), exclude: [.spaceAroundParens],
    )
  }
}
