import Testing

@testable import Swiftiomatic

extension WrapArgumentsTests {
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
      wrapEffects: .never,
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
      wrapEffects: .never,
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
      wrapEffects: .never,
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
      maxWidth: 100,
    )

    testFormatting(
      for: input,
      [output],
      rules: [.wrapArguments, .wrap, .indent],
      options: options,
    )
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
      wrapEffects: .ifMultiline,
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
      wrapEffects: .never,
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
      wrapEffects: .never,
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
      wrapEffects: .never,
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
      wrapEffects: .never,
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

  @Test func wrapArgumentsDoesNotBreakFunctionDeclaration_issue_1776() {
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
    testFormatting(
      for: input,
      rule: .wrapArguments,
      options: options,
      exclude: [.propertyTypes],
    )
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
      exclude: [.indent],
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
      wrapReturnType: .ifMultiline,
    )

    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent],
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
      wrapReturnType: .ifMultiline,
    )

    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent],
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
      wrapEffects: .ifMultiline,
    )

    testFormatting(
      for: input, output, rule: .wrapArguments, options: options,
      exclude: [.indent],
    )
  }

  @Test func wrapEffectsNeverDoesNotUnwrapAsyncLet() {
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
      wrapEffects: .ifMultiline,
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
      wrapEffects: .ifMultiline,
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
      wrapEffects: .ifMultiline,
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func doesNotWrapReturnOnMultilineThrowingFunction() {
    let input = """
      func multilineFunction(foo _: String,
                             bar _: String)
                             throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .afterFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
    )

    testFormatting(
      for: input, rule: .wrapArguments, options: options,
      exclude: [.indent],
    )
  }

  @Test func doesNotWrapReturnOnSingleLineFunctionDeclaration() {
    let input = """
      func multilineFunction(foo _: String, bar _: String) -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func doesNotWrapReturnOnSingleLineFunctionDeclarationAfterMultilineArray() {
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
      wrapReturnType: .ifMultiline,
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func doesNotWrapReturnOnSingleLineFunctionDeclarationAfterMultilineMethodCall() {
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
      wrapReturnType: .ifMultiline,
    )

    testFormatting(
      for: input,
      rule: .wrapArguments,
      options: options,
      exclude: [.propertyTypes],
    )
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
      closingParenPosition: .sameLine,
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

}
