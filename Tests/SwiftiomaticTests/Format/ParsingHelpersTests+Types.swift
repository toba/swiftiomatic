import Testing

@testable import Swiftiomatic

extension ParsingHelpersTests {
  // MARK: - parseTypes

  @Test func parseSimpleType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo = .init()
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo")
  }

  @Test func parseOptionalType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo??? = .init()
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo???")
  }

  @Test func parseIOUType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo!! = .init()
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo!!")
  }

  @Test func doesNotParseTernaryOperatorAsType() {
    let formatter = Formatter(
      tokenize(
        """
        Foo.bar ? .foo : .bar
        """,
      ),
    )
    #expect(formatter.parseType(at: 0)?.string == "Foo.bar")
  }

  @Test func doesNotParseMacroInvocationAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = #colorLiteral(1, 2, 3)
        """,
      ),
    )
    #expect(formatter.parseType(at: 6) == nil)
  }

  @Test func doesNotParseSelectorAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = #selector(Foo.bar)
        """,
      ),
    )
    #expect(formatter.parseType(at: 6) == nil)
  }

  @Test func doesNotParseArrayAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = [foo, bar].member()
        """,
      ),
    )
    #expect(formatter.parseType(at: 6) == nil)
  }

  @Test func doesNotParseDictionaryAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = [foo: bar, baaz: quux].member()
        """,
      ),
    )
    #expect(formatter.parseType(at: 6) == nil)
  }

  @Test func parsesArrayAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = [Foo]()
        """,
      ),
    )
    #expect(formatter.parseType(at: 6)?.string == "[Foo]")
  }

  @Test func parsesDictionaryAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = [Foo: Bar]()
        """,
      ),
    )
    #expect(formatter.parseType(at: 6)?.string == "[Foo: Bar]")
  }

  @Test func parseGenericType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo<Bar, Baaz> = .init()
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo<Bar, Baaz>")
  }

  @Test func parseOptionalGenericType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo<Bar, Baaz>? = .init()
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo<Bar, Baaz>?")
  }

  @Test func parseDictionaryType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: [Foo: Bar] = [:]
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "[Foo: Bar]")
  }

  @Test func parseOptionalDictionaryType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: [Foo: Bar]? = [:]
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "[Foo: Bar]?")
  }

  @Test func parseTupleType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) = (Foo(), Bar())
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar)")
  }

  @Test func parseClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) -> (Foo, Bar) = { foo, bar in (foo, bar) }
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) -> (Foo, Bar)")
  }

  @Test func parseThrowingClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) throws -> Void
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) throws -> Void")
  }

  @Test func parseTypedThrowingClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) throws(MyFeatureError) -> Void
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) throws(MyFeatureError) -> Void")
  }

  @Test func parseAsyncClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) async -> Void
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) async -> Void")
  }

  @Test func parseAsyncThrowsClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) async throws -> Void
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) async throws -> Void")
  }

  @Test func parseTypedAsyncThrowsClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) async throws(MyCustomError) -> Void
        """,
      ),
    )
    #expect(
      formatter.parseType(at: 5)?
        .string == "(Foo, Bar) async throws(MyCustomError) -> Void")
  }

  @Test func parseClosureTypeWithOwnership() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (consuming Foo, borrowing Bar) -> (Foo, Bar) = { foo, bar in (foo, bar) }
        """,
      ),
    )
    #expect(
      formatter.parseType(at: 5)?
        .string == "(consuming Foo, borrowing Bar) -> (Foo, Bar)")
  }

  @Test func parseOptionalReturningClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (Foo, Bar) -> (Foo, Bar)? = { foo, bar in (foo, bar) }
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) -> (Foo, Bar)?")
  }

  @Test func parseOptionalClosureType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: ((Foo, Bar) -> (Foo, Bar)?)? = { foo, bar in (foo, bar) }
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "((Foo, Bar) -> (Foo, Bar)?)?")
  }

  @Test func parseOptionalClosureTypeWithOwnership() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: ((consuming Foo, borrowing Bar) -> (Foo, Bar)?)? = { foo, bar in (foo, bar) }
        """,
      ),
    )
    #expect(
      formatter.parseType(at: 5)?
        .string == "((consuming Foo, borrowing Bar) -> (Foo, Bar)?)?",
    )
  }

  @Test func parseExistentialAny() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: any Foo
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "any Foo")
  }

  @Test func parseCompoundType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo.Bar.Baaz
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo.Bar.Baaz")
  }

  @Test func doesNotParseLeadingDotAsType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo = .Bar.baaz
        """,
      ),
    )
    #expect(formatter.parseType(at: 9)?.string == nil)
  }

  @Test func parseCompoundGenericType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: Foo<Bar>.Bar.Baaz<Quux.V2>
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "Foo<Bar>.Bar.Baaz<Quux.V2>")
  }

  @Test func parseExistentialTypeWithSubtype() {
    let formatter = Formatter(
      tokenize(
        """
        let foo: (any Foo).Bar.Baaz
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "(any Foo).Bar.Baaz")
  }

  @Test func parseOpaqueReturnType() {
    let formatter = Formatter(
      tokenize(
        """
        var body: some View { EmptyView() }
        """,
      ),
    )
    #expect(formatter.parseType(at: 5)?.string == "some View")
  }

  @Test func parameterPackTypes() {
    let formatter = Formatter(
      tokenize(
        """
        func foo<each T>() -> repeat each T {
          return repeat each T.self
        }

        func eachFirst<each T: Collection>(_ item: repeat each T) -> (repeat (each T).Element?) {
            return (repeat (each item).first)
        }
        """,
      ),
    )
    #expect(formatter.parseType(at: 4)?.string == "each T")
    #expect(formatter.parseType(at: 13)?.string == "repeat each T")
    #expect(formatter.parseType(at: 62)?.string == "repeat (each T).Element?")
  }

  @Test func parseInvalidType() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = { foo, bar in (foo, bar) }
        """,
      ),
    )
    #expect(formatter.parseType(at: 4)?.string == nil)
    #expect(formatter.parseType(at: 5)?.string == nil)
    #expect(formatter.parseType(at: 6)?.string == nil)
    #expect(formatter.parseType(at: 7)?.string == nil)
  }

  @Test func multilineType() {
    let formatter = Formatter(
      tokenize(
        """
        extension Foo.Bar
            .Baaz.Quux
            .InnerType1
            .InnerType2
        { }
        """,
      ),
    )

    #expect(formatter.parseType(at: 2)?.string == "Foo.Bar.Baaz.Quux.InnerType1.InnerType2")
  }

  @Test func parseTuples() {
    let input = """
      let tuple: (foo: Foo, bar: Bar)
      let closure: (foo: Foo, bar: Bar) -> Void
      let valueWithRedundantParens: (Foo)
      let voidValue: ()
      let tupleWithComments: (
          bar: String, // comment A
          quux: String // comment B
      )  // Trailing comment
      """

    let formatter = Formatter(tokenize(input))

    #expect(formatter.parseType(at: 5)?.string == "(foo: Foo, bar: Bar)")
    #expect(formatter.parseType(at: 5)?.isTuple == true)

    #expect(formatter.parseType(at: 23)?.string == "(foo: Foo, bar: Bar) -> Void")
    #expect(formatter.parseType(at: 23)?.isTuple == false)

    #expect(formatter.parseType(at: 45)?.string == "(Foo)")
    #expect(formatter.parseType(at: 45)?.isTuple == false)

    #expect(formatter.parseType(at: 54)?.string == "()")
    #expect(formatter.parseType(at: 54)?.isTuple == false)

    #expect(formatter.parseType(at: 62)?.isTuple == true)
    #expect(formatter.parseType(at: 62)?.string == "(bar: String,  quux: String  )")
  }

  // MARK: - parseExpressionRange

  @Test func parseIndividualExpressions() {
    #expect(isSingleExpression(#"Foo()"#))
    #expect(isSingleExpression(#"Foo("bar")"#))
    #expect(isSingleExpression(#"Foo.init()"#))
    #expect(isSingleExpression(#"Foo.init("bar")"#))
    #expect(isSingleExpression(#"foo.bar"#))
    #expect(isSingleExpression(#"foo .bar"#))
    #expect(isSingleExpression(#"foo["bar"]("baaz")"#))
    #expect(isSingleExpression(#"foo().bar().baaz[]().bar"#))
    #expect(isSingleExpression(#"foo?.bar?().baaz!.quux ?? """#))
    #expect(isSingleExpression(#"1"#))
    #expect(isSingleExpression(#"10.0"#))
    #expect(isSingleExpression(#"10000"#))
    #expect(isSingleExpression(#"-24.0"#))
    #expect(isSingleExpression(#"3.14e2"#))
    #expect(isSingleExpression(#"1 + 2"#))
    #expect(isSingleExpression(#"-0.05 * 10"#))
    #expect(isSingleExpression(#"0...10"#))
    #expect(isSingleExpression(#"0..<20"#))
    #expect(isSingleExpression(#"0 ... array.indices.last"#))
    #expect(isSingleExpression(#"true"#))
    #expect(isSingleExpression(#"false"#))
    #expect(isSingleExpression(#"!boolean"#))
    #expect(isSingleExpression(#"boolean || !boolean && boolean"#))
    #expect(isSingleExpression(#"boolean ? value : value"#))
    #expect(isSingleExpression(#"foo"#))
    #expect(isSingleExpression(#""foo""#))
    #expect(isSingleExpression(##"#"raw string"#"##))
    #expect(isSingleExpression(###"##"raw string"##"###))
    #expect(isSingleExpression(#"["foo", "bar"]"#))
    #expect(isSingleExpression(#"["foo": bar]"#))
    #expect(isSingleExpression(#"(tuple: "foo", bar: "baaz")"#))
    #expect(isSingleExpression(#"foo.bar { "baaz"}"#))
    #expect(isSingleExpression(#"foo.bar({ "baaz" })"#))
    #expect(isSingleExpression(#"foo.bar() { "baaz" }"#))
    #expect(isSingleExpression(#"foo.bar { "baaz" } anotherTrailingClosure: { "quux" }"#))
    #expect(isSingleExpression(#"try foo()"#))
    #expect(isSingleExpression(#"try! foo()"#))
    #expect(isSingleExpression(#"try? foo()"#))
    #expect(isSingleExpression(#"try await foo()"#))
    #expect(isSingleExpression(#"foo is Foo"#))
    #expect(isSingleExpression(#"foo as Foo"#))
    #expect(isSingleExpression(#"foo as? Foo"#))
    #expect(isSingleExpression(#"foo as! Foo"#))
    #expect(isSingleExpression(#"foo ? bar : baaz"#))
    #expect(isSingleExpression(#".implicitMember"#))
    #expect(isSingleExpression(#"\Foo.explicitKeypath"#))
    #expect(isSingleExpression(#"\.inferredKeypath"#))
    #expect(isSingleExpression(#"#selector(Foo.bar)"#))
    #expect(isSingleExpression(#"#macro()"#))
    #expect(isSingleExpression(#"#outerMacro(12, #innerMacro(34), "some text")"#))
    #expect(isSingleExpression(#"try { try printThrows(foo) }()"#))
    #expect(isSingleExpression(#"try! { try printThrows(foo) }()"#))
    #expect(isSingleExpression(#"try? { try printThrows(foo) }()"#))
    #expect(isSingleExpression(#"await { await printAsync(foo) }()"#))
    #expect(isSingleExpression(#"try await { try await printAsyncThrows(foo) }()"#))
    #expect(isSingleExpression(#"Foo<Bar>()"#))
    #expect(isSingleExpression(#"each foo"#))
    #expect(isSingleExpression(#"repeat each foo.var.baaz"#))
    #expect(isSingleExpression(#"repeat (each item).first"#))
    #expect(isSingleExpression(#"Foo<Bar, Baaz>(quux: quux)"#))
    #expect(!isSingleExpression(#"if foo { "foo" } else { "bar" }"#))
    #expect(!isSingleExpression(#"foo.bar, baaz.quux"#))

    #expect(
      isSingleExpression(
        #"if foo { "foo" } else { "bar" }"#,
        allowConditionalExpressions: true,
      ),
    )

    #expect(
      isSingleExpression(
        """
        if foo {
          "foo"
        } else {
          "bar"
        }
        """, allowConditionalExpressions: true,
      ),
    )

    #expect(
      isSingleExpression(
        """
        switch foo {
        case true:
            "foo"
        case false:
            "bar"
        }
        """, allowConditionalExpressions: true,
      ),
    )

    #expect(
      isSingleExpression(
        """
        foo
            .bar
        """,
      ),
    )

    #expect(
      isSingleExpression(
        """
        foo?
            .bar?()
            .baaz![0]
        """,
      ),
    )

    #expect(
      isSingleExpression(
        #"""
        """
        multi-line string
        """
        """#,
      ),
    )

    #expect(
      isSingleExpression(
        ##"""
        #"""
        raw multi-line string
        """#
        """##,
      ),
    )

    #expect(!isSingleExpression(#"foo = bar"#))
    #expect(!isSingleExpression(#"foo = "foo"#))
    #expect(!isSingleExpression(#"10 20 30"#))
    #expect(!isSingleExpression(#"foo bar"#))
    #expect(!isSingleExpression(#"foo? bar"#))

    #expect(
      !isSingleExpression(
        """
        foo
            () // if you have a linebreak before a method call, its parsed as a tuple
        """,
      ),
    )

    #expect(
      !isSingleExpression(
        """
        foo
            [0] // if you have a linebreak before a subscript, its invalid
        """,
      ),
    )

    #expect(
      !isSingleExpression(
        """
        #if DEBUG
        foo
        #else
        bar
        #endif
        """,
      ),
    )
  }

  @Test func parseMultipleSingleLineExpressions() {
    let input = """
      foo
      foo?.bar().baaz()
      24
      !foo
      methodCall()
      foo ?? bar ?? baaz
      """

    // Each line is a single expression
    let expectedExpressions = input.components(separatedBy: "\n")
    #expect(parseExpressions(input) == expectedExpressions)
  }

  @Test func parseMultipleLineExpressions() {
    let input = """
      [
          "foo",
          "bar"
      ].map {
          $0.uppercased()
      }

      foo?.bar().methodCall(
          foo: foo,
          bar: bar)

      foo.multipleTrailingClosure {
          print("foo")
      } anotherTrailingClosure: {
          print("bar")
      }
      """

    let expectedExpressions = [
      """
      [
          "foo",
          "bar"
      ].map {
          $0.uppercased()
      }
      """,
      """
      foo?.bar().methodCall(
          foo: foo,
          bar: bar)
      """,
      """
      foo.multipleTrailingClosure {
          print("foo")
      } anotherTrailingClosure: {
          print("bar")
      }
      """,
    ]

    #expect(parseExpressions(input) == expectedExpressions)
  }

  @Test func parsedExpressionInIfConditionExcludesConditionBody() {
    let input = """
      if let bar = foo.bar {
        print(bar)
      }

      if foo.contains(where: { $0.isEmpty }) {
        print("Empty foo")
      }
      """

    #expect(parseExpression(in: input, at: 8) == "foo.bar")
    #expect(parseExpression(in: input, at: 25) == "foo.contains(where: { $0.isEmpty })")
  }

  @Test func parsedExpressionInIfConditionExcludesConditionBody_trailingClosureEdgeCase() {
    // This code is generally considered an anti-pattern, and outputs the following warning when compiled:
    // warning: trailing closure in this context is confusable with the body of the statement; pass as a parenthesized argument to silence this warning
    let input = """
      if foo.contains { $0.isEmpty } {
        print("Empty foo")
      }
      """

    // We don't bother supporting this, since it would increase the complexity of the parser.
    // A more correct result would be `foo.contains { $0.isEmpty }`.
    #expect(parseExpression(in: input, at: 2) == "foo.contains")
  }

  func isSingleExpression(_ string: String, allowConditionalExpressions: Bool = false) -> Bool {
    let formatter = Formatter(tokenize(string))
    guard
      let expressionRange = formatter.parseExpressionRange(
        startingAt: 0, allowConditionalExpressions: allowConditionalExpressions,
      )
    else { return false }
    return expressionRange.upperBound == formatter.tokens.indices.last!
  }

  func parseExpressions(_ string: String) -> [String] {
    let formatter = Formatter(tokenize(string))
    var expressions = [String]()

    var parseIndex = 0
    while let expressionRange = formatter.parseExpressionRange(startingAt: parseIndex) {
      let expression = formatter.tokens[expressionRange].map(\.string).joined()
      expressions.append(expression)

      if let nextExpressionIndex = formatter.index(
        of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound,
      ) {
        parseIndex = nextExpressionIndex
      } else {
        return expressions
      }
    }

    return expressions
  }

  func parseExpression(in input: String, at index: Int) -> String {
    let formatter = Formatter(tokenize(input))
    guard let expressionRange = formatter.parseExpressionRange(startingAt: index)
    else { return "" }
    return formatter.tokens[expressionRange].map(\.string).joined()
  }

}
