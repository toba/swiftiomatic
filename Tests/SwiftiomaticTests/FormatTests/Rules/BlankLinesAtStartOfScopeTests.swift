import Testing

@testable import Swiftiomatic

@Suite struct BlankLinesAtStartOfScopeTests {
  @Test func blankLinesRemovedAtStartOfFunction() {
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
    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func blankLinesRemovedAtStartOfParens() {
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
    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func blankLinesRemovedAtStartOfBrackets() {
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
    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func blankLinesNotRemovedBetweenElementsInsideBrackets() {
    let input = """
      [foo,

       bar]
      """
    testFormatting(for: input, rule: .blankLinesAtStartOfScope, exclude: [.wrapArguments])
  }

  @Test func blankLineRemovedFromStartOfTypeByDefault() {
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
    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func blankLinesNotRemovedFromStartOfTypeWithOptionEnabled() {
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
      for: input, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .preserve))
  }

  @Test func blankLineAtStartOfScopeRemovedFromMethodInType() {
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
      for: input, output, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .preserve)
    )
  }

  @Test func blankLineInsertedAtStartOfType() {
    let input = """
      class Foo {
          func bar() {}

      }
      """
    let output = """
      class Foo {

          func bar() {}

      }
      """
    testFormatting(
      for: input, output, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .insert))
  }

  @Test func falsePositive() throws {
    let input = """
      struct S {
          // MARK: Internal

          func g() {}

          // MARK: Private

          private func f() {}
      }
      """
    #expect(try lint(input, rules: [.blankLinesAtStartOfScope, .organizeDeclarations]) == [])
  }

  @Test func removesBlankLineFromStartOfSwitchCase() {
    let input = """
      switch bool {

      case true:

          print("true")

      case false:

          print("false")
      }
      """

    let output = """
      switch bool {
      case true:
          print("true")

      case false:
          print("false")
      }
      """

    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func removesBlankLineInClosureWithParams() {
    let input = """
      presenter.present(viewController, animated: animated) { animated in

          if animated {
              self?.completion()
          }
      }
      """

    let output = """
      presenter.present(viewController, animated: animated) { animated in
          if animated {
              self?.completion()
          }
      }
      """

    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func removesBlankLineInClosureWithCapture() {
    let input = """
      presenter.present(viewController, animated: animated) { [weak self] animated in

          if animated {
              self?.completion()
          }
      }
      """

    let output = """
      presenter.present(viewController, animated: animated) { [weak self] animated in
          if animated {
              self?.completion()
          }
      }
      """

    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func removesBlankLineInClosureWithActorAnnotion() {
    let input = """
      presenter.present(viewController, animated: animated) { @MainActor in

          if animated {
              self?.completion()
          }
      }
      """

    let output = """
      presenter.present(viewController, animated: animated) { @MainActor in
          if animated {
              self?.completion()
          }
      }
      """

    testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
  }

  @Test func blankLinesInsertedAtStartOfType() {
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
      for: input, output, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .insert))
  }
}
