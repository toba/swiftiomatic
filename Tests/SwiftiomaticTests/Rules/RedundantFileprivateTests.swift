@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantFileprivateTests: RuleTesting {

  // MARK: - Single-type files (should change)

  @Test func singleStructFileprivateVarChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate var foo = "foo"
        }
        """,
      expected: """
        struct Foo {
            private var foo = "foo"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleStructWithImportsChangesToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        import Foundation

        struct Foo {
            1️⃣fileprivate var foo = "foo"
        }
        """,
      expected: """
        import Foundation

        struct Foo {
            private var foo = "foo"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleClassFileprivateFuncChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        class Foo {
            1️⃣fileprivate func bar() {}
        }
        """,
      expected: """
        class Foo {
            private func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleEnumFileprivateChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        enum Foo {
            1️⃣fileprivate static func bar() {}
        }
        """,
      expected: """
        enum Foo {
            private static func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleActorFileprivateChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        actor Foo {
            1️⃣fileprivate var count = 0
        }
        """,
      expected: """
        actor Foo {
            private var count = 0
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleStructInitChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate init() {}
        }
        """,
      expected: """
        struct Foo {
            private init() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func sameTypeExtensionChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate let foo = "foo"
        }

        extension Foo {
            2️⃣fileprivate func bar() {
                print(foo)
            }
        }
        """,
      expected: """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            private func bar() {
                print(foo)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
        FindingSpec("2️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func multipleExtensionsOfSameType() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate var x = 1
        }

        extension Foo {
            2️⃣fileprivate func bar() {}
        }

        extension Foo {
            3️⃣fileprivate func baz() {}
        }
        """,
      expected: """
        struct Foo {
            private var x = 1
        }

        extension Foo {
            private func bar() {}
        }

        extension Foo {
            private func baz() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
        FindingSpec("2️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
        FindingSpec("3️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func fileprivateSetChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate(set) var x = 1
        }
        """,
      expected: """
        struct Foo {
            private(set) var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func subscriptChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate subscript(index: Int) -> Int { index }
        }
        """,
      expected: """
        struct Foo {
            private subscript(index: Int) -> Int { index }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func typealiasChangedToPrivate() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate typealias Bar = Int
        }
        """,
      expected: """
        struct Foo {
            private typealias Bar = Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleTypeWithInheritanceClause() {
    // Even with protocol conformance, if it's the only type, fileprivate == private.
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo: Equatable {
            1️⃣fileprivate var x = 1
        }
        """,
      expected: """
        struct Foo: Equatable {
            private var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func singleTypeInsideIfConfig() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        #if os(macOS)
        struct Foo {
            1️⃣fileprivate var x = 1
        }
        #endif
        """,
      expected: """
        #if os(macOS)
        struct Foo {
            private var x = 1
        }
        #endif
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  // MARK: - Multiple types (should NOT change)

  @Test func notChangedWhenMultipleTypes() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        struct Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """,
      expected: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        struct Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """,
      findings: []
    )
  }

  @Test func notChangedWhenAccessedFromSubclass() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        class Foo {
            fileprivate func foo() {}
        }

        class Bar: Foo {
            func bar() {
                return foo()
            }
        }
        """,
      expected: """
        class Foo {
            fileprivate func foo() {}
        }

        class Bar: Foo {
            func bar() {
                return foo()
            }
        }
        """,
      findings: []
    )
  }

  @Test func notChangedWhenAccessedFromFunction() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        func getFoo() -> String {
            return Foo().foo
        }
        """,
      expected: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        func getFoo() -> String {
            return Foo().foo
        }
        """,
      findings: []
    )
  }

  @Test func notChangedWhenAccessedFromTopLevelVar() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """,
      expected: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """,
      findings: []
    )
  }

  @Test func notChangedWhenAccessedFromTopLevelCode() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """,
      expected: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """,
      findings: []
    )
  }

  @Test func notChangedWhenExtensionOfDifferentType() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """,
      expected: """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """,
      findings: []
    )
  }

  // MARK: - Nested types (should NOT change)

  @Test func notChangedWhenHasNestedType() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate var x = 1

            struct Bar {
                func test(foo: Foo) {
                    print(foo.x)
                }
            }
        }
        """,
      expected: """
        struct Foo {
            fileprivate var x = 1

            struct Bar {
                func test(foo: Foo) {
                    print(foo.x)
                }
            }
        }
        """,
      findings: []
    )
  }

  @Test func notChangedWhenHasNestedEnum() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate enum Bar {
                case a, b
            }

            fileprivate let bar: Bar
        }
        """,
      expected: """
        struct Foo {
            fileprivate enum Bar {
                case a, b
            }

            fileprivate let bar: Bar
        }
        """,
      findings: []
    )
  }

  // MARK: - Members that should NOT be touched

  @Test func privateNotChanged() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            private var x = 1
        }
        """,
      expected: """
        struct Foo {
            private var x = 1
        }
        """,
      findings: []
    )
  }

  @Test func internalNotChanged() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            internal var x = 1
        }
        """,
      expected: """
        struct Foo {
            internal var x = 1
        }
        """,
      findings: []
    )
  }

  @Test func publicNotChanged() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            public var x = 1
        }
        """,
      expected: """
        struct Foo {
            public var x = 1
        }
        """,
      findings: []
    )
  }

  @Test func fileScopeFileprivateNotChanged() {
    // File-scope fileprivate is handled by FileScopedDeclarationPrivacy, not this rule.
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        fileprivate var foo = "foo"
        """,
      expected: """
        fileprivate var foo = "foo"
        """,
      findings: []
    )
  }

  // MARK: - Edge cases

  @Test func emptyFile() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """

        """,
      expected: """

        """,
      findings: []
    )
  }

  @Test func onlyImports() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        import Foundation
        """,
      expected: """
        import Foundation
        """,
      findings: []
    )
  }

  @Test func nestedTypeExtensionNotTreatedAsSameType() {
    // Extension of Foo.Bar is not the same logical type as Foo.
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            fileprivate var x = 1
        }

        extension Foo.Bar {
            func test() {}
        }
        """,
      expected: """
        struct Foo {
            fileprivate var x = 1
        }

        extension Foo.Bar {
            func test() {}
        }
        """,
      findings: []
    )
  }

  @Test func multipleFileprivateMembers() {
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate var x = 1
            2️⃣fileprivate let y = "hello"
            3️⃣fileprivate func bar() {}
            4️⃣fileprivate init(x: Int) { self.x = x }
        }
        """,
      expected: """
        struct Foo {
            private var x = 1
            private let y = "hello"
            private func bar() {}
            private init(x: Int) { self.x = x }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
        FindingSpec("2️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
        FindingSpec("3️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
        FindingSpec("4️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }

  @Test func extensionWithProtocolConformance() {
    // Extension with protocol conformance of the same type — still single type.
    assertFormatting(
      RedundantFileprivate.self,
      input: """
        struct Foo {
            1️⃣fileprivate var x = 1
        }

        extension Foo: CustomStringConvertible {
            var description: String { "\\(x)" }
        }
        """,
      expected: """
        struct Foo {
            private var x = 1
        }

        extension Foo: CustomStringConvertible {
            var description: String { "\\(x)" }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'fileprivate' with 'private'; no other type in this file needs broader access"),
      ]
    )
  }
}
