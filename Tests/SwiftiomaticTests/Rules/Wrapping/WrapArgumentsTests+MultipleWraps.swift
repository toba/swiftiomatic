import Testing

@testable import Swiftiomatic

extension WrapArgumentsTests {
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
      maxWidth: 28,
    )
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments, .wrap], options: options,
    )
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
      maxWidth: 28,
    )
    testFormatting(
      for: input, [output],
      rules: [.wrapArguments, .wrap], options: options,
    )
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
      rules: [.wrapArguments, .wrap], options: options,
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
  }

  @Test func wrapArguments_typealias_shorterThanMaxWidth() {
    let input = """
      typealias Dependencies = FooProviding & BarProviding & BaazProviding
      """

    let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 100)
    testFormatting(
      for: input,
      rule: .wrapArguments,
      options: options,
      exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
    testFormatting(
      for: input,
      rule: .wrapArguments,
      options: options,
      exclude: [.sortTypealiases],
    )
  }

  @Test func wrapArguments_typealias_preservesCommentsAfterTypes() {
    let input = """
      typealias Dependencies
          = FooProviding // We use `FooProviding` because `FooFeature` depends on `Foo`
          & BarProviding // We use `BarProviding` because `BarFeature` depends on `Bar`
          & BaazProviding // We use `BaazProviding` because `BaazFeature` depends on `Baaz`
      """

    let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 100)
    testFormatting(
      for: input,
      rule: .wrapArguments,
      options: options,
      exclude: [.sortTypealiases],
    )
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
      for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases],
    )
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
      wrapReturnType: .ifMultiline,
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
      wrapReturnType: .ifMultiline,
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
      wrapEffects: .ifMultiline,
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

  @Test func doesNotWrapReturnAndEffectOnSingleLineFunctionDeclaration() {
    let input = """
      func singleLineFunction() async throws -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline,
    )

    testFormatting(for: input, rule: .wrapArguments, options: options)
  }

  @Test func doesNotWrapReturnAndTypedEffectOnSingleLineFunctionDeclaration() {
    let input = """
      func singleLineFunction() async throws(Foo) -> String {}
      """

    let options = FormatOptions(
      wrapArguments: .beforeFirst,
      closingParenPosition: .sameLine,
      wrapReturnType: .ifMultiline,
      wrapEffects: .ifMultiline,
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
      wrapEffects: .ifMultiline,
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
      wrapEffects: .never,
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
      wrapEffects: .ifMultiline,
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
      wrapEffects: .never,
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
      wrapEffects: .never,
    )

    testFormatting(for: input, output, rule: .wrapArguments, options: options)
  }

}
