import Testing

@testable import Swiftiomatic

@Suite struct WrapTests {
  @Test func wrapIfStatement() {
    let input = """
      if let foo = foo, let bar = bar, let baz = baz {}
      """
    let output = """
      if let foo = foo,
         let bar = bar,
         let baz = baz {}
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapIfElseStatement() {
    let input = """
      if let foo = foo {} else if let bar = bar {}
      """
    let output = """
      if let foo = foo {}
          else if let bar =
          bar {}
      """
    let output2 = """
      if let foo = foo {}
      else if let bar =
          bar {}
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
  }

  @Test func wrapGuardStatement() {
    let input = """
      guard let foo = foo, let bar = bar else {
          break
      }
      """
    let output = """
      guard let foo = foo,
            let bar = bar
            else {
          break
      }
      """
    let output2 = """
      guard let foo = foo,
            let bar = bar
      else {
          break
      }
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(
      for: input, [output, output2], rules: [.wrap], options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func wrapClosure() {
    let input = """
      let foo = { () -> Bool in true }
      """
    let output = """
      let foo =
          { () -> Bool in
          true }
      """
    let output2 = """
      let foo =
          { () -> Bool in
              true
          }
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
  }

  @Test func wrapClosure2() {
    let input = """
      let foo = { bar, _ in bar }
      """
    let output = """
      let foo =
          { bar, _ in
          bar }
      """
    let output2 = """
      let foo =
          { bar, _ in
              bar
          }
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
  }

  @Test func wrapClosureWithAllmanBraces() {
    let input = """
      let foo = { bar, _ in bar }
      """
    let output = """
      let foo =
          { bar, _ in
          bar }
      """
    let output2 = """
      let foo =
      { bar, _ in
          bar
      }
      """
    let options = FormatOptions(allmanBraces: true, maxWidth: 20)
    testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
  }

  @Test func wrapClosure3() {
    let input = """
      let foo = bar { $0.baz }
      """
    let output = """
      let foo = bar {
          $0.baz }
      """
    let output2 = """
      let foo = bar {
          $0.baz
      }
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidth() {
    let input = """
      @Test func func() -> ReturnType {
          doSomething()
          doSomething()
      }
      """
    let output = """
      @Test func func()
          -> ReturnType {
          doSomething()
          doSomething()
      }
      """
    let options = FormatOptions(maxWidth: 25)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidthWithXcodeIndentation() {
    let input = """
      @Test func func() -> ReturnType {
          doSomething()
          doSomething()
      }
      """
    let output = """
      @Test func func()
          -> ReturnType {
          doSomething()
          doSomething()
      }
      """
    let output2 = """
      @Test func func()
      -> ReturnType {
          doSomething()
          doSomething()
      }
      """
    let options = FormatOptions(xcodeIndentation: true, maxWidth: 25)
    testFormatting(
      for: input, [output, output2], rules: [.wrap], options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidth2() {
    let input = """
      @Test func func() -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let output = """
      @Test func func()
          -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let options = FormatOptions(maxWidth: 35)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidth2WithXcodeIndentation() {
    let input = """
      @Test func func() throws -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let output = """
      @Test func func() throws
          -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let output2 = """
      @Test func func() throws
      -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
    testFormatting(
      for: input, [output, output2], rules: [.wrap], options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidth2WithXcodeIndentation2() {
    let input = """
      @Test func func() throws(Foo) -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let output = """
      @Test func func() throws(Foo)
          -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let output2 = """
      @Test func func() throws(Foo)
      -> (ReturnType, ReturnType2) {
          doSomething()
      }
      """
    let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
    testFormatting(
      for: input, [output, output2], rules: [.wrap], options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidth3() {
    let input = """
      @Test func func() -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output = """
      @Test func func()
          -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let options = FormatOptions(maxWidth: 35)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test(.disabled("Wrap behavior differs from upstream SwiftFormat"))
  func wrapFunctionIfReturnTypeExceedsMaxWidth3WithXcodeIndentation() {
    let input = """
      @Test func func() -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output = """
      @Test func func()
          -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output2 = """
      @Test func func()
      -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
    testFormatting(
      for: input, [output, output2], rules: [.wrap], options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func wrapFunctionIfReturnTypeExceedsMaxWidth4() {
    let input = """
      func testFunc(_: () -> Void) -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output = """
      func testFunc(_: () -> Void)
          -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let options = FormatOptions(maxWidth: 35)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func wrapFunctionIfReturnTypeExceedsMaxWidth4WithXcodeIndentation() {
    let input = """
      func testFunc(_: () -> Void) -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output = """
      func testFunc(_: () -> Void)
          -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output2 = """
      func testFunc(_: () -> Void)
      -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
    testFormatting(
      for: input, [output, output2], rules: [.wrap], options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func wrapChainedFunctionAfterSubscriptCollection() {
    let input = """
      let foo = bar["baz"].quuz()
      """
    let output = """
      let foo = bar["baz"]
          .quuz()
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapChainedFunctionInSubscriptCollection() {
    let input = """
      let foo = bar[baz.quuz()]
      """
    let output = """
      let foo =
          bar[baz.quuz()]
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapThrowingFunctionIfReturnTypeExceedsMaxWidth() {
    let input = """
      func testFunc(_: () -> Void) throws -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output = """
      func testFunc(_: () -> Void) throws
          -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let options = FormatOptions(maxWidth: 42)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func wrapTypedThrowingFunctionIfReturnTypeExceedsMaxWidth() {
    let input = """
      func testFunc(_: () -> Void) throws(Foo) -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let output = """
      func testFunc(_: () -> Void) throws(Foo)
          -> (Bool, String) -> String? {
          doSomething()
      }
      """
    let options = FormatOptions(maxWidth: 42)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func noWrapInterpolatedStringLiteral() {
    let input = """
      "a very long \\(string) literal"
      """
    let options = FormatOptions(maxWidth: 20)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func noWrapAtUnspacedOperator() {
    let input = """
      let foo = bar+baz+quux
      """
    let output = """
      let foo =
          bar+baz+quux
      """
    let options = FormatOptions(maxWidth: 15)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.spaceAroundOperators],
    )
  }

  @Test func noWrapAtUnspacedEquals() {
    let input = """
      let foo=bar+baz+quux
      """
    let options = FormatOptions(maxWidth: 15)
    testFormatting(
      for: input, rule: .wrap, options: options,
      exclude: [.spaceAroundOperators],
    )
  }

  @Test func noWrapSingleParameter() {
    let input = """
      let fooBar = try unkeyedContainer.decode(FooBar.self)
      """
    let output = """
      let fooBar = try unkeyedContainer
          .decode(FooBar.self)
      """
    let options = FormatOptions(maxWidth: 50)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapSingleParameter() {
    let input = """
      let fooBar = try unkeyedContainer.decode(FooBar.self)
      """
    let output = """
      let fooBar = try unkeyedContainer.decode(
          FooBar.self
      )
      """
    let options = FormatOptions(maxWidth: 50, noWrapOperators: [".", "="])
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapFunctionArrow() {
    let input = """
      func foo() -> Int {}
      """
    let output = """
      func foo()
          -> Int {}
      """
    let options = FormatOptions(maxWidth: 14)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func noWrapFunctionArrow() {
    let input = """
      func foo() -> Int {}
      """
    let output = """
      func foo(
      ) -> Int {}
      """
    let options = FormatOptions(maxWidth: 14, noWrapOperators: ["->"])
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func noCrashWrap() {
    let input = """
      struct Foo {
          func bar(a: Set<B>, c: D) {}
      }
      """
    let output = """
      struct Foo {
          func bar(
              a: Set<
                  B
              >,
              c: D
          ) {}
      }
      """
    let options = FormatOptions(maxWidth: 10)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func noCrashWrap2() {
    let input = """
      struct Test {
          func webView(_: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
              authenticationChallengeProcessor.process(challenge: challenge, completionHandler: completionHandler)
          }
      }
      """
    let output = """
      struct Test {
          func webView(
              _: WKWebView,
              didReceive challenge: URLAuthenticationChallenge,
              completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                            URLCredential?) -> Void
          ) {
              authenticationChallengeProcessor.process(
                  challenge: challenge,
                  completionHandler: completionHandler
              )
          }
      }
      """
    let options = FormatOptions(wrapParameters: .preserve, maxWidth: 80)
    testFormatting(
      for: input, output, rule: .wrap, options: options,
      exclude: [.indent, .wrapArguments],
    )
  }

  @Test func wrapColorLiteral() {
    let input = """
      button.setTitleColor(#colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1), for: .normal)
      """
    let options = FormatOptions(maxWidth: 80, assetLiteralWidth: .visualWidth)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func wrapImageLiteral() {
    let input = """
      if let image = #imageLiteral(resourceName: \"abc.png\") {}
      """
    let options = FormatOptions(maxWidth: 40, assetLiteralWidth: .visualWidth)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func noWrapBeforeFirstArgumentInSingleLineStringInterpolation() {
    let input = """
      "a very long string literal with \\(interpolation) inside"
      """
    let options = FormatOptions(maxWidth: 40)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func wrapBeforeFirstArgumentInMultineStringInterpolation() {
    let input = """
      \"""
      a very long string literal with \\(interpolation) inside
      \"""
      """
    let output = """
      \"""
      a very long string literal with \\(
          interpolation
      ) inside
      \"""
      """
    let options = FormatOptions(maxWidth: 40)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func preserveMultiLineStringInterpolationWrapAfterFirst() {
    let input = """
      \"""
      a very long string literal with \\(interpolation) inside
      \"""
      """
    let options = FormatOptions(
      wrapArguments: .afterFirst, wrapStringInterpolation: .preserve, maxWidth: 40,
    )
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func preserveMultiLineStringInterpolationWrapBeforeFirst() {
    let input = """
      \"""
      a very long string literal with \\(interpolation) inside
      \"""
      """
    let options = FormatOptions(
      wrapArguments: .beforeFirst, wrapStringInterpolation: .preserve, maxWidth: 40,
    )
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func preserveCustomMultiLineStringInterpolationWrapBeforeFirst() {
    let input = #"""
      """
      \(raw: isPublic ? "public " : "")lazy var \(raw: name.trimmed.description): \(raw: typeName)<\(raw: genericName),\(returnType)> = {
      """
      """#
    let options = FormatOptions(
      wrapArguments: .beforeFirst, wrapStringInterpolation: .preserve, maxWidth: 40,
    )
    testFormatting(for: input, rule: .wrap, options: options)
  }

  // ternary expressions

  @Test func wrapSimpleTernaryOperator() {
    let input = """
      let foo = fooCondition ? longValueThatContainsFoo(bar) : longValueThatContainsBar(baaz)
      """

    let output = """
      let foo = fooCondition
          ? longValueThatContainsFoo(bar)
          : longValueThatContainsBar(baaz)
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 40)
    testFormatting(for: input, [output], rules: [.wrap, .wrapArguments], options: options)
  }

  @Test func rewrapsSimpleTernaryOperator() {
    let input = """
      let foo = fooCondition ? longValueThatContainsFoo(bar) :
          longValueThatContainsBar(baaz)
      """

    let output = """
      let foo = fooCondition
          ? longValueThatContainsFoo(bar)
          : longValueThatContainsBar(baaz)
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 40)
    testFormatting(for: input, [output], rules: [.wrap, .wrapArguments], options: options)
  }

  @Test func wrapComplexTernaryOperator() {
    let input = """
      let foo = fooCondition ? Foo(property: value) : barContainer.getBar(using: barProvider)
      """

    let output = """
      let foo = fooCondition
          ? Foo(property: value)
          : barContainer.getBar(using: barProvider)
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func rewrapsComplexTernaryOperator() {
    let input = """
      let foo = fooCondition ? Foo(property: value) :
          barContainer.getBar(using: barProvider)
      """

    let output = """
      let foo = fooCondition
          ? Foo(property: value)
          : barContainer.getBar(using: barProvider)
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapsSimpleNestedTernaryOperator() {
    let input = """
      let foo = fooCondition ? (barCondition ? a : b) : (baazCondition ? c : d)
      """

    let output = """
      let foo = fooCondition
          ? (barCondition ? a : b)
          : (baazCondition ? c : d)
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapsDoubleNestedTernaryOperation() {
    let input = """
      let foo = fooCondition ? barCondition ? longTrueBarResult : longFalseBarResult : baazCondition ? longTrueBaazResult : longFalseBaazResult
      """

    let output = """
      let foo = fooCondition
          ? barCondition
              ? longTrueBarResult
              : longFalseBarResult
          : baazCondition
              ? longTrueBaazResult
              : longFalseBaazResult
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func wrapsTripleNestedTernaryOperation() {
    let input = """
      let foo = fooCondition ? barCondition ? quuxCondition ? longTrueQuuxResult : longFalseQuuxResult : barCondition2 ? longTrueBarResult : longFalseBarResult : baazCondition ? longTrueBaazResult : longFalseBaazResult
      """

    let output = """
      let foo = fooCondition
          ? barCondition
              ? quuxCondition
                  ? longTrueQuuxResult
                  : longFalseQuuxResult
              : barCondition2
                  ? longTrueBarResult
                  : longFalseBarResult
          : baazCondition
              ? longTrueBaazResult
              : longFalseBaazResult
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func noWrapTernaryWrappedWithinChildExpression() {
    let input = """
      func foo() {
          return _skipString(string) ? .token(
              string, Location(source: input, range: startIndex ..< index)
          ) : nil
      }
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 0)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func noWrapTernaryWrappedWithinChildExpression2() {
    let input = """
      let types: [PolygonType] = plane.isEqual(to: plane) ? [] : vertices.map {
          let t = plane.normal.dot($0.position) - plane.w
          let type: PolygonType = (t < -epsilon) ? .back : (t > epsilon) ? .front : .coplanar
          polygonType = PolygonType(rawValue: polygonType.rawValue | type.rawValue)!
          return type
      }
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 0)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func noWrapTernaryInsideStringLiteral() {
    let input = """
      "\\(true ? "Some string literal" : "Some other string")"
      """
    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 50)
    testFormatting(for: input, rule: .wrap, options: options)
  }

  @Test func wrapTernaryInsideMultilineStringLiteral() {
    let input = """
      let foo = \"""
      \\(true ? "Some string literal" : "Some other string")"
      \"""
      """
    let output = """
      let foo = \"""
      \\(true
          ? "Some string literal"
          : "Some other string")"
      \"""
      """
    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 50)
    testFormatting(for: input, output, rule: .wrap, options: options)
  }

  @Test func noCrashWrap3() throws {
    let input = """
      override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
          let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
          context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
          return context
      }
      """
    let options = FormatOptions(wrapArguments: .afterFirst, maxWidth: 100)
    let rules: [FormatRule] = [.wrap, .wrapArguments]
    _ = try format(input, rules: rules, options: options)
  }

  @Test func errorNotReportedOnBlankLineAfterWrap() throws {
    let input = """
      [
          abagdiasiudbaisndoanosdasdasdasdasdnaosnooanso(),

          bar(),
      ]
      """
    let options = FormatOptions(truncateBlankLines: false, maxWidth: 40)
    let changes = try lint(input, rules: [.wrap, .indent], options: options)
    #expect(changes == [.init(line: 2, rule: .wrap, filePath: nil, isMove: false)])
  }

  @Test func noReportIndentAsWrap() throws {
    let input = """
      let package = Package(
          name: "ExampleApp",
          products: [
              .executable(
                  name: "ExampleApp",
                  targets: ["ExampleApp"]
              ),
          ],
          dependencies: [
              .package(url: "https://example.com/package.swift", from: "1.0"),
              // Plugins:
              .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.5"),
           ]
      )
      """
    let options = FormatOptions(truncateBlankLines: false, maxWidth: 120)
    let changes = try lint(input, rules: [.wrap, .indent], options: options)
    #expect(changes == [.init(line: 13, rule: .indent, filePath: nil, isMove: false)])
  }

  @Test func keepTrailingCommentWithLine() {
    // https://github.com/nicklockwood/SwiftFormat/issues/2261
    let input = """
      [
          item1, // Comment 1
          item2, // Comment 2
          item3 // Comment 3
      ]
      """

    let options = FormatOptions(maxWidth: 20)
    testFormatting(
      for: input, rule: .wrap, options: options,
      exclude: [.trailingCommas, .wrapSingleLineComments],
    )
  }

  @Test func keepTrailingCommentWithLine2() {
    let input = """
      [
          item1, // Comment 1
          item2, // Comment 2
          item3 // Comment 3
      ]
      """

    let output = """
      [
          item1, // Comment
          // 1
          item2, // Comment
          // 2
          item3 // Comment
          // 3
      ]
      """

    testFormatting(
      for: input, [output],
      rules: [.wrap, .wrapSingleLineComments],
      options: FormatOptions(maxWidth: 20),
      exclude: [.trailingCommas],
    )
  }
}
