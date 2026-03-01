import Testing

@testable import Swiftiomatic

extension WrapArgumentsTests {

  @Test func wrapAfterFirstConvertedToWrapBefore() {
    let input = """
      func foo(bar _: Int,
          baz _: String) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func linebreakInsertedAtEndOfWrappedFunction() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func afterFirstConvertedToBeforeFirst() {
    let input = """
      func foo(bar _: Int,
               baz _: String) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersListBeforeFirstInClosureType() {
    let input = """
      var mathFunction: (Int,
                         Int, String) -> Int = { _, _, _ in
          0
      }
      """
    let output = """
      var mathFunction: (
          Int,
          Int,
          String
      ) -> Int = { _, _, _ in
          0
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
    )
  }

  @Test func wrapParametersListBeforeFirstInThrowingClosureType() {
    let input = """
      var mathFunction: (Int,
                         Int, String) throws -> Int = { _, _, _ in
          0
      }
      """
    let output = """
      var mathFunction: (
          Int,
          Int,
          String
      ) throws -> Int = { _, _, _ in
          0
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
    )
  }

  @Test func wrapParametersListBeforeFirstInTypedThrowingClosureType() {
    let input = """
      var mathFunction: (Int,
                         Int, String) throws(Foo) -> Int = { _, _, _ in
          0
      }
      """
    let output = """
      var mathFunction: (
          Int,
          Int,
          String
      ) throws(Foo) -> Int = { _, _, _ in
          0
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
    )
  }

  @Test func wrapParametersListBeforeFirstInRethrowingClosureType() {
    let input = """
      var mathFunction: (Int,
                         Int, String) rethrows -> Int = { _, _, _ in
          0
      }
      """
    let output = """
      var mathFunction: (
          Int,
          Int,
          String
      ) rethrows -> Int = { _, _, _ in
          0
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
    )
  }

  @Test func wrapParametersListBeforeFirstInClosureTypeAsFunctionParameter() {
    let input = """
      func foo(bar: (Int,
                     Bool, String) -> Int) -> Int {}
      """
    let output = """
      func foo(bar: (
          Int,
          Bool,
          String
      ) -> Int) -> Int {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParams() {
    let input = """
      func foo(bar: Int, baz: (Int,
                               Bool, String) -> Int) -> Int {}
      """
    let output = """
      func foo(bar: Int, baz: (
          Int,
          Bool,
          String
      ) -> Int) -> Int {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test
  func wrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParamsAfterWrappedClosure()
  {
    let input = """
      func foo(bar: Int, baz: (Int,
                               Bool, String) -> Int, quux: String) -> Int {}
      """
    let output = """
      func foo(bar: Int, baz: (
          Int,
          Bool,
          String
      ) -> Int, quux: String) -> Int {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersListBeforeFirstInEscapingClosureTypeAsFunctionParameter() {
    let input = """
      func foo(bar: @escaping (Int,
                               Bool, String) -> Int) -> Int {}
      """
    let output = """
      func foo(bar: @escaping (
          Int,
          Bool,
          String
      ) -> Int) -> Int {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersListBeforeFirstInNoEscapeClosureTypeAsFunctionParameter() {
    let input = """
      func foo(bar: @noescape (Int,
                               Bool, String) -> Int) -> Int {}
      """
    let output = """
      func foo(bar: @noescape (
          Int,
          Bool,
          String
      ) -> Int) -> Int {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersListBeforeFirstInEscapingAutoclosureTypeAsFunctionParameter() {
    let input = """
      func foo(bar: @escaping @autoclosure (Int,
                                            Bool, String) -> Int) -> Int {}
      """
    let output = """
      func foo(bar: @escaping @autoclosure (
          Int,
          Bool,
          String
      ) -> Int) -> Int {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments],
      options: options,
      exclude: [.unusedArguments],
    )
  }

  // MARK: beforeFirst, maxWidth

  @Test func wrapBeforeFirstIfMaxLengthExceeded() {
    let input = """
      func foo(bar: Int, baz: String) -> Bool {}
      """
    let output = """
      func foo(
          bar: Int,
          baz: String
      ) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 20)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func noWrapBeforeFirstIfMaxLengthNotExceeded() {
    let input = """
      func foo(bar: Int, baz: String) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 42)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func noWrapGenericsIfClosingBracketWithinMaxWidth() {
    let input = """
      func foo<T: Bar>(bar: Int, baz: String) -> Bool {}
      """
    let output = """
      func foo<T: Bar>(
          bar: Int,
          baz: String
      ) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 20)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func wrapAlreadyWrappedArgumentsIfMaxLengthExceeded() {
    let input = """
      func foo(
          bar: Int, baz: String, quux: Bool
      ) -> Bool {}
      """
    let output = """
      func foo(
          bar: Int, baz: String,
          quux: Bool
      ) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 26)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersBeforeFirstIfMaxLengthExceededInReturnType() {
    let input = """
      func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
      """
    let output2 = """
      func foo(
          bar: Int,
          baz: String,
          quux: Bool
      ) -> LongReturnType {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 50)
    testFormatting(
      for: input, [input, output2], rules: [.wrapArguments],
      options: options, exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersBeforeFirstWithSeparatedArgumentLabels() {
    let input = """
      func foo(with
          bar: Int, and
          baz: String
      ) -> LongReturnType {}
      """
    let output = """
      func foo(
          with bar: Int,
          and baz: String
      ) -> LongReturnType {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst)
    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: options, exclude: [.unusedArguments],
    )
  }

  @Test func wrapParametersListBeforeFirstInClosureTypeWithMaxWidth() {
    let input = """
      var mathFunction: (Int, Int, String) -> Int = { _, _, _ in
          0
      }
      """
    let output = """
      var mathFunction: (
          Int,
          Int,
          String
      ) -> Int = { _, _, _ in
          0
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, [output], rules: [.wrapArguments],
      options: options,
    )
  }

  @Test func noWrapBeforeFirstMaxWidthNotExceededWithLineBreakSinceLastEndOfArgumentScope() {
    let input = """
      class Foo {
          func foo() {
              bar()
          }

          func bar(foo: String, bar: Int) {
              quux()
          }
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 37)
    testFormatting(
      for: input, rule: .wrapArguments,
      options: options, exclude: [.unusedArguments],
    )
  }

  @Test func noWrapSubscriptWithSingleElement() {
    let input = """
      guard let foo = bar[0] {}
      """
    let output = """
      guard let foo = bar[
          0
      ] {}
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 20)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.wrap],
    )
  }

  @Test func wrapArrayWithSingleElementIfOverMaxWidth() {
    let input = """
      let foo = [0]
      """
    let output = """
      let foo = [
          0,
      ]
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 11)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas], options: options,
      exclude: [.wrap],
    )
  }

  @Test func wrapPartiallyWrappedArrayWithSingleElement() {
    let input = """
      let foo = [
          0]
      """
    let output = """
      let foo = [
          0,
      ]
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 100)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas], options: options,
      exclude: [.wrap],
    )
  }

  @Test func wrapDictionaryWithSingleElementIfOverMaxWidth() {
    let input = """
      let foo = [bar: baz]
      """
    let output = """
      let foo = [
          bar: baz,
      ]
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 15)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas], options: options,
      exclude: [.wrap],
    )
  }

  @Test func noWrapImageLiteral() {
    let input = """
      if let image = #imageLiteral(resourceName: \"abc.png\") {}
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.wrap],
    )
  }

  @Test func noWrapColorLiteral() {
    let input = """
      if let color = #colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1) {}
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.wrap],
    )
  }

  @Test func wrapArgumentsNoIndentBlankLines() {
    let input = """
      let foo = [

          bar,

      ]
      """
    let options = FormatOptions(wrapCollections: .beforeFirst)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.wrap, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  // MARK: closingParenPosition = true

  @Test func parenOnSameLineWhenWrapAfterFirstConvertedToWrapBefore() {
    let input = """
      func foo(bar _: Int,
          baz _: String) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, closingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func parenOnSameLineWhenWrapBeforeFirstUnchanged() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, closingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func parenOnSameLineWhenWrapBeforeFirstPreserved() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .preserve, closingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  // MARK: indent with tabs

  @Test func tabIndentWrappedFunctionWithSmartTabs() {
    let input = """
      func foo(bar: Int,
               baz: Int) {}
      """
    let options = FormatOptions(indent: "\t", wrapParameters: .afterFirst, tabWidth: 2)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func tabIndentWrappedFunctionWithoutSmartTabs() {
    let input = """
      func foo(bar: Int,
               baz: Int) {}
      """
    let output = """
      func foo(bar: Int,
      \t\t\t\t baz: Int) {}
      """
    let options = FormatOptions(
      indent: "\t", wrapParameters: .afterFirst,
      tabWidth: 2, smartTabs: false,
    )
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments],
    )
  }

}
