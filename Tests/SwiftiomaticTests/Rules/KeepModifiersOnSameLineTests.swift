@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct KeepModifiersOnSameLineTests: RuleTesting {

  @Test func modifiersOnSeparateLines() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        1️⃣public
        private(set)
        var foo: Foo
        """,
      expected: """
        public private(set) var foo: Foo
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }

  @Test func singleModifierOnSeparateLine() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        1️⃣public
        var foo: Foo
        """,
      expected: """
        public var foo: Foo
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }

  @Test func nonisolatedOnSeparateLine() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        1️⃣nonisolated
        func bar() {}
        """,
      expected: """
        nonisolated func bar() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }

  @Test func multipleModifiersOnMultipleLines() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        public class Container {
          1️⃣public
          static
          final
          var foo: String = ""
        }
        """,
      expected: """
        public class Container {
          public static final var foo: String = ""
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }

  @Test func attributesRemainOnSeparateLines() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        @MainActor
        public var foo: Foo
        """,
      expected: """
        @MainActor
        public var foo: Foo
        """,
      findings: []
    )
  }

  @Test func attributesSeparateModifiersCollapsed() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        @MainActor
        1️⃣public
        private(set)
        var foo: Foo
        """,
      expected: """
        @MainActor
        public private(set) var foo: Foo
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }

  @Test func multipleAttributesNoModifierChange() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        @MainActor
        @Published
        public var foo: Foo
        """,
      expected: """
        @MainActor
        @Published
        public var foo: Foo
        """,
      findings: []
    )
  }

  @Test func alreadyOnSameLine() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        public private(set) var foo: Foo
        """,
      expected: """
        public private(set) var foo: Foo
        """,
      findings: []
    )
  }

  @Test func commentsPreserved() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        public
        // This is private setter
        private(set)
        var foo: Foo
        """,
      expected: """
        public
        // This is private setter
        private(set)
        var foo: Foo
        """,
      findings: []
    )
  }

  @Test func noModifiers() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        var foo: Foo
        func bar() {}
        class Baz {}
        """,
      expected: """
        var foo: Foo
        func bar() {}
        class Baz {}
        """,
      findings: []
    )
  }

  @Test func structDeclaration() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        1️⃣public
        struct MyStruct {
          2️⃣private
          var value: Int
        }
        """,
      expected: """
        public struct MyStruct {
          private var value: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
        FindingSpec("2️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }

  @Test func protocolDeclaration() {
    assertFormatting(
      KeepModifiersOnSameLine.self,
      input: """
        1️⃣public
        protocol MyProtocol {
          2️⃣static
          func someMethod()
        }
        """,
      expected: """
        public protocol MyProtocol {
          static func someMethod()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place all modifiers on the same line as the declaration keyword"),
        FindingSpec("2️⃣", message: "place all modifiers on the same line as the declaration keyword"),
      ]
    )
  }
}
