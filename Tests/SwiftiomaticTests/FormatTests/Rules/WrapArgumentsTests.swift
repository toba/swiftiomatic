import Testing

@testable import Swiftiomatic

@Suite struct WrapArgumentsTests {
  @Test func indentFirstElementWhenApplyingWrap() {
    let input = """
      let foo = Set([
      Thing(),
      Thing(),
      ])
      """
    let output = """
      let foo = Set([
          Thing(),
          Thing(),
      ])
      """
    testFormatting(for: input, output, rule: .wrapArguments, exclude: [.propertyTypes])
  }

  @Test func wrapArgumentsDoesntIndentTrailingComment() {
    let input = """
      foo( // foo
      bar: Int,
      baaz: Int
      )
      """
    let output = """
      foo( // foo
          bar: Int,
          baaz: Int
      )
      """
    testFormatting(for: input, output, rule: .wrapArguments)
  }

  @Test func wrapArgumentsDoesntIndentClosingBracket() {
    let input = """
      [
          "foo": [
          ],
      ]
      """
    testFormatting(for: input, rule: .wrapArguments)
  }

  @Test func wrapParametersDoesNotAffectFunctionDeclaration() {
    let input = """
      foo(
          bar _: Int,
          baz _: String
      )
      """
    let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersClosureAfterParameterListDoesNotWrapClosureArguments() {
    let input = """
      func foo() {}
      bar = (baz: 5, quux: 7,
             quuz: 10)
      """
    let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .beforeFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersNotSetWrapArgumentsAfterFirstDefaultsToAfterFirst() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let output = """
      func foo(bar _: Int,
               baz _: String) {}
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersNotSetWrapArgumentsBeforeFirstDefaultsToBeforeFirst() {
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
    let options = FormatOptions(wrapArguments: .beforeFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersNotSetWrapArgumentsPreserveDefaultsToPreserve() {
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
    let options = FormatOptions(wrapArguments: .preserve)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionDeclarationClosingParenOnSameLine() {
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
    let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionDeclarationClosingParenOnNextLine() {
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
    let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .balanced)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionDeclarationClosingParenOnSameLineAndForce() {
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
    let options = FormatOptions(
      wrapArguments: .beforeFirst, closingParenPosition: .sameLine,
      callSiteClosingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionDeclarationClosingParenOnNextLineAndForce() {
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
    let options = FormatOptions(
      wrapArguments: .beforeFirst, closingParenPosition: .balanced,
      callSiteClosingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionDeclarationClosingParenOnNextLineSingleArgument() {
    let input = """
      func foo(
          bar _: Int) {}
      """
    let output = """
      func foo(
          bar _: Int
      ) {}
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst, closingParenPosition: .balanced, maxWidth: 100)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionCallClosingParenOnNextLineAndForce() {
    let input = """
      foo(
          bar: 42,
          baz: "foo"
      )
      """
    let output = """
      foo(
          bar: 42,
          baz: "foo")
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst, closingParenPosition: .balanced,
      callSiteClosingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionCallClosingParenBalancedAndForce() {
    let input = """
      foo(
          bar: 42,
          baz: "foo")
      """
    let output = """
      foo(
          bar: 42,
          baz: "foo"
      )
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst, closingParenPosition: .sameLine,
      callSiteClosingParenPosition: .balanced)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersFunctionCallClosingParenBalancedSingleArgument() {
    let input = """
      foo(
          bar: 42)
      """
    let output = """
      foo(
          bar: 42
      )
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst, closingParenPosition: .sameLine,
      callSiteClosingParenPosition: .balanced, maxWidth: 100)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func indentMultilineStringWhenWrappingArguments() {
    let input = """
      foobar(foo: \"\""
                 baz
             \"\"",
             bar: \"\""
                 baz
             \"\"")
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func handleXcodeTokenApplyingWrap() {
    let input = """
      test(image: \u{003c}#T##UIImage#>, name: "Name")
      """

    let output = """
      test(
          image: \u{003c}#T##UIImage#>,
          name: "Name"
      )
      """
    let options = FormatOptions(wrapArguments: .beforeFirst, maxWidth: 20)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func issue1530() {
    let input = """
      extension DRAutoWeatherReadRequestResponse {
          static let mock = DRAutoWeatherReadRequestResponse(
              offlineFirstWeather: DRAutoWeatherReadRequestResponse.DROfflineFirstWeather(
                  daily: .mockWeatherID, hourly: []
              )
          )
      }
      """
    let options = FormatOptions(wrapArguments: .beforeFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.propertyTypes])
  }

  // MARK: wrapParameters

  // MARK: preserve

  @Test func afterFirstPreserved() {
    let input = """
      func foo(bar _: Int,
               baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func afterFirstPreservedIndentFixed() {
    let input = """
      func foo(bar _: Int,
       baz _: String) {}
      """
    let output = """
      func foo(bar _: Int,
               baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func afterFirstPreservedNewlineRemoved() {
    let input = """
      func foo(bar _: Int,
               baz _: String
      ) {}
      """
    let output = """
      func foo(bar _: Int,
               baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func beforeFirstPreserved() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func beforeFirstPreservedIndentFixed() {
    let input = """
      func foo(
          bar _: Int,
       baz _: String
      ) {}
      """
    let output = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func beforeFirstPreservedNewlineAdded() {
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
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapParametersAfterMultilineComment() {
    let input = """
      /**
       Some function comment.
       */
      func barFunc(
          _ firstParam: FirstParamType,
          secondParam: SecondParamType
      )
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // MARK: afterFirst

  @Test func beforeFirstConvertedToAfterFirst() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let output = """
      func foo(bar _: Int,
               baz _: String) {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func noWrapInnerArguments() {
    let input = """
      func foo(
          bar _: Int,
          baz _: foo(bar, baz)
      ) {}
      """
    let output = """
      func foo(bar _: Int,
               baz _: foo(bar, baz)) {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  // MARK: afterFirst, maxWidth

  @Test func wrapAfterFirstIfMaxLengthExceeded() {
    let input = """
      func foo(bar: Int, baz: String) -> Bool {}
      """
    let output = """
      func foo(bar: Int,
               baz: String) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments, .wrap])
  }

  @Test func wrapAfterFirstIfMaxLengthExceeded2() {
    let input = """
      func foo(bar: Int, baz: String, quux: Bool) -> Bool {}
      """
    let output = """
      func foo(bar: Int,
               baz: String,
               quux: Bool) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments, .wrap])
  }

  @Test func wrapAfterFirstIfMaxLengthExceeded3() {
    let input = """
      func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
      """
    let output = """
      func foo(bar: Int, baz: String,
               aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments, .wrap])
  }

  @Test func wrapAfterFirstIfMaxLengthExceeded3WithWrap() {
    let input = """
      func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
      """
    let output = """
      func foo(bar: Int, baz: String,
               aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
               -> Bool {}
      """
    let output2 = """
      func foo(bar: Int, baz: String,
               aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
          -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
    testFormatting(
      for: input, [output, output2],
      rules: [.wrapArguments, .wrap],
      options: options, exclude: [.unusedArguments])
  }

  @Test func wrapAfterFirstIfMaxLengthExceeded4WithWrap() {
    let input = """
      func foo(bar: String, baz: String, quux: Bool) -> Bool {}
      """
    let output = """
      func foo(bar: String,
               baz: String,
               quux: Bool) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments, .wrap],
      options: options, exclude: [.unusedArguments])
  }

  @Test func wrapAfterFirstIfMaxLengthExceededInClassScopeWithWrap() {
    let input = """
      class TestClass {
          func foo(bar: String, baz: String, quux: Bool) -> Bool {}
      }
      """
    let output = """
      class TestClass {
          func foo(bar: String,
                   baz: String,
                   quux: Bool)
                   -> Bool {}
      }
      """
    let output2 = """
      class TestClass {
          func foo(bar: String,
                   baz: String,
                   quux: Bool)
              -> Bool {}
      }
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
    testFormatting(
      for: input, [output, output2],
      rules: [.wrapArguments, .wrap],
      options: options, exclude: [.unusedArguments])
  }

  @Test func wrapParametersListInClosureType() {
    let input = """
      var mathFunction: (Int,
                         Int, String) -> Int = { _, _, _ in
          0
      }
      """
    let output = """
      var mathFunction: (Int,
                         Int,
                         String) -> Int = { _, _, _ in
          0
      }
      """
    let output2 = """
      var mathFunction: (Int,
                         Int,
                         String)
          -> Int = { _, _, _ in
              0
          }
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 30)
    testFormatting(
      for: input, [output, output2],
      rules: [.wrapArguments],
      options: options)
  }

  @Test func wrapParametersAfterFirstIfMaxLengthExceededInReturnType() {
    let input = """
      func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
      """
    let output2 = """
      func foo(bar: Int, baz: String,
               quux: Bool) -> LongReturnType {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 50)
    testFormatting(
      for: input, [input, output2], rules: [.wrapArguments],
      options: options, exclude: [.unusedArguments])
  }

  @Test func wrapParametersAfterFirstWithSeparatedArgumentLabels() {
    let input = """
      func foo(with
          bar: Int, and
          baz: String, and
          quux: Bool
      ) -> LongReturnType {}
      """
    let output = """
      func foo(with bar: Int,
               and baz: String,
               and quux: Bool) -> LongReturnType {}
      """
    let options = FormatOptions(wrapParameters: .afterFirst)
    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: options, exclude: [.unusedArguments])
  }

  // MARK: beforeFirst

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
      options: options)
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
      options: options)
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
      options: options)
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
      options: options)
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
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
  }

  @Test
  func
    wrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParamsAfterWrappedClosure()
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
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
  }

  @Test func noWrapBeforeFirstIfMaxLengthNotExceeded() {
    let input = """
      func foo(bar: Int, baz: String) -> Bool {}
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 42)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
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
      exclude: [.unusedArguments])
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
      options: options, exclude: [.unusedArguments])
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
      options: options, exclude: [.unusedArguments])
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
      options: options)
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
      options: options, exclude: [.unusedArguments])
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
      exclude: [.wrap])
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
      exclude: [.wrap])
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
      exclude: [.wrap])
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
      exclude: [.wrap])
  }

  @Test func noWrapImageLiteral() {
    let input = """
      if let image = #imageLiteral(resourceName: \"abc.png\") {}
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.wrap])
  }

  @Test func noWrapColorLiteral() {
    let input = """
      if let color = #colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1) {}
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.wrap])
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
      exclude: [.wrap, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
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
      exclude: [.unusedArguments])
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
      tabWidth: 2, smartTabs: false)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments])
  }

  // MARK: - wrapArguments --wrapArguments

  @Test func wrapArgumentsDoesNotAffectFunctionDeclaration() {
    let input = """
      func foo(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapArgumentsDoesNotAffectInit() {
    let input = """
      init(
          bar _: Int,
          baz _: String
      ) {}
      """
    let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapArgumentsDoesNotAffectSubscript() {
    let input = """
      subscript(
          bar _: Int,
          baz _: String
      ) -> Int {}
      """
    let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // MARK: afterFirst

  @Test func wrapArgumentsConvertBeforeFirstToAfterFirst() {
    let input = """
      foo(
          bar _: Int,
          baz _: String
      )
      """
    let output = """
      foo(bar _: Int,
          baz _: String)
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func correctWrapIndentForNestedArguments() {
    let input = """
      foo(
      bar: (
      x: 0,
      y: 0
      ),
      baz: (
      x: 0,
      y: 0
      )
      )
      """
    let output = """
      foo(bar: (x: 0,
                y: 0),
          baz: (x: 0,
                y: 0))
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func noRemoveLinebreakAfterCommentInArguments() {
    let input = """
      a(b // comment
      )
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noRemoveLinebreakAfterCommentInArguments2() {
    let input = """
      foo(bar: bar
      //  ,
      //  baz: baz
          ) {}
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.indent])
  }

  @Test func consecutiveCodeCommentsNotIndented() {
    let input = """
      foo(bar: bar,
      //    bar,
      //    baz,
          quux)
      """
    let options = FormatOptions(wrapArguments: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // MARK: afterFirst maxWidth

  @Test func wrapArgumentsAfterFirst() {
    let input = """
      foo(bar: Int, baz: String, quux: Bool)
      """
    let output = """
      foo(bar: Int,
          baz: String,
          quux: Bool)
      """
    let options = FormatOptions(wrapArguments: .afterFirst, maxWidth: 20)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.unusedArguments, .wrap])
  }

  // MARK: beforeFirst

  @Test func closureInsideParensNotWrappedOntoNextLine() {
    let input = """
      foo({
          bar()
      })
      """
    let options = FormatOptions(wrapArguments: .beforeFirst)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.trailingClosures])
  }

  @Test func noMangleCommentedLinesWhenWrappingArguments() {
    let input = """
      foo(bar: bar, quux: quux
      //    ,
      //    baz: baz
          ) {}
      """
    let output = """
      foo(
          bar: bar,
          quux: quux
      //    ,
      //    baz: baz
      ) {}
      """
    let options = FormatOptions(wrapArguments: .beforeFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func noMangleCommentedLinesWhenWrappingArgumentsWithNoCommas() {
    let input = """
      foo(bar: bar, quux: quux
      //    baz: baz
          ) {}
      """
    let output = """
      foo(
          bar: bar,
          quux: quux
      //    baz: baz
      ) {}
      """
    let options = FormatOptions(wrapArguments: .beforeFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  // MARK: preserve

  @Test func wrapArgumentsDoesNotAffectLessThanOperator() {
    let input = """
      func foo() {
          guard foo < bar.count else { return nil }
      }
      """
    let options = FormatOptions(wrapArguments: .preserve)
    testFormatting(
      for: input, rule: .wrapArguments,
      options: options, exclude: [.wrapConditionalBodies])
  }

  // MARK: - --wrapArguments, --wrapParameter

  // MARK: beforeFirst

  @Test func noMistakeTernaryExpressionForArguments() {
    let input = """
      (foo ?
          bar :
          baz)
      """
    let options = FormatOptions(wrapArguments: .beforeFirst, wrapParameters: .beforeFirst)
    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.redundantParens])
  }

  // MARK: beforeFirst, maxWidth : string interpolation

  @Test func noWrapBeforeFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(interpolation) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 40)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeFirstArgumentInStringInterpolation2() {
    let input = """
      "a very long string literal with \\(interpolation) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 50)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeFirstArgumentInStringInterpolation3() {
    let input = """
      "a very long string literal with \\(interpolated, variables) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 40)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeNestedFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(foo(interpolated)) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 45)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeNestedFirstArgumentInStringInterpolation2() {
    let input = """
      "a very long string literal with \\(foo(interpolated, variables)) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 45)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapProtocolFuncParametersBeforeFirst() {
    let input = """
      public protocol Foo {
          public func stringify<T>(_ value: T, label: String) -> (T, String)
      }
      """
    let output = """
      public protocol Foo {
          public func stringify<T>(
              _ value: T,
              label: String
          ) -> (T, String)
      }
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: options)
  }

  // MARK: afterFirst maxWidth : string interpolation

  @Test func noWrapAfterFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(interpolated) inside"
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapParameters: .afterFirst,
      maxWidth: 46)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapAfterFirstArgumentInStringInterpolation2() {
    let input = """
      "a very long string literal with \\(interpolated, variables) inside"
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapParameters: .afterFirst,
      maxWidth: 50)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapAfterNestedFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(foo(interpolated, variables)) inside"
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapParameters: .afterFirst,
      maxWidth: 55)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // macros

  @Test func wrapMacroParametersBeforeFirst() {
    let input = """
      @freestanding(expression)
      public macro stringify<T>(_ value: T, label: String) -> (T, String)
      """
    let output = """
      @freestanding(expression)
      public macro stringify<T>(
          _ value: T,
          label: String
      ) -> (T, String)
      """
    let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: options)
  }

  // MARK: - wrapArguments --wrapCollections

  // MARK: beforeFirst

  @Test func noDoubleSpaceAddedToWrappedArray() {
    let input = """
      [ foo,
          bar ]
      """
    let output = """
      [
          foo,
          bar
      ]
      """
    let options = FormatOptions(trailingCommas: .never, wrapCollections: .beforeFirst)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .spaceInsideBrackets],
      options: options)
  }

  @Test func trailingCommasAddedToWrappedArray() {
    let input = """
      [foo,
          bar]
      """
    let output = """
      [
          foo,
          bar,
      ]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .beforeFirst)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  @Test func trailingCommasAddedToWrappedNestedDictionary() {
    let input = """
      [foo: [bar: baz,
          bar2: baz2]]
      """
    let output = """
      [foo: [
          bar: baz,
          bar2: baz2,
      ]]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .beforeFirst)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  @Test func trailingCommasAddedToSingleLineNestedDictionary() {
    let input = """
      [
          foo: [bar: baz, bar2: baz2]]
      """
    let output = """
      [
          foo: [bar: baz, bar2: baz2],
      ]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .beforeFirst)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  @Test func trailingCommasAddedToWrappedNestedDictionaries() {
    let input = """
      [foo: [bar: baz,
          bar2: baz2],
          foo2: [bar: baz,
          bar2: baz2]]
      """
    let output = """
      [
          foo: [
              bar: baz,
              bar2: baz2,
          ],
          foo2: [
              bar: baz,
              bar2: baz2,
          ],
      ]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .beforeFirst)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  @Test func spaceAroundEnumValuesInArray() {
    let input = """
      [
          .foo,
          .bar, .baz,
      ]
      """
    let options = FormatOptions(wrapCollections: .beforeFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // MARK: beforeFirst maxWidth

  @Test func wrapCollectionOnOneLineBeforeFirstWidthExceededInChainedFunctionCallAfterCollection() {
    let input = """
      let foo = ["bar", "baz"].quux(quuz)
      """
    let output = """
      let foo = ["bar", "baz"]
          .quux(quuz)
      """
    let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 26)
    testFormatting(
      for: input, [output],
      rules: [.wrap, .wrapArguments], options: options)
  }

  // MARK: afterFirst

  @Test func trailingCommaRemovedInWrappedArray() {
    let input = """
      [
          .foo,
          .bar,
          .baz,
      ]
      """
    let output = """
      [.foo,
       .bar,
       .baz]
      """
    let options = FormatOptions(wrapCollections: .afterFirst)
    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func noRemoveLinebreakAfterCommentInElements() {
    let input = """
      [a, // comment
      ]
      """
    let options = FormatOptions(wrapCollections: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapCollectionsConsecutiveCodeCommentsNotIndented() {
    let input = """
      let a = [foo,
      //         bar,
      //         baz,
               quux]
      """
    let options = FormatOptions(wrapCollections: .afterFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapCollectionsConsecutiveCodeCommentsNotIndentedInWrapBeforeFirst() {
    let input = """
      let a = [
          foo,
      //    bar,
      //    baz,
          quux,
      ]
      """
    let options = FormatOptions(wrapCollections: .beforeFirst)
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // MARK: preserve

  @Test func noBeforeFirstPreservedAndTrailingCommaIgnoredInMultilineNestedDictionary() {
    let input = """
      [foo: [bar: baz,
          bar2: baz2]]
      """
    let output = """
      [foo: [bar: baz,
             bar2: baz2]]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .preserve)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  @Test func beforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionary() {
    let input = """
      [
          foo: [bar: baz, bar2: baz2]]
      """
    let output = """
      [
          foo: [bar: baz, bar2: baz2],
      ]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .preserve)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  @Test
  func beforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionaryWithOneNestedItem() {
    let input = """
      [
          foo: [bar: baz]]
      """
    let output = """
      [
          foo: [bar: baz],
      ]
      """
    let options = FormatOptions(trailingCommas: .always, wrapCollections: .preserve)
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .trailingCommas],
      options: options)
  }

  // MARK: - wrapArguments --wrapCollections & --wrapArguments

  // MARK: beforeFirst maxWidth

  @Test func wrapArgumentsBeforeFirstWhenArgumentsExceedMaxWidthAndArgumentIsCollection() {
    let input = """
      foo(bar: ["baz", "quux"], quuz: corge)
      """
    let output = """
      foo(
          bar: ["baz", "quux"],
          quuz: corge
      )
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapCollections: .beforeFirst,
      maxWidth: 26)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments], options: options)
  }

  // MARK: afterFirst maxWidth

  @Test func wrapArgumentsAfterFirstWhenArgumentsExceedMaxWidthAndArgumentIsCollection() {
    let input = """
      foo(bar: ["baz", "quux"], quuz: corge)
      """
    let output = """
      foo(bar: ["baz", "quux"],
          quuz: corge)
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapCollections: .beforeFirst,
      maxWidth: 26)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments], options: options)
  }

  // MARK: - wrapArguments Multiple Wraps On Same Line

  @Test func wrapAfterFirstWhenChainedFunctionAndThenArgumentsExceedMaxWidth() {
    let input = """
      foo.bar(baz: [qux, quux]).quuz([corge: grault], garply: waldo)
      """
    let output = """
      foo.bar(baz: [qux, quux])
          .quuz([corge: grault],
                garply: waldo)
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapCollections: .afterFirst,
      maxWidth: 28)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments, .wrap], options: options)
  }

  @Test
  func wrapAfterFirstWrapCollectionsBeforeFirstWhenChainedFunctionAndThenArgumentsExceedMaxWidth() {
    let input = """
      foo.bar(baz: [qux, quux]).quuz([corge: grault], garply: waldo)
      """
    let output = """
      foo.bar(baz: [qux, quux])
          .quuz([corge: grault],
                garply: waldo)
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapCollections: .beforeFirst,
      maxWidth: 28)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments, .wrap], options: options)
  }

  @Test func noMangleNestedFunctionCalls() {
    let input = """
      points.append(.curve(
          quadraticBezier(p0.position.x, Double(p1.x), Double(p2.x), t),
          quadraticBezier(p0.position.y, Double(p1.y), Double(p2.y), t)
      ))
      """
    let output = """
      points.append(.curve(
          quadraticBezier(
              p0.position.x,
              Double(p1.x),
              Double(p2.x),
              t
          ),
          quadraticBezier(
              p0.position.y,
              Double(p1.y),
              Double(p2.y),
              t
          )
      ))
      """
    let options = FormatOptions(wrapArguments: .beforeFirst, maxWidth: 40)
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments, .wrap], options: options)
  }

  @Test func wrapArguments_typealias_beforeFirst() {
    let input = """
      typealias Dependencies = FooProviding & BarProviding & BaazProviding & QuuxProviding
      """

    let output = """
      typealias Dependencies
          = FooProviding
          & BarProviding
          & BaazProviding
          & QuuxProviding
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 40)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_multipleTypealiases_beforeFirst() {
    let input = """
      enum Namespace {
          typealias DependenciesA = FooProviding & BarProviding
          typealias DependenciesB = BaazProviding & QuuxProviding
      }
      """

    let output = """
      enum Namespace {
          typealias DependenciesA
              = FooProviding
              & BarProviding
          typealias DependenciesB
              = BaazProviding
              & QuuxProviding
      }
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 45)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_afterFirst() {
    let input = """
      typealias Dependencies = FooProviding & BarProviding & BaazProviding & QuuxProviding
      """

    let output = """
      typealias Dependencies = FooProviding
          & BarProviding
          & BaazProviding
          & QuuxProviding
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 40)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_multipleTypealiases_afterFirst() {
    let input = """
      enum Namespace {
          typealias DependenciesA = FooProviding & BarProviding
          typealias DependenciesB = BaazProviding & QuuxProviding
      }
      """

    let output = """
      enum Namespace {
          typealias DependenciesA = FooProviding
              & BarProviding
          typealias DependenciesB = BaazProviding
              & QuuxProviding
      }
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 45)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth() {
    let input = """
      typealias Dependencies = FooProviding & BarProviding & BaazProviding
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 100)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently() {
    let input = """
      typealias Dependencies = FooProviding & BarProviding &
          BaazProviding & QuuxProviding
      """

    let output = """
      typealias Dependencies = FooProviding
          & BarProviding
          & BaazProviding
          & QuuxProviding
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 200)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently2() {
    let input = """
      enum Namespace {
          typealias Dependencies = FooProviding & BarProviding
              & BaazProviding & QuuxProviding
      }
      """

    let output = """
      enum Namespace {
          typealias Dependencies
              = FooProviding
              & BarProviding
              & BaazProviding
              & QuuxProviding
      }
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 200)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently3() {
    let input = """
      typealias Dependencies
          = FooProviding & BarProviding &
          BaazProviding & QuuxProviding
      """

    let output = """
      typealias Dependencies = FooProviding
          & BarProviding
          & BaazProviding
          & QuuxProviding
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 200)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently4() {
    let input = """
      typealias Dependencies
          = FooProviding
          & BarProviding
          & BaazProviding
          & QuuxProviding
      """

    let output = """
      typealias Dependencies = FooProviding
          & BarProviding
          & BaazProviding
          & QuuxProviding
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 200)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistentlyWithComment() {
    let input = """
      typealias Dependencies = FooProviding & BarProviding // trailing comment 1
          // Inline Comment 1
          & BaazProviding & QuuxProviding // trailing comment 2
      """

    let output = """
      typealias Dependencies
          = FooProviding
          & BarProviding // trailing comment 1
          // Inline Comment 1
          & BaazProviding
          & QuuxProviding // trailing comment 2
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 200)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_singleTypePreserved() {
    let input = """
      typealias Dependencies = FooProviding
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 10)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.wrap])
  }

  @Test func wrapArguments_typealias_preservesCommentsBetweenTypes() {
    let input = """
      typealias Dependencies
          // We use `FooProviding` because `FooFeature` depends on `Foo`
          = FooProviding
          // We use `BarProviding` because `BarFeature` depends on `Bar`
          & BarProviding
          // We use `BaazProviding` because `BaazFeature` depends on `Baaz`
          & BaazProviding
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 100)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_preservesCommentsAfterTypes() {
    let input = """
      typealias Dependencies
          = FooProviding // We use `FooProviding` because `FooFeature` depends on `Foo`
          & BarProviding // We use `BarProviding` because `BarFeature` depends on `Bar`
          & BaazProviding // We use `BaazProviding` because `BaazFeature` depends on `Baaz`
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 100)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  @Test func wrapArguments_typealias_withAssociatedType() {
    let input = """
      typealias Collections = Collection<Int> & Collection<String> & Collection<Double> & Collection<Float>
      """

    let output = """
      typealias Collections
          = Collection<Int>
          & Collection<String>
          & Collection<Double>
          & Collection<Float>
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 50)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
  }

  // MARK: - -return wrap-if-multiline

  @Test func wrapReturnOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String) -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapReturnOnMultilineFunctionDeclarationInProtocol() {
    let input = """
      protocol MyProtocol {
          func multilineFunction(
              foo _: String,
              bar _: String) -> String
      }
      """

    let output = """
      protocol MyProtocol {
          func multilineFunction(
              foo _: String,
              bar _: String)
              -> String
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func wrapReturnAndEffectOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String) async -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func doesntWrapReturnAndEffectOnSingleLineFunctionDeclaration() {
    let input = """
      func singleLineFunction() async throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func doesntWrapReturnAndTypedEffectOnSingleLineFunctionDeclaration() {
    let input = """
      func singleLineFunction() async throws(Foo) -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapEffectOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String) async throws
          -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapEffectOnMultilineInit() {
    let input = """
      init(
          foo: String,
          bar: String
      )
      async throws
      {
          print(foo, bar)
      }
      """

    let output = """
      init(
          foo: String,
          bar: String
      ) async throws {
          print(foo, bar)
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, [output], rules: [.wrapArguments, .braces], options: options)
  }

  @Test func wrapEffectOnMultilineProtocolRequirement() {
    let input = """
      protocol MyProtocol {
          func multilineFunction(
              foo _: String,
              bar _: String) async throws
              -> String
      }
      """

    let output = """
      protocol MyProtocol {
          func multilineFunction(
              foo _: String,
              bar _: String)
              async throws -> String
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapEffectOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String) async throws
          -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapEffectAndReturnTypeOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String
      ) async throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func formatReturnTypeOnMultilineFunctionDeclarationWithLineComment() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws
          -> String // this is a comment
      {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String
      ) async throws -> String // this is a comment
      {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapClosingBraceInVoidThrowingMethod() {
    let input = """
      func multilineFunction(
          foo: String,
          bar: String)
          async throws
      {
          print(foo, bar)
      }
      """

    let output = """
      func multilineFunction(
          foo: String,
          bar: String
      ) async throws {
          print(foo, bar)
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, [output], rules: [.wrapArguments, .braces], options: options)
  }

  @Test func unwrapClosingBraceInVoidNonThrowingMethod() {
    let input = """
      func multilineFunction(
          foo: String,
          bar: String)
      {
          print(foo, bar)
      }
      """

    let output = """
      func multilineFunction(
          foo: String,
          bar: String
      ) {
          print(foo, bar)
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, [output], rules: [.wrapArguments, .braces], options: options)
  }

  @Test func wrapReturnIfMultilineOnClosureArgument() {
    let input = """
      func multilineFunctionWithClosureArgument(
          closure: ((
              _ view: ChartContainerView<Self>,
              _ content: Content,
              _ traitCollection: UITraitCollection,
              _ state: ItemCellState) -> Void)? = nil) -> String
      {
          print(closure)
      }
      """

    let output = """
      func multilineFunctionWithClosureArgument(
          closure: ((
              _ view: ChartContainerView<Self>,
              _ content: Content,
              _ traitCollection: UITraitCollection,
              _ state: ItemCellState)
              -> Void)? = nil)
          -> String
      {
          print(closure)
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      maxWidth: 100
    )

    testFormatting(for: input, [output], rules: [.wrapArguments, .wrap, .indent], options: options)
  }

  @Test func preservesReturnInClosure() {
    let input = """
      public private(set) var foo: ((
          UIAccessibility.Notification,
          Any?,
          Bool,
          TimeInterval,
          String,
          Int,
          String) -> Void)?
      """

    let output = """
      public private(set) var foo: ((
          UIAccessibility.Notification,
          Any?,
          Bool,
          TimeInterval,
          String,
          Int,
          String)
          -> Void)?
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapCollections: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      maxWidth: 100,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, [output], rules: [.wrapArguments, .wrap], options: options)
  }

  @Test func formatReturnTypeOnMultilineFunctionDeclarationWithBlockComment() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws
          -> String /* block comment */
      {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String
      ) async throws -> String /* block comment */ {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapReturnTypeOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String
      ) -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapReturnTypeOnMultilineSubscriptDeclaration() {
    let input = """
      subscript(
          foo _: String,
          bar _: String)
          -> String {}
      """

    let output = """
      subscript(
          foo _: String,
          bar _: String
      ) -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func unwrapBraceForReturnTypeOnMultilineFunctionDeclaration() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          -> String 
      {
          print("hello")
      }
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String
      ) -> String {
          print("hello")
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .balanced,
      wrapReturnType: .never,
      wrapEffects: .never
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func allmanBraceWithWrapReturnTypeNever() {
    let input = """
      func makeStuff(
          param1: String = "",
          param2: Int? = nil,
          param3: String = ""
      ) -> String {
          print(param1, param2, param3)
          return "return"
      }
      """
    let output = """
      func makeStuff(
          param1: String = "",
          param2: Int? = nil,
          param3: String = ""
      ) -> String
      {
          print(param1, param2, param3)
          return "return"
      }
      """
    let options = FormatOptions(allmanBraces: true, wrapReturnType: .never)
    testFormatting(for: input, [output], rules: [.wrapArguments, .braces], options: options)
  }

  @Test func wrapArgumentsDoesntBreakFunctionDeclaration_issue_1776() {
    let input = """
      struct OpenAPIController: RouteCollection {
          let info = InfoObject(title: "Swagger {{cookiecutter.service_name}} - OpenAPI",
                                description: "{{cookiecutter.description}}",
                                contact: .init(email: "{{cookiecutter.email}}"),
                                version: Version(0, 0, 1))
          func boot(routes: RoutesBuilder) throws {
              routes.get("swagger", "swagger.json") {
                  $0.application.routes.openAPI(info: info)
              }
              .excludeFromOpenAPI()
          }
      }
      """

    let options = FormatOptions(wrapEffects: .never)
    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.propertyTypes])
  }

  @Test func wrapEffectsNeverPreservesComments() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          // Comment here between the parameters and effects
          async throws -> String {}
      """

    let output = """
      func multilineFunction(
          foo _: String,
          bar _: String) async throws -> String {}
      """

    let options = FormatOptions(closingParenPosition: .sameLine, wrapEffects: .never)
    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent]
    )
  }

  @Test func wrapReturnOnMultilineFunctionDeclarationWithAfterFirst() {
    let input = """
      func multilineFunction(foo _: String,
                             bar _: String) -> String {}
      """

    let output = """
      func multilineFunction(foo _: String,
                             bar _: String)
                             -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .afterFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent]
    )
  }

  @Test func wrapReturnOnMultilineThrowingFunctionDeclarationWithAfterFirst() {
    let input = """
      func multilineFunction(foo _: String,
                             bar _: String) throws -> String {}
      """

    let output = """
      func multilineFunction(foo _: String,
                             bar _: String) throws
                             -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .afterFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent]
    )
  }

  @Test func wrapReturnAndEffectOnMultilineThrowingFunctionDeclarationWithAfterFirst() {
    let input = """
      func multilineFunction(foo _: String,
                             bar _: String) throws -> String {}
      """

    let output = """
      func multilineFunction(foo _: String,
                             bar _: String)
                             throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .afterFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent]
    )
  }

  @Test func wrapEffectsNeverDoesntUnwrapAsyncLet() {
    let input = """
      async let createdAd = createAd(
          subcategoryID: subcategory.id,
          shopID: shop?.id)
      async let locationCity = createEditAdWorker.loadNearestCity(coordinates: coordinates)
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func wrapEffectsWrapsAsyncEffectBeforeLetProperty() {
    let input = """
      @attached(body) macro GenerateBody() = #externalMacro(module: "...", type: "...")

      @GenerateBody // generates the body
      func foo(
          _ bar: Baaz,
          _ baaz: Baaz) async

      let quux: Quux
      """

    let output = """
      @attached(body) macro GenerateBody() = #externalMacro(module: "...", type: "...")

      @GenerateBody // generates the body
      func foo(
          _ bar: Baaz,
          _ baaz: Baaz)
      async

      let quux: Quux
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, [output], rules: [.wrapArguments, .indent], options: options)
  }

  @Test func wrapsThrowsBeforeAsyncLet() {
    let input = """
      @GenerateBody // generates the body
      func foo(
          _ bar: Baaz,
          _ baaz: Baaz) throws

      async let quux: Quux
      """

    let output = """
      @GenerateBody // generates the body
      func foo(
          _ bar: Baaz,
          _ baaz: Baaz)
          throws

      async let quux: Quux
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func doesntWrapReturnOnMultilineThrowingFunction() {
    let input = """
      func multilineFunction(foo _: String,
                             bar _: String)
                             throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .afterFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.indent]
    )
  }

  @Test func doesntWrapReturnOnSingleLineFunctionDeclaration() {
    let input = """
      func multilineFunction(foo _: String, bar _: String) -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func doesntWrapReturnOnSingleLineFunctionDeclarationAfterMultilineArray() {
    let input = """
      final class Foo {
          private static let array = [
              "one",
          ]

          private func singleLine() -> String {}
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func doesntWrapReturnOnSingleLineFunctionDeclarationAfterMultilineMethodCall() {
    let input = """
      public final class Foo {
          public var multiLineMethodCall = Foo.multiLineMethodCall(
              bar: bar,
              baz: baz)

          func singleLine() -> String {
              return "method body"
          }
      }
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline
    )

    testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.propertyTypes])
  }

  @Test func preserveReturnOnMultilineFunctionDeclarationByDefault() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String) -> String
      {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  // MARK: wrapConditions before-first

  @Test func wrapConditionsBeforeFirstPreservesMultilineStatements() {
    let input = """
      if
          let unwrappedFoo = Foo(
              bar: bar,
              baz: baz),
          unwrappedFoo.elements
              .compactMap({ $0 })
              .filter({
                  if $0.matchesCondition {
                      return true
                  } else {
                      return false
                  }
              })
              .isEmpty,
          let bar = unwrappedFoo.bar,
          let baz = unwrappedFoo.bar?
              .first(where: { $0.isBaz }),
          let unwrappedFoo2 = Foo(
              bar: bar2,
              baz: baz2),
          let quux = baz.quux
      {}
      """
    testFormatting(
      for: input, rules: [.wrapArguments, .indent],
      options: FormatOptions(closingParenPosition: .sameLine, wrapConditions: .beforeFirst),
      exclude: [.propertyTypes]
    )
  }

  @Test func wrapConditionsBeforeFirst() {
    let input = """
      if let foo = foo,
         let bar = bar,
         foo == bar {}

      else if foo != bar,
              let quux = quux {}

      if let baz = baz {}

      guard baz.filter({ $0 == foo }),
            let bar = bar else {}

      while let foo = foo,
            let bar = bar {}
      """
    let output = """
      if
        let foo = foo,
        let bar = bar,
        foo == bar {}

      else if
        foo != bar,
        let quux = quux {}

      if let baz = baz {}

      guard
        baz.filter({ $0 == foo }),
        let bar = bar else {}

      while
        let foo = foo,
        let bar = bar {}
      """
    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
      exclude: [.wrapConditionalBodies]
    )
  }

  @Test func wrapConditionsBeforeFirstWhereShouldPreserveExisting() {
    let input = """
      else {}

      else
      {}

      if foo == bar
      {}

      guard let foo = bar else
      {}

      guard let foo = bar
      else {}
      """
    testFormatting(
      for: input, rule: .wrapArguments,
      options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
      exclude: [.elseOnSameLine, .wrapConditionalBodies, .blankLinesAfterGuardStatements]
    )
  }

  @Test func wrapConditionsAfterFirst() {
    let input = """
      if
        let foo = foo,
        let bar = bar,
        foo == bar {}

      else if
        foo != bar,
        let quux = quux {}

      else {}

      if let baz = baz {}

      guard
        baz.filter({ $0 == foo }),
        let bar = bar else {}

      while
        let foo = foo,
        let bar = bar {}
      """
    let output = """
      if let foo = foo,
         let bar = bar,
         foo == bar {}

      else if foo != bar,
              let quux = quux {}

      else {}

      if let baz = baz {}

      guard baz.filter({ $0 == foo }),
            let bar = bar else {}

      while let foo = foo,
            let bar = bar {}
      """
    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: FormatOptions(indent: "  ", wrapConditions: .afterFirst),
      exclude: [.wrapConditionalBodies]
    )
  }

  @Test func wrapConditionsAfterFirstWhenFirstLineIsComment() {
    let input = """
      guard
          // Apply this rule to any function-like declaration
          ["func", "init", "subscript"].contains(keyword.string),
          // Opaque generic parameter syntax is only supported in Swift 5.7+
          formatter.options.swiftVersion >= "5.7",
          // Validate that this is a generic method using angle bracket syntax,
          // and find the indices for all of the key tokens
          let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
          let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
          let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
          let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
          genericSignatureStartIndex < paramListStartIndex,
          genericSignatureEndIndex < paramListStartIndex,
          let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
          let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
      else { return }
      """
    let output = """
      guard // Apply this rule to any function-like declaration
          ["func", "init", "subscript"].contains(keyword.string),
          // Opaque generic parameter syntax is only supported in Swift 5.7+
          formatter.options.swiftVersion >= "5.7",
          // Validate that this is a generic method using angle bracket syntax,
          // and find the indices for all of the key tokens
          let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
          let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
          let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
          let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
          genericSignatureStartIndex < paramListStartIndex,
          genericSignatureEndIndex < paramListStartIndex,
          let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
          let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
      else { return }
      """
    testFormatting(
      for: input, [output], rules: [.wrapArguments, .indent],
      options: FormatOptions(wrapConditions: .afterFirst),
      exclude: [.wrapConditionalBodies]
    )
  }

  @Test func wrapPartiallyWrappedFunctionCall() {
    let input = """
      func foo(
          bar: Bar, baaz: Baaz,
          quux: Quux,
      ) {
          print(
              bar, baaz,
          )
      }
      """

    let output = """
      func foo(
          bar: Bar,
          baaz: Baaz,
          quux: Quux,
      ) {
          print(
              bar,
              baaz,
          )
      }
      """

    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false),
      exclude: [.unusedArguments, .trailingCommas])
  }

  @Test func wrapPartiallyWrappedFunctionCallTwoLines() {
    let input = """
      func foo(
          foo: Foo, bar: Bar,
          baaz: Baaz, quux: Quux
      ) {
          print(
              foo, bar,
              baaz, quux
          )
      }
      """

    let output = """
      func foo(
          foo: Foo,
          bar: Bar,
          baaz: Baaz,
          quux: Quux
      ) {
          print(
              foo,
              bar,
              baaz,
              quux
          )
      }
      """

    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false))
  }

  @Test func wrapPartiallyWrappedArray() {
    let input = """
      let foo = [
          foo, bar,
          baaz, quux,
      ]
      """

    let output = """
      let foo = [
          foo,
          bar,
          baaz,
          quux,
      ]
      """

    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false))
  }

  @Test func arrayWithBlankLine() {
    let input = """
      let foo = [
          foo,
          bar,

          baaz,
          quux,
      ]
      """

    testFormatting(
      for: input, rule: .wrapArguments,
      options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false))
  }

  @Test func partiallyWrappedArrayWithBlankLine() {
    let input = """
      let foo = [
          foo, bar,

          baaz, quux,
      ]
      """

    let output = """
      let foo = [
          foo,
          bar,

          baaz,
          quux,
      ]
      """

    testFormatting(
      for: input, output, rule: .wrapArguments,
      options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false))
  }

  @Test func wrapArgumentsBeforeFirstDoesntWrapClosingParenIfFirstArgumentNotWrapped() {
    let input = """
      return .tuple(string
          .split { $0.isNewline }
          .map { .string("\\($0)") })
      """

    testFormatting(
      for: input, rule: .wrapArguments,
      options: FormatOptions(
        wrapArguments: .beforeFirst, closingParenPosition: .balanced, maxWidth: 1000
      ))
  }
}
