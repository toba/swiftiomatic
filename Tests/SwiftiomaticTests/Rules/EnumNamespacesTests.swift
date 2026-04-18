@testable import SwiftiomaticKit
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

  // MARK: - Adapted from SwiftFormat reference tests

  @Test func finalClassWithInheritanceNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        private final class CustomUITableViewCell: UITableViewCell {}
        """,
      expected: """
        private final class CustomUITableViewCell: UITableViewCell {}
        """,
      findings: []
    )
  }

  @Test func classFunctionNotReplacedByEnum() {
    // class func implies inheritance — non-final class, skip
    assertFormatting(
      EnumNamespaces.self,
      input: """
        class Container {
          class func bar() {}
        }
        """,
      expected: """
        class Container {
          class func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func nestedNamespacesBothConvert() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Namespace {
          struct 2️⃣NestedNamespace {
            static let foo: Int
            static let bar: Int
          }
        }
        """,
      expected: """
        enum Namespace {
          enum NestedNamespace {
            static let foo: Int
            static let bar: Int
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
        FindingSpec("2️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func outerNamespaceWithNonNamespaceNested() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Namespace {
          struct TypeNestedInNamespace {
            let foo: Int
            let bar: Int
          }
        }
        """,
      expected: """
        enum Namespace {
          struct TypeNestedInNamespace {
            let foo: Int
            let bar: Int
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func localStructInsideStaticFunc() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Namespace {
          static func staticFunction() {
            struct NestedType {
              init() {}
            }
          }
        }
        """,
      expected: """
        enum Namespace {
          static func staticFunction() {
            struct NestedType {
              init() {}
            }
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func localFunctionInsideStaticFunc() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Namespace {
          static func staticFunction() {
            func nestedFunction() {}
          }
        }
        """,
      expected: """
        enum Namespace {
          static func staticFunction() {
            func nestedFunction() {}
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func structWithStaticFuncOnly() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct 1️⃣Constants {
          static func remoteConfig() -> Int {
            return 10
          }
        }
        """,
      expected: """
        enum Constants {
          static func remoteConfig() -> Int {
            return 10
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func structWithStaticAndInstanceFunction() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Constants {
          static func remoteConfig() -> Int {
            return 10
          }

          func instanceConfig(offset: Int) -> Int {
            return offset + 10
          }
        }
        """,
      expected: """
        struct Constants {
          static func remoteConfig() -> Int {
            return 10
          }

          func instanceConfig(offset: Int) -> Int {
            return offset + 10
          }
        }
        """,
      findings: []
    )
  }

  @Test func ifConfigWithInstanceFuncsNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct Foo {
          #if BAR
            func something() {}
          #else
            func something() {}
          #endif
        }
        """,
      expected: """
        struct Foo {
          #if BAR
            func something() {}
          #else
            func something() {}
          #endif
        }
        """,
      findings: []
    )
  }

  @Test func openClassNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        open class Foo {
          public static let bar = "bar"
        }
        """,
      expected: """
        open class Foo {
          public static let bar = "bar"
        }
        """,
      findings: []
    )
  }

  @Test func finalClassAfterImport() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        import Foundation

        final class 1️⃣MyViewModel {
          static let name = "A"
        }
        """,
      expected: """
        import Foundation

        enum MyViewModel {
          static let name = "A"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }

  @Test func objcAttributeSkipsConversion() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        @objc(NSFoo)
        final class Foo {
          static let name = "A"
        }
        """,
      expected: """
        @objc(NSFoo)
        final class Foo {
          static let name = "A"
        }
        """,
      findings: []
    )
  }

  @Test func macroAttributeSkipsConversion() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        @FooBar
        struct Foo {
          static let name = "A"
        }
        """,
      expected: """
        @FooBar
        struct Foo {
          static let name = "A"
        }
        """,
      findings: []
    )
  }

  @Test func parameterizedMacroSkipsConversion() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        @FooMacro(arg: "Foo")
        struct Foo {
          static let name = "A"
        }
        """,
      expected: """
        @FooMacro(arg: "Foo")
        struct Foo {
          static let name = "A"
        }
        """,
      findings: []
    )
  }

  @Test func instanceSubscriptNotModified() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        struct MyStruct {
          subscript(key: String) -> String {
            return key
          }
        }
        """,
      expected: """
        struct MyStruct {
          subscript(key: String) -> String {
            return key
          }
        }
        """,
      findings: []
    )
  }

  @Test func structInsideExtensionConverts() {
    assertFormatting(
      EnumNamespaces.self,
      input: """
        enum Namespace {}
        extension Namespace {
          struct 1️⃣Constants {
            static let bar = "bar"
          }
        }
        """,
      expected: """
        enum Namespace {}
        extension Namespace {
          enum Constants {
            static let bar = "bar"
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'enum' instead of 'struct' or 'class' for types with only static members"),
      ]
    )
  }
}
