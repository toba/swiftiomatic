import Testing

@testable import Swiftiomatic

@Suite struct BlankLinesAtEndOfScopeTests {
  @Test func blankLinesRemovedAtEndOfFunction() {
    let input = """
      func foo() {
          // code

      }
      """

    let output = """
      func foo() {
          // code
      }
      """

    testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
  }

  @Test func blankLinesRemovedAtEndOfParens() {
    let input = """
      (
          foo: Int

      )
      """
    let output = """
      (
          foo: Int
      )
      """
    testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
  }

  @Test func blankLinesRemovedAtEndOfBrackets() {
    let input = """
      [
          foo,
          bar,

      ]
      """

    let output = """
      [
          foo,
          bar,
      ]
      """

    testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
  }

  @Test func blankLineNotRemovedBeforeElse() {
    let input = """
      if x {
          // do something

      } else if y {

          // do something else

      }
      """
    let output = """
      if x {
          // do something

      } else if y {

          // do something else
      }
      """
    testFormatting(
      for: input, output, rule: .blankLinesAtEndOfScope,
      exclude: [.blankLinesAtStartOfScope])
  }

  @Test func blankLineRemovedFromEndOfTypeByDefault() {
    let input = """
      class FooTests {
          func testFoo() {}

      }
      """

    let output = """
      class FooTests {
          func testFoo() {}
      }
      """
    testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
  }

  @Test func blankLinesNotRemovedFromEndOfTypeWithOptionEnabled() {
    let input = """
      class FooClass {
          func fooMethod() {}

      }

      struct FooStruct {
          func fooMethod() {}

      }

      enum FooEnum {
          func fooMethod() {}

      }

      actor FooActor {
          func fooMethod() {}

      }

      protocol FooProtocol {
          func fooMethod()
      }

      extension Array where Element == Foo {
          func fooMethod() {}

      }
      """
    testFormatting(
      for: input, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .preserve))
  }

  @Test func blankLineAtEndOfScopeRemovedFromMethodInType() {
    let input = """
      class Foo {
          func bar() {
              print("hello world")

          }
      }
      """

    let output = """
      class Foo {
          func bar() {
              print("hello world")
          }
      }
      """
    testFormatting(
      for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .preserve),
      exclude: [.blankLinesAtStartOfScope])
  }

  @Test func blankLinesInsertedAtEndOfType() {
    let input = """
      class FooClass {

          struct FooStruct {

              func nestedFunc() {}
          }

          func fooMethod() {}
      }
      """

    let output = """
      class FooClass {

          struct FooStruct {

              func nestedFunc() {}

          }

          func fooMethod() {}

      }
      """
    testFormatting(
      for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .insert))
  }

  @Test func blankLinesRemovedAtEndOfType() {
    let input = """
      class FooClass {
          struct FooStruct {
              func nestedFunc() {}
          }

          func fooMethod() {}
      }
      """

    let output = """
      class FooClass {
          struct FooStruct {
              func nestedFunc() {}

          }

          func fooMethod() {}

      }
      """
    testFormatting(
      for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .insert),
      exclude: [.blankLinesAtStartOfScope])
  }
}
