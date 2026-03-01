import Testing

@testable import Swiftiomatic

extension ParsingHelpersTests {
  // MARK: parseExpressionRange(endingAt:)

  @Test func parseExpressionEndingAt() {
    // Simple cases
    #expect(isSingleExpressionParsedFromEnd("foo"))
    #expect(isSingleExpressionParsedFromEnd("42"))

    // Postfix operators
    #expect(isSingleExpressionParsedFromEnd("foo!"))
    #expect(isSingleExpressionParsedFromEnd("foo?"))

    // Method calls and subscripts
    #expect(isSingleExpressionParsedFromEnd("foo.bar()"))
    #expect(isSingleExpressionParsedFromEnd("foo[0]"))

    // Prefix operators and keywords
    #expect(isSingleExpressionParsedFromEnd("!foo"))
    #expect(isSingleExpressionParsedFromEnd("try foo()"))
    #expect(isSingleExpressionParsedFromEnd("await foo()"))

    // Infix operators
    #expect(isSingleExpressionParsedFromEnd("foo + bar"))
    #expect(isSingleExpressionParsedFromEnd("foo * bar + baz"))
    #expect(isSingleExpressionParsedFromEnd("foo == bar.baaz"))
    #expect(isSingleExpressionParsedFromEnd("foo == .baaz"))
    #expect(isSingleExpressionParsedFromEnd("foo == !baaz"))
    #expect(isSingleExpressionParsedFromEnd("0 == -baaz"))

    // Type operators
    #expect(isSingleExpressionParsedFromEnd("foo as String"))
    #expect(isSingleExpressionParsedFromEnd("foo as! String"))
    #expect(isSingleExpressionParsedFromEnd("foo as? String"))
    #expect(isSingleExpressionParsedFromEnd("foo is String"))

    // Complex expressions with operators in the middle
    #expect(isSingleExpressionParsedFromEnd("foo!.bar"))
    #expect(isSingleExpressionParsedFromEnd("foo?[bar]?.baaz"))
    #expect(isSingleExpressionParsedFromEnd("foo!.bar + baz"))
    #expect(isSingleExpressionParsedFromEnd("obj.foo!.bar().baz"))
    #expect(isSingleExpressionParsedFromEnd("foo!.bar as String"))
    #expect(isSingleExpressionParsedFromEnd("try foo!.bar()"))
    #expect(isSingleExpressionParsedFromEnd("await foo!.bar()"))
    #expect(isSingleExpressionParsedFromEnd("try! foo.bar"))
    #expect(isSingleExpressionParsedFromEnd("try? foo()"))

    // Closures and literals
    #expect(isSingleExpressionParsedFromEnd("{ foo }"))
    #expect(isSingleExpressionParsedFromEnd("[1, 2, 3]"))
  }

  func isSingleExpressionParsedFromEnd(_ input: String) -> Bool {
    let formatter = Formatter(tokenize(input))
    let lastTokenIndex = formatter.tokens.count - 1
    guard let expressionRange = formatter.parseExpressionRange(endingAt: lastTokenIndex) else {
      return false
    }
    return formatter.tokens[expressionRange].string == input
  }

  // MARK: parseExpressionRange(containing:)

  @Test func parseExpressionRangeContaining() {
    // Simple cases
    #expect(parseExpression(in: "foo!", containing: "!") == "foo!")

    // Force unwrap in different contexts
    #expect(parseExpression(in: "foo(bar: foo!.bar)", containing: "!") == "foo!.bar")
    #expect(parseExpression(in: "let foo = foo!.bar + baz", containing: "!") == "foo!.bar + baz")
    #expect(parseExpression(in: "if foo, foo!.bar == quux", containing: "!") == "foo!.bar == quux")
    #expect(parseExpression(in: "[foo!.bar, baz]", containing: "!") == "foo!.bar")
    #expect(parseExpression(in: "(foo!.bar, baz)", containing: "!") == "foo!.bar")
    #expect(parseExpression(in: "return foo!.bar + baz", containing: "!") == "foo!.bar + baz")
    #expect(parseExpression(in: "return foo[bar]!.baaz", containing: "!") == "foo[bar]!.baaz")
    #expect(parseExpression(in: "array[foo!.bar]", containing: "!") == "foo!.bar")
    #expect(parseExpression(in: "{ foo!.bar }", containing: "!") == "foo!.bar")
    #expect(parseExpression(in: "foo as! Foo", containing: "!") == "foo as! Foo")
    #expect(parseExpression(in: "foo! + \"suffix\"", containing: "!") == "foo! + \"suffix\"")
    #expect(
      parseExpression(in: "foo(\"test\".data(using: .utf8)!)", containing: "!")
        == "\"test\".data(using: .utf8)!",
    )

    // Multiple force unwraps
    #expect(parseExpression(in: "foo!.bar! + baz", containing: "!") == "foo!.bar! + baz")

    // Force unwrap in method chains
    #expect(parseExpression(in: "obj.foo!.bar().baz", containing: "!") == "obj.foo!.bar().baz")

    // Force unwrap with prefix operators
    #expect(parseExpression(in: "try foo!.bar()", containing: "!") == "try foo!.bar()")
    #expect(parseExpression(in: "await foo!.bar()", containing: "!") == "await foo!.bar()")

    // Force unwrap with type operators
    #expect(parseExpression(in: "foo!.bar as! String", containing: "!") == "foo!.bar as! String")

    #expect(
      parseExpression(
        in: #"XCTAssertEqual(route.query as! [String: String], ["a": "b"])"#,
        containing: "!",
      )
        == "route.query as! [String: String]",
    )
  }

  func parseExpression(in expression: String, containing: String) -> String? {
    let formatter = Formatter(tokenize(expression))
    guard let tokenIndex = formatter.tokens.firstIndex(where: { $0.string == containing }),
      let range = formatter.parseExpressionRange(containing: tokenIndex)
    else {
      return nil
    }
    return formatter.tokens[range].string
  }

  // MARK: isStoredProperty

  @Test func isStoredProperty() {
    #expect(isStoredProperty("var foo: String"))
    #expect(isStoredProperty("let foo = 42"))
    #expect(isStoredProperty("let foo: Int = 42"))
    #expect(isStoredProperty("var foo: Int = 42"))
    #expect(isStoredProperty("@Environment(\\.myEnvironmentProperty) var foo", at: 7))

    #expect(
      isStoredProperty(
        """
        var foo: String {
          didSet {
            print(newValue)
          }
        }
        """,
      ),
    )

    #expect(
      isStoredProperty(
        """
        var foo: String {
          willSet {
            print(newValue)
          }
        }
        """,
      ),
    )

    #expect(
      !isStoredProperty(
        """
        var foo: String {
            "foo"
        }
        """,
      ),
    )

    #expect(
      !isStoredProperty(
        """
        var foo: String {
            get { "foo" }
            set { print(newValue) }
        }
        """,
      ),
    )
  }

  func isStoredProperty(_ input: String, at index: Int = 0) -> Bool {
    let formatter = Formatter(tokenize(input))
    return formatter.isStoredProperty(atIntroducerIndex: index)
  }

  // MARK: scopeType

  @Test func scopeTypeForArrayExtension() {
    let input = "extension [Int] {}"
    let formatter = Formatter(tokenize(input))
    #expect(formatter.scopeType(at: 2) == .arrayType)
  }

  // MARK: parseFunctionDeclarationArgumentLabels

  @Test func parseFunctionDeclarationArguments() {
    let input = """
      func foo(_ foo: Foo, bar: Bar, quux _: Quux, last baaz: Baaz) {}
      func bar() {}
      """

    let formatter = Formatter(tokenize(input))

    let arguments = formatter.parseFunctionDeclarationArguments(startOfScope: 3)  // foo(...)

    #expect(arguments.count == 4)

    // First argument: _ foo: Foo
    #expect(arguments[0].externalLabel == nil)
    #expect(arguments[0].internalLabel == "foo")
    #expect(arguments[0].externalLabelIndex == 4)
    #expect(arguments[0].internalLabelIndex == 6)
    #expect(arguments[0].type.string == "Foo")

    // Second argument: bar: Bar
    #expect(arguments[1].externalLabel == "bar")
    #expect(arguments[1].internalLabel == "bar")
    #expect(arguments[1].externalLabelIndex == nil)
    #expect(arguments[1].internalLabelIndex == 12)
    #expect(arguments[1].type.string == "Bar")

    // Third argument: quux _: Quux
    #expect(arguments[2].externalLabel == "quux")
    #expect(arguments[2].internalLabel == nil)
    #expect(arguments[2].externalLabelIndex == 18)
    #expect(arguments[2].internalLabelIndex == 20)
    #expect(arguments[2].type.string == "Quux")

    // Fourth argument: last baaz: Baaz
    #expect(arguments[3].externalLabel == "last")
    #expect(arguments[3].internalLabel == "baaz")
    #expect(arguments[3].externalLabelIndex == 26)
    #expect(arguments[3].internalLabelIndex == 28)
    #expect(arguments[3].type.string == "Baaz")

    #expect(
      formatter.parseFunctionDeclarationArguments(startOfScope: 40)  // bar()
        == [],
    )
  }

  @Test func parseFunctionCallArgumentLabels() {
    let input = """
      foo(Foo(foo: foo), bar: Bar(bar), foo, quux: Quux(), last: Baaz(foo: foo))

      print(formatter.isOperator(at: 0))
      """

    let formatter = Formatter(tokenize(input))
    #expect(
      formatter.parseFunctionCallArguments(startOfScope: 1).map(\.label)  // foo(...)
        == [nil, "bar", nil, "quux", "last"],
    )

    #expect(
      formatter.parseFunctionCallArguments(startOfScope: 3).map(\.label)  // Foo(...)
        == ["foo"],
    )

    #expect(
      formatter.parseFunctionCallArguments(startOfScope: 15).map(\.label)  // Bar(...)
        == [nil],
    )

    #expect(
      formatter.parseFunctionCallArguments(startOfScope: 27).map(\.label)  // Quux()
        == [],
    )

    #expect(
      formatter.parseFunctionCallArguments(startOfScope: 49).map(\.label)  // isOperator(...)
        == ["at"],
    )
  }

  @Test func parseFunctionDeclarationWithEffects() throws {
    let input = """
      struct FooBar {

          func foo(bar: Bar, baaz: Baaz) async throws(GenericError<Foo>) -> Foo<Bar, Baaz> {
              Foo(bar: bar, baaz: baaz)
          }

      }
      """

    let formatter = Formatter(tokenize(input))
    let function = try #require(formatter.parseFunctionDeclaration(keywordIndex: 8))

    #expect(function.keywordIndex == 8)
    #expect(function.name == "foo")
    #expect(function.genericParameterRange == nil)
    #expect(formatter.tokens[function.argumentsRange].string == "(bar: Bar, baaz: Baaz)")
    #expect(function.arguments.count == 2)
    #expect(
      try formatter.tokens[#require(function.effectsRange)].string
        == "async throws(GenericError<Foo>)",
    )
    #expect(function.effects == ["async", "throws(GenericError<Foo>)"])
    #expect(function.returnOperatorIndex == 34)
    #expect(
      try formatter.tokens[#require(function.returnType?.range)]
        .string == "Foo<Bar, Baaz>")
    #expect(function.whereClauseRange == nil)
    #expect(
      try formatter.tokens[#require(function.bodyRange)].string == """
        {
                Foo(bar: bar, baaz: baaz)
            }
        """,
    )
  }

  @Test func parseFunctionDeclarationWithGeneric() throws {
    let input = """
      public func genericFoo<Bar: Baaz>(bar: Bar) rethrows where Baaz.Quux == Foo {
          print(bar)
      }

      func bar() { print("bar") }
      """

    let formatter = Formatter(tokenize(input))

    let function = try #require(formatter.parseFunctionDeclaration(keywordIndex: 2))
    #expect(function.keywordIndex == 2)
    #expect(function.name == "genericFoo")
    #expect(
      try formatter.tokens[#require(function.genericParameterRange)]
        .string == "<Bar: Baaz>")
    #expect(formatter.tokens[function.argumentsRange].string == "(bar: Bar)")
    #expect(function.arguments.count == 1)
    #expect(try formatter.tokens[#require(function.effectsRange)].string == "rethrows")
    #expect(function.effects == ["rethrows"])
    #expect(function.returnOperatorIndex == nil)
    #expect(function.returnType?.range == nil)
    #expect(
      try formatter.tokens[#require(function.whereClauseRange)]
        .string == "where Baaz.Quux == Foo ",
    )
    #expect(
      try formatter.tokens[#require(function.bodyRange)].string == """
        {
            print(bar)
        }
        """,
    )

    let secondFunction = try #require(formatter.parseFunctionDeclaration(keywordIndex: 41))
    #expect(secondFunction.keywordIndex == 41)
    #expect(secondFunction.name == "bar")
    #expect(secondFunction.genericParameterRange == nil)
    #expect(formatter.tokens[secondFunction.argumentsRange].string == "()")
    #expect(secondFunction.arguments.isEmpty)
    #expect(secondFunction.effectsRange == nil)
    #expect(secondFunction.effects == [])
    #expect(secondFunction.returnOperatorIndex == nil)
    #expect(secondFunction.returnType?.range == nil)
    #expect(secondFunction.whereClauseRange == nil)
    #expect(
      try formatter.tokens[#require(secondFunction.bodyRange)]
        .string == #"{ print("bar") }"#)
  }

  @Test func parseProtocolFunctionRequirements() throws {
    let input = """
      protocol FooBarProtocol {
          func foo(bar: Bar, baaz: Baaz) async throws -> Module.Foo<Bar, Baaz> where Bar == Baaz.Quux

          subscript<Bar: Baaz>(_ bar: Bar) throws
      }
      """

    let formatter = Formatter(tokenize(input))

    let function = try #require(formatter.parseFunctionDeclaration(keywordIndex: 7))
    #expect(function.keywordIndex == 7)
    #expect(function.name == "foo")
    #expect(function.genericParameterRange == nil)
    #expect(formatter.tokens[function.argumentsRange].string == "(bar: Bar, baaz: Baaz)")
    #expect(function.arguments.count == 2)
    #expect(try formatter.tokens[#require(function.effectsRange)].string == "async throws")
    #expect(function.effects == ["async", "throws"])
    #expect(function.returnOperatorIndex == 27)
    #expect(
      try formatter.tokens[#require(function.returnType?.range)]
        .string == "Module.Foo<Bar, Baaz>",
    )
    #expect(
      try formatter.tokens[#require(function.whereClauseRange)]
        .string == "where Bar == Baaz.Quux",
    )
    #expect(function.bodyRange == nil)

    let secondFunction = try #require(formatter.parseFunctionDeclaration(keywordIndex: 51))
    #expect(secondFunction.keywordIndex == 51)
    #expect(secondFunction.name == nil)
    #expect(
      try formatter.tokens[#require(secondFunction.genericParameterRange)]
        .string == "<Bar: Baaz>",
    )
    #expect(formatter.tokens[secondFunction.argumentsRange].string == "(_ bar: Bar)")
    #expect(secondFunction.arguments.count == 1)
    #expect(try formatter.tokens[#require(secondFunction.effectsRange)].string == "throws")
    #expect(secondFunction.effects == ["throws"])
    #expect(secondFunction.returnOperatorIndex == nil)
    #expect(secondFunction.returnType?.range == nil)
    #expect(secondFunction.whereClauseRange == nil)
    #expect(secondFunction.bodyRange == nil)
  }

  @Test func parseFailableInit() throws {
    let input = """
      init() {}
      init?() { return nil }
      """

    let formatter = Formatter(tokenize(input))

    let firstInit = try #require(formatter.parseFunctionDeclaration(keywordIndex: 0))
    #expect(firstInit.keywordIndex == 0)
    #expect(firstInit.name == nil)
    #expect(formatter.tokens[firstInit.argumentsRange].string == "()")
    #expect(firstInit.arguments.isEmpty)
    #expect(firstInit.effects == [])
    #expect(firstInit.returnOperatorIndex == nil)
    #expect(firstInit.whereClauseRange == nil)
    #expect(try formatter.tokens[#require(firstInit.bodyRange)].string == "{}")

    let secondInit = try #require(formatter.parseFunctionDeclaration(keywordIndex: 7))
    #expect(secondInit.keywordIndex == 7)
    #expect(secondInit.name == nil)
    #expect(formatter.tokens[secondInit.argumentsRange].string == "()")
    #expect(secondInit.arguments.isEmpty)
    #expect(secondInit.effects == [])
    #expect(secondInit.returnOperatorIndex == nil)
    #expect(secondInit.whereClauseRange == nil)
    #expect(try formatter.tokens[#require(secondInit.bodyRange)].string == "{ return nil }")
  }

  @Test func commaSeparatedElementsInScope() {
    let input = """
      [
          1,
          2,
          3
      ]
      """

    let formatter = Formatter(tokenize(input))
    let elements = formatter.commaSeparatedElementsInScope(startOfScope: 0).map {
      formatter.tokens[$0].string
    }
    #expect(
      elements == [
        "1",
        "2",
        "3",
      ],
    )
  }

  @Test func commaSeparatedElementsInScopeWithTrailingComma() {
    let input = """
      foo(
          foo: foo(),
          bar: bar(foo, bar),
          baaz: baaz.quux,
      )
      """

    let formatter = Formatter(tokenize(input))
    let elements = formatter.commaSeparatedElementsInScope(startOfScope: 1).map {
      formatter.tokens[$0].string
    }
    #expect(
      elements == [
        "foo: foo()",
        "bar: bar(foo, bar)",
        "baaz: baaz.quux",
      ],
    )
  }

  @Test func parseCommentRange() throws {
    let input = """
      import FooLib

      // Class declaration
      class MyClass {}

      // Other comment

      /// Foo bar
      /// baaz quux
      @Foo
      struct MyStruct {}
      """

    let formatter = Formatter(tokenize(input))
    let classCommentRange = try #require(
      formatter
        .parseDocCommentRange(forDeclarationAt: 9))  // class
    let structCommentRange = try #require(
      formatter
        .parseDocCommentRange(forDeclarationAt: 30))  // struct

    #expect(
      formatter.tokens[classCommentRange].string == """
        // Class declaration
        """,
    )

    #expect(
      formatter.tokens[structCommentRange].string == """
        /// Foo bar
        /// baaz quux
        """,
    )
  }

  @Test func parseFunctionArgumentWithAttribute() throws {
    let input = "init(@ViewBuilder content: () -> Content) {}"
    let tokens = tokenize(input)
    let formatter = Formatter(tokens)

    let funcDecl = try #require(formatter.parseFunctionDeclaration(keywordIndex: 0))
    #expect(funcDecl.arguments.count == 1)

    let arg = funcDecl.arguments[0]
    #expect(arg.internalLabel == "content")
    #expect(arg.type.string == "() -> Content")
    #expect(arg.attributes == ["@ViewBuilder"])
  }

  @Test func parseFunctionArgumentWithGenericAttribute() throws {
    let input = "init(@DictionaryBuilder<String, Int> content: () -> [String: Int]) {}"
    let tokens = tokenize(input)
    let formatter = Formatter(tokens)

    let funcDecl = try #require(formatter.parseFunctionDeclaration(keywordIndex: 0))
    #expect(funcDecl.arguments.count == 1)

    let arg = funcDecl.arguments[0]
    #expect(arg.internalLabel == "content")
    #expect(arg.type.string == "() -> [String: Int]")
    #expect(arg.attributes == ["@DictionaryBuilder<String, Int>"])
  }

  @Test func parseDeclarationsWithViewBuilderProperty() {
    let input = """
      struct Foo {
          @Environment(\\.bar) private var bar

          @ViewBuilder let content: Content
          let title: String
      }
      """
    let tokens = tokenize(input)
    let formatter = Formatter(tokens)

    let declarations = formatter.parseDeclarations()
    guard let typeDecl = declarations.first?.asTypeDeclaration else {
      Issue.record("Failed to parse type declaration")
      return
    }

    // Should have 3 property declarations
    let properties = typeDecl.body.filter { $0.keyword == "var" || $0.keyword == "let" }
    #expect(properties.count == 3)

    // Check that @ViewBuilder property is parsed correctly
    let viewBuilderProp = properties.first { prop in
      formatter.tokens[prop.keywordIndex + 2].string == "content"
    }
    #expect(viewBuilderProp != nil, "@ViewBuilder property should be found")
    #expect(viewBuilderProp?.keyword == "let")
  }

  @Test func parseDeclarationsWithViewBuilderPropertyNoBlankLine() {
    // @ViewBuilder property immediately after another property (no blank line)
    let input = """
      struct Foo {
          @Environment(\\.sizeClass) private var sizeClass
          @ViewBuilder let actionBar: ActionBar
          let title: String
      }
      """
    let tokens = tokenize(input)
    let formatter = Formatter(tokens)

    let declarations = formatter.parseDeclarations()
    guard let typeDecl = declarations.first?.asTypeDeclaration else {
      Issue.record("Failed to parse type declaration")
      return
    }

    let properties = typeDecl.body.filter { $0.keyword == "var" || $0.keyword == "let" }
    #expect(properties.count == 3, "Should find 3 properties: sizeClass, actionBar, title")
  }
}
