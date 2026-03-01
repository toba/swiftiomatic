import Testing

@testable import Swiftiomatic

extension MarkTypesTests {
  @Test func markTypesIfNotEmpty() {
    let input = """
      struct EmptyFoo {}
      struct EmptyBar { }
      struct EmptyBaz {

      }
      struct Quux {
          let foo = 1
      }
      """

    let output = """
      struct EmptyFoo {}
      struct EmptyBar { }
      struct EmptyBaz {

      }

      // MARK: - Quux

      struct Quux {
          let foo = 1
      }
      """

    let options = FormatOptions(markTypes: .ifNotEmpty)
    testFormatting(
      for: input, output, rule: .markTypes, options: options,
      exclude: [
        .emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
        .blankLinesBetweenScopes,
      ],
    )
  }

  @Test func neverMarkExtensions() {
    let input = """
      extension EmptyFoo: FooProtocol {}
      extension EmptyBar: BarProtocol { }
      extension EmptyBaz: BazProtocol {

      }
      extension Quux: QuuxProtocol {
          let foo = 1
      }
      """

    let options = FormatOptions(markExtensions: .never)
    testFormatting(
      for: input, rule: .markTypes, options: options,
      exclude: [
        .emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
        .blankLinesBetweenScopes,
      ],
    )
  }

  @Test func markExtensionsIfNotEmpty() {
    let input = """
      extension EmptyFoo: FooProtocol {}
      extension EmptyBar: BarProtocol { }
      extension EmptyBaz: BazProtocol {

      }
      extension Quux: QuuxProtocol {
          let foo = 1
      }
      """

    let output = """
      extension EmptyFoo: FooProtocol {}
      extension EmptyBar: BarProtocol { }
      extension EmptyBaz: BazProtocol {

      }

      // MARK: - Quux + QuuxProtocol

      extension Quux: QuuxProtocol {
          let foo = 1
      }
      """

    let options = FormatOptions(markExtensions: .ifNotEmpty)
    testFormatting(
      for: input, output, rule: .markTypes, options: options,
      exclude: [
        .emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
        .blankLinesBetweenScopes,
      ],
    )
  }

  @Test func markExtensionsDisabled() {
    let input = """
      extension Foo: FooProtocol {}

      // sm:disable markTypes

      extension Bar: BarProtocol {}

      // sm:enable markTypes

      extension Baz: BazProtocol {}

      extension Quux: QuuxProtocol {}
      """

    let output = """
      // MARK: - Foo + FooProtocol

      extension Foo: FooProtocol {}

      // sm:disable markTypes

      extension Bar: BarProtocol {}

      // MARK: - Baz + BazProtocol

      // sm:enable markTypes

      extension Baz: BazProtocol {}

      // MARK: - Quux + QuuxProtocol

      extension Quux: QuuxProtocol {}
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func extensionMarkWithImportOfSameName() {
    let input = """
      import MagazineLayout

      // MARK: - MagazineLayout + FooProtocol

      extension MagazineLayout: FooProtocol {}

      // MARK: - MagazineLayout + BarProtocol

      extension MagazineLayout: BarProtocol {}
      """

    testFormatting(for: input, rule: .markTypes)
  }

  @Test func doesNotUseGroupedMarkTemplateWhenSeparatedByOtherType() {
    let input = """
      // MARK: - MyComponent

      class MyComponent {}

      // MARK: - MyComponentContent

      struct MyComponentContent {}

      // MARK: - MyComponent + ContentConfigurableView

      extension MyComponent: ContentConfigurableView {}
      """

    testFormatting(for: input, rule: .markTypes)
  }

  @Test func usesGroupedMarkTemplateWhenSeparatedByExtensionOfSameType() {
    let input = """
      // MARK: - MyComponent

      class MyComponent {}

      // MARK: Equatable

      extension MyComponent: Equatable {}

      // MARK: ContentConfigurableView

      extension MyComponent: ContentConfigurableView {}
      """

    testFormatting(for: input, rule: .markTypes)
  }

  @Test func doesNotUseGroupedMarkTemplateWhenSeparatedByExtensionOfOtherType() {
    let input = """
      // MARK: - MyComponent

      class MyComponent {}

      // MARK: - OtherComponent + Equatable

      extension OtherComponent: Equatable {}

      // MARK: - MyComponent + ContentConfigurableView

      extension MyComponent: ContentConfigurableView {}
      """

    testFormatting(for: input, rule: .markTypes)
  }

  @Test func addsMarkBeforeTypesWithNoBlankLineAfterMark() {
    let input = """
      struct Foo {}
      class Bar {}
      enum Baz {}
      protocol Quux {}
      """

    let output = """
      // MARK: - Foo
      struct Foo {}

      // MARK: - Bar
      class Bar {}

      // MARK: - Baz
      enum Baz {}

      // MARK: - Quux
      protocol Quux {}
      """
    let options = FormatOptions(lineAfterMarks: false)
    testFormatting(for: input, output, rule: .markTypes, options: options)
  }

  @Test func addsMarkForTypeInExtension() {
    let input = """
      enum Foo {}

      extension Foo {
          struct Bar {
              let baaz: Baaz
          }
      }
      """

    let output = """
      // MARK: - Foo

      enum Foo {}

      // MARK: Foo.Bar

      extension Foo {
          struct Bar {
              let baaz: Baaz
          }
      }
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func doesNotAddsMarkForMultipleTypesInExtension() {
    let input = """
      enum Foo {}

      extension Foo {
          struct Bar {
              let baaz: Baaz
          }

          struct Quux {
              let baaz: Baaz
          }
      }
      """

    let output = """
      // MARK: - Foo

      enum Foo {}

      extension Foo {
          struct Bar {
              let baaz: Baaz
          }

          struct Quux {
              let baaz: Baaz
          }
      }
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func addsMarkForTypeInExtensionNotFollowingTypeBeingExtended() {
    let input = """
      struct Baaz {}

      extension Foo {
          struct Bar {
              let baaz: Baaz
          }
      }
      """

    let output = """
      // MARK: - Baaz

      struct Baaz {}

      // MARK: - Foo.Bar

      extension Foo {
          struct Bar {
              let baaz: Baaz
          }
      }
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func handlesMultipleLayersOfExtensionNesting() {
    let input = """
      enum Foo {}

      extension Foo {
          enum Bar {}
      }

      extension Foo {
          extension Bar {
              struct Baaz {
                  let quux: Quux
              }
          }
      }
      """

    let output = """
      // MARK: - Foo

      enum Foo {}

      // MARK: Foo.Bar

      extension Foo {
          enum Bar {}
      }

      // MARK: Foo.Bar.Baaz

      extension Foo {
          extension Bar {
              struct Baaz {
                  let quux: Quux
              }
          }
      }
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func markTypeLintReturnsErrorAsExpected() throws {
    let input = """
      struct MyStruct {}

      extension MyStruct {}
      """

    // Initialize rule names
    _ = FormatRules.byName
    let changes = try lint(input, rules: [.markTypes])
    #expect(
      changes == [
        .init(line: 1, rule: .markTypes, filePath: nil, isMove: false)
      ],
    )
  }

  @Test func complexTypeNames() {
    let input = """
      extension [Foo]: TestProtocol {
          func test() {}
      }

      extension Foo.Bar.Baaz: TestProtocol {
          func test() {}
      }

      extension Collection<Foo>: TestProtocol {
          func test() {}
      }

      extension Foo?: TestProtocol {
          func test()
      }
      """

    let output = """
      // MARK: - [Foo] + TestProtocol

      extension [Foo]: TestProtocol {
          func test() {}
      }

      // MARK: - Foo.Bar.Baaz + TestProtocol

      extension Foo.Bar.Baaz: TestProtocol {
          func test() {}
      }

      // MARK: - Collection<Foo> + TestProtocol

      extension Collection<Foo>: TestProtocol {
          func test() {}
      }

      // MARK: - Foo? + TestProtocol

      extension Foo?: TestProtocol {
          func test()
      }
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func markCommentOnExtensionWithWrappedType() {
    let input = """
      extension Foo.Bar
          .Baaz.Quux: Foo
          .Bar.Baaz
          .QuuxProtocol
      {
          func test() {}
      }

      extension [
          String: AnyHashable
      ]: Hashable {}
      """

    let output = """
      // MARK: - Foo.Bar.Baaz.Quux + Foo.Bar.Baaz.QuuxProtocol

      extension Foo.Bar
          .Baaz.Quux: Foo
          .Bar.Baaz
          .QuuxProtocol
      {
          func test() {}
      }

      // MARK: - [String: AnyHashable] + Hashable

      extension [
          String: AnyHashable
      ]: Hashable {}
      """

    testFormatting(
      for: input,
      output,
      rule: .markTypes,
      exclude: [.wrapMultilineFunctionChains],
    )
  }

  @Test func supportsUncheckedSendable() {
    let input = """
      struct Foo {}

      extension Foo: @unchecked Sendable {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}

      // MARK: @unchecked Sendable

      extension Foo: @unchecked Sendable {}
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func supportsProtocolCompositions() {
    let input = """
      struct Foo {}

      extension Foo: Bar & Baaz {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}

      // MARK: Bar & Baaz

      extension Foo: Bar & Baaz {}
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func supportsMaybeCopiable() {
    let input = """
      struct Foo {}

      extension Foo: ~Copyable {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}

      // MARK: ~Copyable

      extension Foo: ~Copyable {}
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func marksTypeAfterExtension() {
    let input = """
      extension Foo {
          var foo: Foo { Foo() }
          var bar: Bar { Bar() }
      }

      struct Baaz {
          let foo: Foo
          let bar: Bar
      }
      """

    let output = """
      extension Foo {
          var foo: Foo { Foo() }
          var bar: Bar { Bar() }
      }

      // MARK: - Baaz

      struct Baaz {
          let foo: Foo
          let bar: Bar
      }
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.wrapPropertyBodies])
  }
}
