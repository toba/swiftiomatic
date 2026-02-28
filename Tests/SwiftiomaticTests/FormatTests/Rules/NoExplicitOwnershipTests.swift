import Testing

@testable import Swiftiomatic

@Suite struct NoExplicitOwnershipTests {
  @Test func removesOwnershipKeywordsFromFunc() {
    let input = """
      consuming func myMethod(consuming foo: consuming Foo, borrowing bars: borrowing [Bar]) {}
      borrowing func myMethod(consuming foo: consuming Foo, borrowing bars: borrowing [Bar]) {}
      """

    let output = """
      func myMethod(consuming foo: Foo, borrowing bars: [Bar]) {}
      func myMethod(consuming foo: Foo, borrowing bars: [Bar]) {}
      """

    testFormatting(for: input, output, rule: .noExplicitOwnership, exclude: [.unusedArguments])
  }

  @Test func removesOwnershipKeywordsFromClosure() {
    let input = """
      foos.map { (foo: consuming Foo) in
          foo.bar
      }

      foos.map { (foo: borrowing Foo) in
          foo.bar
      }
      """

    let output = """
      foos.map { (foo: Foo) in
          foo.bar
      }

      foos.map { (foo: Foo) in
          foo.bar
      }
      """

    testFormatting(for: input, output, rule: .noExplicitOwnership, exclude: [.unusedArguments])
  }

  @Test func removesOwnershipKeywordsFromType() {
    let input = """
      let consuming: (consuming Foo) -> Bar
      let borrowing: (borrowing Foo) -> Bar
      """

    let output = """
      let consuming: (Foo) -> Bar
      let borrowing: (Foo) -> Bar
      """

    testFormatting(for: input, output, rule: .noExplicitOwnership)
  }
}
