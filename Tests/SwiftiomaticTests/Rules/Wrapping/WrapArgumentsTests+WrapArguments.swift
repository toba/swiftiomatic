import Testing

@testable import Swiftiomatic

extension WrapArgumentsTests {
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
      exclude: [.unusedArguments, .wrap],
    )
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
      exclude: [.trailingClosures],
    )
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
      options: options, exclude: [.wrapConditionalBodies],
    )
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
      exclude: [.redundantParens],
    )
  }

  // MARK: beforeFirst, maxWidth : string interpolation

  @Test func noWrapBeforeFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(interpolation) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 40,
    )
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeFirstArgumentInStringInterpolation2() {
    let input = """
      "a very long string literal with \\(interpolation) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 50,
    )
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeFirstArgumentInStringInterpolation3() {
    let input = """
      "a very long string literal with \\(interpolated, variables) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 40,
    )
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeNestedFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(foo(interpolated)) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 45,
    )
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapBeforeNestedFirstArgumentInStringInterpolation2() {
    let input = """
      "a very long string literal with \\(foo(interpolated, variables)) inside"
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      wrapParameters: .beforeFirst,
      maxWidth: 45,
    )
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
      options: options,
    )
  }

  // MARK: afterFirst maxWidth : string interpolation

  @Test func noWrapAfterFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(interpolated) inside"
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapParameters: .afterFirst,
      maxWidth: 46,
    )
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapAfterFirstArgumentInStringInterpolation2() {
    let input = """
      "a very long string literal with \\(interpolated, variables) inside"
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapParameters: .afterFirst,
      maxWidth: 50,
    )
    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func noWrapAfterNestedFirstArgumentInStringInterpolation() {
    let input = """
      "a very long string literal with \\(foo(interpolated, variables)) inside"
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst,
      wrapParameters: .afterFirst,
      maxWidth: 55,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      rules: [.wrap, .wrapArguments], options: options,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      options: options,
    )
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
      maxWidth: 26,
    )
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments], options: options,
    )
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
      maxWidth: 26,
    )
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments], options: options,
    )
  }

}
