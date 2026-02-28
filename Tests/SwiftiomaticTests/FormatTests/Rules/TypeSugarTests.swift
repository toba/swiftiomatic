import Testing

@testable import Swiftiomatic

@Suite struct TypeSugarTests {
  // arrays

  @Test func arrayTypeConvertedToSugar() {
    let input = """
      var foo: Array<String>
      """
    let output = """
      var foo: [String]
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func swiftArrayTypeConvertedToSugar() {
    let input = """
      var foo: Swift.Array<String>
      """
    let output = """
      var foo: [String]
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func arrayNestedTypeAliasNotConvertedToSugar() {
    let input = """
      typealias Indices = Array<Foo>.Indices
      """
    testFormatting(for: input, rule: .typeSugar)
  }

  @Test func arrayTypeReferenceConvertedToSugar() {
    let input = """
      let type = Array<Foo>.Type
      """
    let output = """
      let type = [Foo].Type
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func swiftArrayTypeReferenceConvertedToSugar() {
    let input = """
      let type = Swift.Array<Foo>.Type
      """
    let output = """
      let type = [Foo].Type
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func arraySelfReferenceConvertedToSugar() {
    let input = """
      let type = Array<Foo>.self
      """
    let output = """
      let type = [Foo].self
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func swiftArraySelfReferenceConvertedToSugar() {
    let input = """
      let type = Swift.Array<Foo>.self
      """
    let output = """
      let type = [Foo].self
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func arrayDeclarationNotConvertedToSugar() {
    let input = """
      struct Array<Element> {}
      """
    testFormatting(for: input, rule: .typeSugar)
  }

  @Test func extensionTypeSugar() {
    let input = """
      extension Array<Foo> {}
      extension Optional<Foo> {}
      extension Dictionary<Foo, Bar> {}
      extension Optional<Array<Dictionary<Foo, Array<Bar>>>> {}
      """

    let output = """
      extension [Foo] {}
      extension Foo? {}
      extension [Foo: Bar] {}
      extension [[Foo: [Bar]]]? {}
      """
    testFormatting(for: input, output, rule: .typeSugar, exclude: [.emptyExtensions])
  }

  // dictionaries

  @Test func dictionaryTypeConvertedToSugar() {
    let input = """
      var foo: Dictionary<String, Int>
      """
    let output = """
      var foo: [String: Int]
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func swiftDictionaryTypeConvertedToSugar() {
    let input = """
      var foo: Swift.Dictionary<String, Int>
      """
    let output = """
      var foo: [String: Int]
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  // optionals

  @Test func optionalPropertyTypeNotConvertedToSugarByDefault() {
    let input = """
      struct Bar {
          var bar: Optional<String>
      }
      """
    testFormatting(for: input, rule: .typeSugar)
  }

  @Test func optionalTypeConvertedToSugar() {
    let input = """
      struct Bar {
          init() {
              foo = "foo"
          }

          var foo: Optional<String>
      }

      struct Baaz {
          var bar: Optional<String> = nil
          let bar: Optional<String>
      }

      struct Quuz {
          let bar: Optional<String>
      }
      """
    let output = """
      struct Bar {
          init() {
              foo = "foo"
          }

          var foo: String?
      }

      struct Baaz {
          var bar: String? = nil
          let bar: String?
      }

      struct Quuz {
          let bar: String?
      }
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func swiftOptionalTypeConvertedToSugar() {
    let input = """
      var foo: Swift.Optional<String>
      """
    let output = """
      var foo: String?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func optionalClosureParenthesizedConvertedToSugar() {
    let input = """
      var foo: Optional<(Int) -> String>
      """
    let output = """
      var foo: ((Int) -> String)?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func optionalTupleWrappedInParensConvertedToSugar() {
    let input = """
      let foo: Optional<(foo: Int, bar: String)>
      """
    let output = """
      let foo: (foo: Int, bar: String)?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func optionalComposedProtocolWrappedInParensConvertedToSugar() {
    let input = """
      let foo: Optional<UIView & Foo>
      """
    let output = """
      let foo: (UIView & Foo)?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func swiftOptionalClosureParenthesizedConvertedToSugar() {
    let input = """
      var foo: Swift.Optional<(Int) -> String>
      """
    let output = """
      var foo: ((Int) -> String)?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func strippingSwiftNamespaceInOptionalTypeWhenConvertedToSugar() {
    let input = """
      Swift.Optional<String>
      """
    let output = """
      String?
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  @Test func strippingSwiftNamespaceDoesNotStripPreviousSwiftNamespaceReferences() {
    let input = """
      let a: Swift.String = Optional<String>
      """
    let output = """
      let a: Swift.String = String?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func optionalTypeInsideCaseConvertedToSugar() {
    let input = """
      if case .some(Optional<Any>.some(let foo)) = bar else {}
      """
    let output = """
      if case .some(Any?.some(let foo)) = bar else {}
      """
    testFormatting(for: input, output, rule: .typeSugar, exclude: [.hoistPatternLet])
  }

  @Test func switchCaseOptionalNotReplaced() {
    let input = """
      switch foo {
      case Optional<Any>.none:
      }
      """
    testFormatting(for: input, rule: .typeSugar)
  }

  @Test func caseOptionalNotReplaced2() {
    let input = """
      if case Optional<Any>.none = foo {}
      """
    testFormatting(for: input, rule: .typeSugar)
  }

  @Test func unwrappedOptionalSomeParenthesized() {
    let input = """
      func foo() -> Optional<some Publisher<String, Never>> {}
      """
    let output = """
      func foo() -> (some Publisher<String, Never>)? {}
      """
    testFormatting(for: input, output, rule: .typeSugar)
  }

  // swift parser bug

  @Test func avoidSwiftParserBugWithClosuresInsideArrays() {
    let input = """
      var foo = Array<(_ image: Data?) -> Void>()
      """
    testFormatting(
      for: input, rule: .typeSugar, options: FormatOptions(shortOptionals: .always),
      exclude: [.propertyTypes])
  }

  @Test func avoidSwiftParserBugWithClosuresInsideDictionaries() {
    let input = """
      var foo = Dictionary<String, (_ image: Data?) -> Void>()
      """
    testFormatting(
      for: input, rule: .typeSugar, options: FormatOptions(shortOptionals: .always),
      exclude: [.propertyTypes])
  }

  @Test func avoidSwiftParserBugWithClosuresInsideOptionals() {
    let input = """
      var foo = Optional<(_ image: Data?) -> Void>()
      """
    testFormatting(
      for: input, rule: .typeSugar, options: FormatOptions(shortOptionals: .always),
      exclude: [.propertyTypes])
  }

  @Test func dontOverApplyBugWorkaround() {
    let input = """
      var foo: Array<(_ image: Data?) -> Void>
      """
    let output = """
      var foo: [(_ image: Data?) -> Void]
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func dontOverApplyBugWorkaround2() {
    let input = """
      var foo: Dictionary<String, (_ image: Data?) -> Void>
      """
    let output = """
      var foo: [String: (_ image: Data?) -> Void]
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func dontOverApplyBugWorkaround3() {
    let input = """
      var foo: Optional<(_ image: Data?) -> Void>
      """
    let output = """
      var foo: ((_ image: Data?) -> Void)?
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(for: input, output, rule: .typeSugar, options: options)
  }

  @Test func dontOverApplyBugWorkaround4() {
    let input = """
      var foo = Array<(image: Data?) -> Void>()
      """
    let output = """
      var foo = [(image: Data?) -> Void]()
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(
      for: input, output, rule: .typeSugar, options: options, exclude: [.propertyTypes])
  }

  @Test func dontOverApplyBugWorkaround5() {
    let input = """
      var foo = Array<(Data?) -> Void>()
      """
    let output = """
      var foo = [(Data?) -> Void]()
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(
      for: input, output, rule: .typeSugar, options: options, exclude: [.propertyTypes])
  }

  @Test func dontOverApplyBugWorkaround6() {
    let input = """
      var foo = Dictionary<Int, Array<(_ image: Data?) -> Void>>()
      """
    let output = """
      var foo = [Int: Array<(_ image: Data?) -> Void>]()
      """
    let options = FormatOptions(shortOptionals: .always)
    testFormatting(
      for: input, output, rule: .typeSugar, options: options, exclude: [.propertyTypes])
  }
}
