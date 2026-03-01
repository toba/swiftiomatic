import Testing

@testable import Swiftiomatic

extension ParsingHelpersTests {
  // MARK: parseDeclarations

  @Test func parseDeclarations() {
    let input = """
      import CoreGraphics
      import Foundation

      let global = 10

      @objc
      @available(iOS 13.0, *)
      @propertyWrapper("parameter")
      weak var multilineGlobal = ["string"]
          .map(\\.count)
      let anotherGlobal = "hello"

      /// Doc comment
      /// (multiple lines)
      func globalFunction() {
          print("hi")
      }

      protocol SomeProtocol {
          var getter: String { get async throws }
          func protocolMethod() -> Bool
      }

      class SomeClass {

          enum NestedEnum {
              /// Doc comment
              case bar
              func test() {}
          }

          /*
           * Block comment
           */

          private(set)
          var instanceVar = "test" // trailing comment

          @_silgen_name("__MARKER_functionWithNoBody")
          func functionWithNoBody(_ x: String) -> Int?

          @objc
          private var computed: String {
              get {
                  "computed string"
              }
          }

      }

      struct EmptyType {}

      struct Test{let foo: String}

      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(
      declarations[0].tokens.string == """
        import CoreGraphics

        """,
    )

    #expect(
      declarations[1].tokens.string == """
        import Foundation


        """,
    )

    #expect(
      declarations[2].tokens.string == """
        let global = 10


        """,
    )

    #expect(
      declarations[3].tokens.string == """
        @objc
        @available(iOS 13.0, *)
        @propertyWrapper("parameter")
        weak var multilineGlobal = ["string"]
            .map(\\.count)

        """,
    )

    #expect(
      declarations[4].tokens.string == """
        let anotherGlobal = "hello"


        """,
    )

    #expect(
      declarations[5].tokens.string == """
        /// Doc comment
        /// (multiple lines)
        func globalFunction() {
            print("hi")
        }


        """,
    )

    #expect(
      declarations[6].tokens.string == """
        protocol SomeProtocol {
            var getter: String { get async throws }
            func protocolMethod() -> Bool
        }


        """,
    )

    #expect(
      declarations[6].body?[0].tokens.string == """
            var getter: String { get async throws }

        """,
    )

    #expect(
      declarations[6].body?[1].tokens.string == """
            func protocolMethod() -> Bool

        """,
    )

    #expect(
      declarations[7].tokens.string == """
        class SomeClass {

            enum NestedEnum {
                /// Doc comment
                case bar
                func test() {}
            }

            /*
             * Block comment
             */

            private(set)
            var instanceVar = "test" // trailing comment

            @_silgen_name("__MARKER_functionWithNoBody")
            func functionWithNoBody(_ x: String) -> Int?

            @objc
            private var computed: String {
                get {
                    "computed string"
                }
            }

        }


        """,
    )

    #expect(
      declarations[7].body?[0].tokens.string == """
            enum NestedEnum {
                /// Doc comment
                case bar
                func test() {}
            }


        """,
    )

    #expect(
      declarations[7].body?[0].body?[0].tokens.string == """
                /// Doc comment
                case bar

        """,
    )

    #expect(
      declarations[7].body?[0].body?[1].tokens.string == """
                func test() {}

        """,
    )

    #expect(
      declarations[7].body?[1].tokens.string == """
            /*
             * Block comment
             */

            private(set)
            var instanceVar = "test" // trailing comment


        """,
    )

    #expect(
      declarations[7].body?[2].tokens.string == """
            @_silgen_name(\"__MARKER_functionWithNoBody\")
            func functionWithNoBody(_ x: String) -> Int?


        """,
    )

    #expect(
      declarations[7].body?[3].tokens.string == """
            @objc
            private var computed: String {
                get {
                    "computed string"
                }
            }


        """,
    )

    #expect(
      declarations[8].tokens.string == """
        struct EmptyType {}


        """,
    )

    #expect(
      declarations[9].tokens.string == """
        struct Test{let foo: String}

        """,
    )

    #expect(
      declarations[9].body?[0].tokens.string == """
        let foo: String
        """,
    )
  }

  @Test func parseClassFuncDeclarationCorrectly() {
    // `class func` is one of the few cases (possibly only!)
    // where a declaration will have more than one declaration token
    let input = """
      class Foo() {}

      class func foo() {}
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(declarations[0].keyword == "class")
    #expect(declarations[1].keyword == "func")
  }

  @Test func parseMarkCommentsCorrectly() {
    let input = """
      class Foo {

          // MARK: Lifecycle

          init(json: JSONObject) throws {
              bar = try json.value(for: "bar")
              baz = try json.value(for: "baz")
          }

          // MARK: Internal

          let bar: String
          var baz: Int?

      }
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(declarations[0].keyword == "class")
    #expect(declarations[0].body?[0].keyword == "init")
    #expect(declarations[0].body?[1].keyword == "let")
    #expect(declarations[0].body?[2].keyword == "var")
  }

  @Test func parseTrailingCommentsCorrectly() {
    let input = """
      struct Foo {
          var bar = "bar"
          /// Leading comment
          public var baz = "baz" // Trailing comment
          var quux = "quux"
      }
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(
      declarations[0].body?[0].tokens.string == """
            var bar = "bar"

        """,
    )

    #expect(
      declarations[0].body?[0].tokens.string == """
            var bar = "bar"

        """,
    )

    #expect(
      declarations[0].body?[1].tokens.string == """
            /// Leading comment
            public var baz = "baz" // Trailing comment

        """,
    )

    #expect(
      declarations[0].body?[2].tokens.string == """
            var quux = "quux"

        """,
    )
  }

  @Test func parseDeclarationsWithSituationalKeywords() {
    let input = """
      let `static` = NavigationBarType.static(nil, .none)
      let foo = bar
      let `static` = NavigationBarType.static
      let bar = foo
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(
      declarations[0].tokens.string == """
        let `static` = NavigationBarType.static(nil, .none)

        """,
    )

    #expect(
      declarations[1].tokens.string == """
        let foo = bar

        """,
    )

    #expect(
      declarations[2].tokens.string == """
        let `static` = NavigationBarType.static

        """,
    )

    #expect(
      declarations[3].tokens.string == """
        let bar = foo
        """,
    )
  }

  @Test func parseSimpleCompilationBlockCorrectly() {
    let input = """
      #if DEBUG
      struct DebugFoo {
          let bar = "debug"
      }
      #endif
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(declarations[0].keyword == "#if")
    #expect(declarations[0].body?[0].keyword == "struct")
    #expect(declarations[0].body?[0].body?[0].keyword == "let")
  }

  @Test func parseSimpleNestedCompilationBlockCorrectly() {
    let input = """
      #if canImport(UIKit)
      #if DEBUG
      struct DebugFoo {
          let bar = "debug"
      }
      #endif
      #endif
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(declarations[0].keyword == "#if")
    #expect(declarations[0].body?[0].keyword == "#if")
    #expect(declarations[0].body?[0].body?[0].keyword == "struct")
    #expect(declarations[0].body?[0].body?[0].body?[0].keyword == "let")
  }

  @Test func parseComplexConditionalCompilationBlockCorrectly() {
    let input = """
      let beforeBlock = "baz"

      #if DEBUG
      struct DebugFoo {
          let bar = "debug"
      }
      #elseif BETA
      struct BetaFoo {
          let bar = "beta"
      }
      #else
      struct ProductionFoo {
          let bar = "production"
      }
      #endif

      #if EMPTY_BLOCK
      #endif

      let afterBlock = "quux"
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(declarations[0].keyword == "let")
    #expect(declarations[1].keyword == "#if")
    #expect(declarations[1].body?[0].keyword == "struct")
    #expect(declarations[1].body?[1].keyword == "struct")
    #expect(declarations[1].body?[2].keyword == "struct")
    #expect(declarations[2].keyword == "#if")
    #expect(declarations[3].keyword == "let")
  }

  @Test func parseSymbolImportCorrectly() {
    let input = """
      import protocol SomeModule.SomeProtocol
      import class SomeModule.SomeClass
      import enum SomeModule.SomeEnum
      import struct SomeModule.SomeStruct
      import typealias SomeModule.SomeTypealias
      import let SomeModule.SomeGlobalConstant
      import var SomeModule.SomeGlobalVariable
      import func SomeModule.SomeFunc

      struct Foo {
          init() {}
          public func instanceMethod() {}
      }
      """

    let originalTokens = tokenize(input)
    let declarations = Formatter(originalTokens).parseDeclarations()

    #expect(declarations[0].keyword == "import")
    #expect(declarations[1].keyword == "import")
    #expect(declarations[2].keyword == "import")
    #expect(declarations[3].keyword == "import")
    #expect(declarations[4].keyword == "import")
    #expect(declarations[5].keyword == "import")
    #expect(declarations[6].keyword == "import")
    #expect(declarations[7].keyword == "import")
    #expect(declarations[8].keyword == "struct")
    #expect(declarations[8].body?[0].keyword == "init")
    #expect(declarations[8].body?[1].keyword == "func")
  }

  @Test func classOverrideDoesntCrashParseDeclarations() {
    let input = """
      class Foo {
          var bar: Int?
          class override var baz: String
      }
      """
    let tokens = tokenize(input)
    _ = Formatter(tokens).parseDeclarations()
  }

  @Test func parseDeclarationRangesInType() throws {
    let input = """
      class Foo {
          let bar = "bar"
          let baaz = "baaz"
      }
      """

    let formatter = Formatter(tokenize(input))
    let declarations = formatter.parseDeclarations()

    #expect(declarations.count == 1)
    #expect(declarations[0].range == 0...28)

    #expect(declarations[0].body?.count == 2)

    let barDeclarationRange = try #require(declarations[0].body?[0].range)
    #expect(barDeclarationRange == 6...16)
    #expect(formatter.tokens[barDeclarationRange].string == "    let bar = \"bar\"\n")

    let baazDeclarationRange = try #require(declarations[0].body?[1].range)
    #expect(baazDeclarationRange == 17...27)
    #expect(formatter.tokens[baazDeclarationRange].string == "    let baaz = \"baaz\"\n")
  }

  @Test func parseDeclarationRangesInConditionalCompilation() throws {
    let input = """
      #if DEBUG
      let bar = "bar"
      let baaz = "baaz"
      #endif
      """

    let formatter = Formatter(tokenize(input))
    let declarations = formatter.parseDeclarations()

    #expect(declarations.count == 1)
    #expect(declarations[0].range == 0...24)
    #expect(declarations[0].tokens.map(\.string).joined() == input)

    #expect(declarations[0].body?.count == 2)

    let barDeclarationRange = try #require(declarations[0].body?[0].range)
    #expect(barDeclarationRange == 4...13)
    #expect(formatter.tokens[barDeclarationRange].string == "let bar = \"bar\"\n")

    let baazDeclarationRange = try #require(declarations[0].body?[1].range)
    #expect(baazDeclarationRange == 14...23)
    #expect(formatter.tokens[baazDeclarationRange].string == "let baaz = \"baaz\"\n")
  }

  @Test func parseConditionalCompilationWithNoInnerDeclarations() {
    let input = """
      struct Foo {
          // This type is empty
      }
      extension Foo {
          // This extension is empty
      }
      """

    let formatter = Formatter(tokenize(input))
    let declarations = formatter.parseDeclarations()
    #expect(declarations.count == 2)

    #expect(
      declarations[0].tokens.map(\.string).joined() == """
        struct Foo {
            // This type is empty
        }

        """,
    )

    #expect(
      declarations[1].tokens.map(\.string).joined() == """
        extension Foo {
            // This extension is empty
        }
        """,
    )
  }

  @Test func parseConditionalCompilationWithArgument() {
    let input = """
      #if os(Linux)
      #error("Linux is currently not supported")
      #endif
      """

    let formatter = Formatter(tokenize(input))
    let declarations = formatter.parseDeclarations()
    #expect(declarations.count == 1)
    #expect(declarations[0].tokens.map(\.string).joined() == input)
  }

  @Test func parseIfExpressionDeclaration() {
    let input = """
      private lazy var x: [Any] =
        if let b {
          [b]
        } else if false {
          []
        } else {
          [1, 2]
        }

      private lazy var y = f()
      """

    let formatter = Formatter(tokenize(input))
    let declarations = formatter.parseDeclarations()
    #expect(declarations.count == 2)

    #expect(
      declarations[0].tokens.string == """
        private lazy var x: [Any] =
          if let b {
            [b]
          } else if false {
            []
          } else {
            [1, 2]
          }


        """,
    )

    #expect(declarations[1].tokens.string == "private lazy var y = f()")
  }

  @Test func parseDeclarationsWithMalformedTypes() {
    let input = """
      extension Foo {
          /// Invalid type, should still get handled properly
          private var foo: FooBar++ {
              guard
                  let foo = foo.bar,
                  let bar = foo.bar
              else {
                  return nil
              }

              return bar
          }
      }

      extension Foo {
          /// Invalid type, should still get handled properly
          func foo() -> FooBar++ {
              guard
                  let foo = foo.bar,
                  let bar = foo.bar
              else {
                  return nil
              }

              return bar
          }

          func bar() {}
      }
      """

    let formatter = Formatter(tokenize(input))
    let declarations = formatter.parseDeclarations()
    #expect(declarations.count == 2)
    #expect(declarations[0].body?.count == 1)
    #expect(declarations[1].body?.count == 2)

    #expect(
      declarations[0].body?[0].tokens.string == """
            /// Invalid type, should still get handled properly
            private var foo: FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }

        """,
    )

    #expect(
      declarations[1].body?[0].tokens.string == """
            /// Invalid type, should still get handled properly
            func foo() -> FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }


        """,
    )
  }

  // MARK: declarationScope

  @Test func declarationScope_classAndGlobals() {
    let input = """
      let foo = Foo()

      class Foo {
          let instanceMember = Bar()
      }

      let bar = Bar()
      """

    let tokens = tokenize(input)
    let formatter = Formatter(tokens)

    #expect(formatter.declarationScope(at: 3) == .global)  // foo
    #expect(formatter.declarationScope(at: 20) == .type)  // instanceMember
    #expect(formatter.declarationScope(at: 33) == .global)  // bar
  }

  @Test func declarationScope_classAndLocal() {
    let input = """
      class Foo {
          let instanceMember1 = Bar()

          var instanceMember2: Bar = {
              Bar()
          }

          func instanceMethod() {
              let localMember1 = Bar()
          }

          let instanceMember3 = Bar()

          let instanceMemberClosure = Foo {
              let localMember2 = Bar()
          }
      }
      """

    let tokens = tokenize(input)
    let formatter = Formatter(tokens)

    #expect(formatter.declarationScope(at: 9) == .type)  // instanceMember1
    #expect(formatter.declarationScope(at: 21) == .type)  // instanceMember2
    #expect(formatter.declarationScope(at: 31) == .local)  // Bar()
    #expect(formatter.declarationScope(at: 42) == .type)  // instanceMethod
    #expect(formatter.declarationScope(at: 51) == .local)  // localMember1
    #expect(formatter.declarationScope(at: 66) == .type)  // instanceMember3
    #expect(formatter.declarationScope(at: 78) == .type)  // instanceMemberClosure
    #expect(formatter.declarationScope(at: 89) == .local)  // localMember2
  }

  @Test func declarationScope_protocol() {
    let input = """
      protocol Bar {
          var foo { get }
      }
      """

    let formatter = Formatter(tokenize(input))
    #expect(formatter.declarationScope(at: 7) == .type)
  }

  @Test func declarationScope_doCatch() {
    let input = """
      do {
          let decoder = JSONDecoder()
          return try decoder.decode(T.self, from: data)
      } catch {
          return error
      }
      """

    let formatter = Formatter(tokenize(input))
    #expect(formatter.declarationScope(at: 5) == .local)
  }

  @Test func declarationScope_ifLet() {
    let input = """
      if let foo = bar {
          return foo
      }
      """

    let formatter = Formatter(tokenize(input))
    #expect(formatter.declarationScope(at: 2) == .local)
  }

  // MARK: spaceEquivalentToWidth

  @Test func spaceEquivalentToWidth() {
    let formatter = Formatter([])
    #expect(formatter.spaceEquivalentToWidth(10) == "          ")
  }

  @Test func spaceEquivalentToWidthWithTabs() {
    let options = FormatOptions(indent: "\t", tabWidth: 4, smartTabs: false)
    let formatter = Formatter([], options: options)
    #expect(formatter.spaceEquivalentToWidth(10) == "\t\t  ")
  }

  // MARK: spaceEquivalentToTokens

  @Test func spaceEquivalentToCode() {
    let tokens = tokenize("let a = b + c")
    let formatter = Formatter(tokens)
    #expect(formatter.spaceEquivalentToTokens(from: 0, upTo: tokens.count) == "             ")
  }

  @Test func spaceEquivalentToImageLiteral() {
    let tokens = tokenize("let a = #imageLiteral(resourceName: \"abc.png\")")
    let formatter = Formatter(tokens)
    #expect(formatter.spaceEquivalentToTokens(from: 0, upTo: tokens.count) == "          ")
  }

  // MARK: startOfConditionalStatement

  @Test func ifTreatedAsConditional() {
    let formatter = Formatter(tokenize("if bar == baz {}"))
    for i in formatter.tokens.indices.dropLast(2) {
      #expect(formatter.startOfConditionalStatement(at: i) == 0)
    }
  }

  @Test func ifLetTreatedAsConditional() {
    let formatter = Formatter(tokenize("if let bar = baz {}"))
    for i in formatter.tokens.indices.dropLast(2) {
      #expect(formatter.startOfConditionalStatement(at: i) == 0)
    }
  }

  @Test func guardLetTreatedAsConditional() {
    let formatter = Formatter(tokenize("guard let foo = bar else {}"))
    for i in formatter.tokens.indices.dropLast(4) {
      #expect(formatter.startOfConditionalStatement(at: i) == 0)
    }
  }

  @Test func letNotTreatedAsConditional() {
    let formatter = Formatter(tokenize("let foo = bar, bar = baz"))
    for i in formatter.tokens.indices {
      #expect(formatter.startOfConditionalStatement(at: i) == nil)
    }
  }

  @Test func enumCaseNotTreatedAsConditional() {
    let formatter = Formatter(tokenize("enum Foo { case bar }"))
    for i in formatter.tokens.indices {
      #expect(formatter.startOfConditionalStatement(at: i) == nil)
    }
  }

  @Test func startOfConditionalStatementConditionContainingUnParenthesizedClosure() {
    let formatter = Formatter(
      tokenize(
        """
        if let btn = btns.first { !$0.isHidden } {}
        """,
      ),
    )
    #expect(formatter.startOfConditionalStatement(at: 12) == 0)
    #expect(formatter.startOfConditionalStatement(at: 21) == 0)
  }

  // MARK: isStartOfStatement

  @Test func asyncAfterFuncNotTreatedAsStartOfStatement() {
    let formatter = Formatter(
      tokenize(
        """
        func foo()
            async
        """,
      ),
    )
    #expect(!(formatter.isStartOfStatement(at: 7)))
  }

  @Test func asyncLetTreatedAsStartOfStatement() {
    let formatter = Formatter(
      tokenize(
        """
        async let foo = bar()
        """,
      ),
    )
    #expect(formatter.isStartOfStatement(at: 0))
  }

  @Test func asyncIdentifierTreatedAsStartOfStatement() {
    let formatter = Formatter(
      tokenize(
        """
        func async() {}
        async()
        """,
      ),
    )
    #expect(formatter.isStartOfStatement(at: 9))
  }

  @Test func asyncIdentifierNotTreatedAsStartOfStatement() {
    let formatter = Formatter(
      tokenize(
        """
        func async() {}
        let foo =
            async()
        """,
      ),
    )
    #expect(!(formatter.isStartOfStatement(at: 16)))
  }

  @Test func numericFunctionArgumentNotTreatedAsStartOfStatement() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = bar(
            200
        )
        """,
      ),
    )
    #expect(!(formatter.isStartOfStatement(at: 10, treatingCollectionKeysAsStart: false)))
  }

  @Test func stringLiteralFunctionArgumentNotTreatedAsStartOfStatement() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = bar(
            "baz"
        )
        """,
      ),
    )
    #expect(!(formatter.isStartOfStatement(at: 10, treatingCollectionKeysAsStart: false)))
  }

}
