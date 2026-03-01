import Testing

@testable import Swiftiomatic

@Suite struct SpaceAroundBracketsTests {
  @Test func subscriptNoAddSpacing() {
    let input = """
      foo[bar] = baz
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func subscriptRemoveSpacing() {
    let input = """
      foo [bar] = baz
      """
    let output = """
      foo[bar] = baz
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func arrayLiteralSpacing() {
    let input = """
      foo = [bar, baz]
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func spaceNotRemovedAfterOfArray() {
    let input = """
      let foo: [4 of [String]]
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func spaceAddedAfterOfArray() {
    let input = """
      let foo: [4 of[String]]
      """
    let output = """
      let foo: [4 of [String]]
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func ofIdentifierBracketSpacing() {
    let input = """
      if foo.of[String.self] {}
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func asArrayCastingSpacing() {
    let input = """
      foo as[String]
      """
    let output = """
      foo as [String]
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func asOptionalArrayCastingSpacing() {
    let input = """
      foo as? [String]
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func isArrayTestingSpacing() {
    let input = """
      if foo is[String] {}
      """
    let output = """
      if foo is [String] {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func isIdentifierBracketSpacing() {
    let input = """
      if foo.is[String.self] {}
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func spaceBeforeTupleIndexSubscript() {
    let input = """
      foo.1 [2]
      """
    let output = """
      foo.1[2]
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func removeSpaceBetweenBracketAndParen() {
    let input = """
      let foo = bar[5] ()
      """
    let output = """
      let foo = bar[5]()
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func removeSpaceBetweenBracketAndParenInsideClosure() {
    let input = """
      let foo = bar { [Int] () }
      """
    let output = """
      let foo = bar { [Int]() }
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func addSpaceBetweenCaptureListAndParen() {
    let input = """
      let foo = bar { [self](foo: Int) in foo }
      """
    let output = """
      let foo = bar { [self] (foo: Int) in foo }
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func addSpaceBetweenInoutAndStringArray() {
    let input = """
      func foo(arg _: inout[String]) {}
      """
    let output = """
      func foo(arg _: inout [String]) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func addSpaceBetweenConsumingAndStringArray() {
    let input = """
      func foo(arg _: consuming[String]) {}
      """
    let output = """
      func foo(arg _: consuming [String]) {}
      """
    testFormatting(
      for: input, output, rule: .spaceAroundBrackets,
      exclude: [.noExplicitOwnership],
    )
  }

  @Test func addSpaceBetweenBorrowingAndStringArray() {
    let input = """
      func foo(arg _: borrowing[String]) {}
      """
    let output = """
      func foo(arg _: borrowing [String]) {}
      """
    testFormatting(
      for: input, output, rule: .spaceAroundBrackets,
      exclude: [.noExplicitOwnership],
    )
  }

  @Test func addSpaceBetweenSendingAndStringArray() {
    let input = """
      func foo(arg _: sending[String]) {}
      """
    let output = """
      func foo(arg _: sending [String]) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func spaceNotRemovedBetweenAsOperatorAndBracket() {
    // https://github.com/nicklockwood/SwiftFormat/issues/1846
    let input = """
      @Test(arguments: [kSecReturnRef, kSecReturnAttributes] as [String])
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func spaceNotRemovedBetweenTryAndBracket() {
    let input = """
      @Test(arguments: try [Identifier(101), nil])
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }

  @Test func addSpaceBetweenBracketAndAwait() {
    let input = """
      let foo = await[bar: 5]
      """
    let output = """
      let foo = await [bar: 5]
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func addSpaceBetweenParenAndAwaitForSwift5_5() {
    let input = """
      let foo = await[bar: 5]
      """
    let output = """
      let foo = await [bar: 5]
      """
    testFormatting(
      for: input, output, rule: .spaceAroundBrackets,
      options: FormatOptions(swiftVersion: "5.5"),
    )
  }

  @Test func noAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
    let input = """
      let foo = await[bar: 5]
      """
    testFormatting(
      for: input, rule: .spaceAroundBrackets,
      options: FormatOptions(swiftVersion: "5.4.9"),
    )
  }

  @Test func addSpaceBetweenParenAndUnsafe() {
    let input = """
      unsafe[kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
      """
    let output = """
      unsafe [kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
      """
    testFormatting(for: input, output, rule: .spaceAroundBrackets)
  }

  @Test func noAddSpaceBetweenParenAndAwaitForSwiftLessThan6_2() {
    let input = """
      unsafe[kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
      """
    testFormatting(
      for: input, rule: .spaceAroundBrackets,
      options: FormatOptions(swiftVersion: "6.1"),
    )
  }

  @Test func spacePreservedBetweenGlobalActorAndCaptureList() {
    let input = """
      Task { @MainActor [capturedProperty] in
          print(capturedProperty)
      }

      Task { @MyGlobalActor [capturedProperty] in
          print(capturedProperty)
      }
      """
    testFormatting(for: input, rule: .spaceAroundBrackets)
  }
}
