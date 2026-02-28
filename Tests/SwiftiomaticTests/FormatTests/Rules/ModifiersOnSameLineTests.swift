import Testing

@testable import Swiftiomatic

@Suite struct ModifiersOnSameLineTests {
  // MARK: - modifiersOnSameLine

  @Test func modifiersOnSeparateLinesAreCombined() {
    let input = """
      public
      private(set)
      var foo: Foo
      """
    let output = """
      public private(set) var foo: Foo
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func singleModifierOnSeparateLineIsCombined() {
    let input = """
      public
      var foo: Foo
      """
    let output = """
      public var foo: Foo
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func nonisolatedModifierOnSeparateLineIsCombined() {
    let input = """
      nonisolated
      func bar() {}
      """
    let output = """
      nonisolated func bar() {}
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func multipleModifiersOnMultipleLinesAreCombined() {
    let input = """
      public class Container {
          public
          static
          final
          var foo: String = ""
      }
      """
    let output = """
      public class Container {
          public static final var foo: String = ""
      }
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine, exclude: [.modifierOrder])
  }

  @Test func attributesCanRemainOnSeparateLines() {
    let input = """
      @MainActor
      public var foo: Foo
      """
    testFormatting(for: input, rule: .modifiersOnSameLine)
  }

  @Test func attributesOnSeparateLinesWithModifiersOnSeparateLines() {
    let input = """
      @MainActor
      public
      private(set)
      var foo: Foo
      """
    let output = """
      @MainActor
      public private(set) var foo: Foo
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func multipleAttributesCanRemainOnSeparateLines() {
    let input = """
      @MainActor
      @Published
      public var foo: Foo
      """
    testFormatting(for: input, rule: .modifiersOnSameLine)
  }

  @Test func modifiersAlreadyOnSameLineAreNotChanged() {
    let input = """
      public private(set) var foo: Foo
      """
    testFormatting(for: input, rule: .modifiersOnSameLine)
  }

  @Test func commentsArePreserved() {
    let input = """
      public
      // This is private setter
      private(set)
      var foo: Foo
      """
    testFormatting(
      for: input, rule: .modifiersOnSameLine, exclude: [.docComments, .docCommentsBeforeModifiers])
  }

  @Test func declarationWithoutModifiersIsNotChanged() {
    let input = """
      var foo: Foo
      func bar() {}
      class Baz {}
      """
    testFormatting(for: input, rule: .modifiersOnSameLine)
  }

  @Test func onlyAttributesWithoutModifiers() {
    let input = """
      @MainActor
      var foo: Foo
      """
    testFormatting(for: input, rule: .modifiersOnSameLine)
  }

  @Test func modifiersInStructDeclaration() {
    let input = """
      public
      struct MyStruct {
          private
          var value: Int
      }
      """
    let output = """
      public struct MyStruct {
          private var value: Int
      }
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func modifiersInProtocolDeclaration() {
    let input = """
      public
      protocol MyProtocol {
          static
          func someMethod()
      }
      """
    let output = """
      public protocol MyProtocol {
          static func someMethod()
      }
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func modifiersWithComplexAccessControl() {
    let input = """
      public
      private(set)
      var complexProperty: String
      """
    let output = """
      public private(set) var complexProperty: String
      """
    testFormatting(for: input, output, rule: .modifiersOnSameLine)
  }

  @Test func doesNotConfusePropertyIdentifierWithModifier() {
    let input = """
      @Environment(\\.rowPaddingOverride) private var override
      private var resolvedRowPadding: AdaptiveEdgeInsets
      """
    testFormatting(for: input, rule: .modifiersOnSameLine)
  }

  @Test func doesNotUnwrapWhenLineWouldExceedMaxWidth() {
    let input = """
      public private(set)
      var propertyWithAReallyLongNameExceedingWidth: T
      """
    let options = FormatOptions(maxWidth: 50)
    testFormatting(for: input, rule: .modifiersOnSameLine, options: options)
  }
}
