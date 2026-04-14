@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct EnumNamespacesTests: RuleTesting {
  @Test func structWithOnlyStaticMembers() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Constants {
          static let foo = "foo"
          static let bar = "bar"
        }
        """,
      expected: """
        enum Constants {
          static let foo = "foo"
          static let bar = "bar"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func finalClassWithOnlyStaticMembers() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        final class 1️⃣Constants {
          static let foo = "foo"
          static func bar() {}
        }
        """,
      expected: """
        enum Constants {
          static let foo = "foo"
          static func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func nonFinalClassNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        class Constants {
          static let foo = "foo"
        }
        """,
      expected: """
        class Constants {
          static let foo = "foo"
        }
        """,
      findings: []
    )
  }

  @Test func structWithInstanceMember() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Foo {
          static let bar = "bar"
          let baz = "baz"
        }
        """,
      expected: """
        struct Foo {
          static let bar = "bar"
          let baz = "baz"
        }
        """,
      findings: []
    )
  }

  @Test func structWithInitializer() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Foo {
          static let bar = "bar"
          init() {}
        }
        """,
      expected: """
        struct Foo {
          static let bar = "bar"
          init() {}
        }
        """,
      findings: []
    )
  }

  @Test func structWithInheritance() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Foo: Codable {
          static let bar = "bar"
        }
        """,
      expected: """
        struct Foo: Codable {
          static let bar = "bar"
        }
        """,
      findings: []
    )
  }

  @Test func structWithAttributes() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        @MainActor
        struct Foo {
          static let bar = "bar"
        }
        """,
      expected: """
        @MainActor
        struct Foo {
          static let bar = "bar"
        }
        """,
      findings: []
    )
  }

  @Test func emptyStructNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Empty {}
        """,
      expected: """
        struct Empty {}
        """,
      findings: []
    )
  }

  @Test func enumNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        enum Constants {
          static let foo = "foo"
        }
        """,
      expected: """
        enum Constants {
          static let foo = "foo"
        }
        """,
      findings: []
    )
  }

  @Test func structWithNestedType() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Namespace {
          static let value = 42
          struct Nested {}
        }
        """,
      expected: """
        enum Namespace {
          static let value = 42
          struct Nested {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func structWithInstanceFunc() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Foo {
          static let bar = "bar"
          func baz() {}
        }
        """,
      expected: """
        struct Foo {
          static let bar = "bar"
          func baz() {}
        }
        """,
      findings: []
    )
  }

  @Test func genericStructNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Foo<T> {
          static let bar = "bar"
        }
        """,
      expected: """
        struct Foo<T> {
          static let bar = "bar"
        }
        """,
      findings: []
    )
  }
}
