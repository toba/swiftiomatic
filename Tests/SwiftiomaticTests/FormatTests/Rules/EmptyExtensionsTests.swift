import Testing

@testable import Swiftiomatic

@Suite struct EmptyExtensionsTests {
  @Test func removeEmptyExtension() {
    let input = """
      extension String {}

      extension String: Equatable {}
      """
    let output = """
      extension String: Equatable {}
      """
    testFormatting(for: input, output, rule: .emptyExtensions)
  }

  @Test func removeNonConformingEmptyExtension() {
    let input = """
      extension [Foo: Bar] {}

      extension Array where Element: Foo {}
      """
    let output = """

      """
    testFormatting(for: input, output, rule: .emptyExtensions)
  }

  @Test func doNotRemoveEmptyConformingExtension() {
    let input = """
      extension String: Equatable {}
      extension Foo: @unchecked Sendable {}
      extension Bar: @retroactive @unchecked Sendable {}
      extension Module.Bar: @retroactive @unchecked Swift.Sendable {}
      """
    testFormatting(for: input, rule: .emptyExtensions)
  }

  @Test func doNotRemoveAtModifierEmptyExtension() {
    let input = """
      @GenerateBoilerPlate
      extension Foo {}
      """
    testFormatting(for: input, rule: .emptyExtensions)
  }

  @Test func removeEmptyExtensionWithEmptyBody() {
    let input = """
      extension Foo { }

      extension Foo {

      }
      """
    let output = """

      """
    testFormatting(for: input, output, rule: .emptyExtensions)
  }

  @Test func removeUnusedPrivateDeclarationThenEmptyExtension() {
    let input = """
      class Foo {
          init() {}
      }
      extension Foo {
          private var bar: Bar { "bar" }
      }
      """

    let output = """
      class Foo {
          init() {}
      }

      """
    testFormatting(for: input, [output], rules: [.unusedPrivateDeclarations, .emptyExtensions])
  }
}
