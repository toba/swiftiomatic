//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantAccessControlTests: RuleTesting {

  // MARK: - RedundantInternal Tests

  @Test func redundantInternal_functionDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_classDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal class Foo {}
        """,
      expected: """
        class Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_structDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal struct Foo {}
        """,
      expected: """
        struct Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_enumDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal enum Foo {}
        """,
      expected: """
        enum Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_variableDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal var x = 1
        """,
      expected: """
        var x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_typealiasDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal typealias Foo = Int
        """,
      expected: """
        typealias Foo = Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_protocolDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal protocol Foo {}
        """,
      expected: """
        protocol Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_initializerDecl() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        struct Foo {
          1️⃣internal init() {}
        }
        """,
      expected: """
        struct Foo {
          init() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_internalWithOtherModifiers() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        1️⃣internal final class Foo {}
        """,
      expected: """
        final class Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_publicIsNotModified() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public func foo() {}
        """,
      expected: """
        public func foo() {}
        """,
      findings: []
    )
  }

  @Test func redundantInternal_privateIsNotModified() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        private func foo() {}
        """,
      expected: """
        private func foo() {}
        """,
      findings: []
    )
  }

  @Test func redundantInternal_noAccessLevelIsNotModified() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: []
    )
  }

  @Test func redundantInternal_internalSetIsNotModified() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public internal(set) var x = 1
        """,
      expected: """
        public internal(set) var x = 1
        """,
      findings: []
    )
  }

  @Test func redundantInternal_preservesLeadingComment() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        /// A function.
        1️⃣internal func foo() {}
        """,
      expected: """
        /// A function.
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantInternal_memberInsideClass() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public class Foo {
          1️⃣internal func bar() {}
          2️⃣internal var x = 1
        }
        """,
      expected: """
        public class Foo {
          func bar() {}
          var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
        FindingSpec("2️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  // MARK: - RedundantPublic Tests

  @Test func redundantPublic_publicMemberInInternalType() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        struct Foo {
          1️⃣public func bar() {}
          2️⃣public var x = 1
        }
        """,
      expected: """
        struct Foo {
          func bar() {}
          var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
        FindingSpec("2️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func redundantPublic_publicMemberInPrivateType() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        private class Foo {
          1️⃣public func bar() {}
        }
        """,
      expected: """
        private class Foo {
          func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func redundantPublic_publicMemberInPublicTypeNotFlagged() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public struct Foo {
          public func bar() {}
        }
        """,
      expected: """
        public struct Foo {
          public func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func redundantPublic_internalMemberNotFlagged() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        struct Foo {
          func bar() {}
        }
        """,
      expected: """
        struct Foo {
          func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func redundantPublic_publicMemberInEnum() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        enum Foo {
          1️⃣public static func make() -> Foo { .init() }
        }
        """,
      expected: """
        enum Foo {
          static func make() -> Foo { .init() }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func redundantPublic_packageTypeNotFlagged() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        package struct Foo {
          public func bar() {}
        }
        """,
      expected: """
        package struct Foo {
          public func bar() {}
        }
        """,
      findings: []
    )
  }

  // MARK: - RedundantExtensionACL Tests

  @Test func redundantExtensionACL_publicExtensionPublicMember() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public extension Foo {
          1️⃣public func bar() {}
          2️⃣public var x: Int { 1 }
        }
        """,
      expected: """
        public extension Foo {
          func bar() {}
          var x: Int { 1 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
        FindingSpec("2️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
      ]
    )
  }

  @Test func redundantExtensionACL_internalExtensionInternalMember() {
    // With the merged rule, `internal` on the member is removed by the redundant-internal
    // logic (depth-first traversal visits the function before the extension), so the
    // finding message comes from removeRedundantInternal rather than the extension ACL check.
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        internal extension Foo {
          1️⃣internal func bar() {}
        }
        """,
      expected: """
        internal extension Foo {
          func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantExtensionACL_differentAccessLevelNotFlagged() {
    // The extension ACL check doesn't flag members with different access levels.
    // However, `internal` is still removed by the redundant-internal logic.
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public extension Foo {
          1️⃣internal func bar() {}
          private func baz() {}
        }
        """,
      expected: """
        public extension Foo {
          func bar() {}
          private func baz() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantExtensionACL_noExtensionAccessLevelNotFlagged() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        extension Foo {
          public func bar() {}
        }
        """,
      expected: """
        extension Foo {
          public func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func redundantExtensionACL_memberWithNoAccessLevelNotFlagged() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public extension Foo {
          func bar() {}
        }
        """,
      expected: """
        public extension Foo {
          func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func redundantExtensionACL_publicSetNotFlagged() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public extension Foo {
          public(set) var x: Int { get { 1 } set {} }
        }
        """,
      expected: """
        public extension Foo {
          public(set) var x: Int { get { 1 } set {} }
        }
        """,
      findings: []
    )
  }

  @Test func redundantExtensionACL_memberWithOtherModifiers() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        public extension Foo {
          1️⃣public static func bar() {}
        }
        """,
      expected: """
        public extension Foo {
          static func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
      ]
    )
  }

  // MARK: - RedundantFileprivate: Single-type files (should change)

  @Test func redundantFileprivate_singleStructFileprivateVarChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleStructWithImportsChangesToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleClassFileprivateFuncChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleEnumFileprivateChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleActorFileprivateChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleStructInitChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_sameTypeExtensionChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_multipleExtensionsOfSameType() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_fileprivateSetChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_subscriptChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_typealiasChangedToPrivate() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleTypeWithInheritanceClause() {
    // Even with protocol conformance, if it's the only type, fileprivate == private.
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_singleTypeInsideIfConfig() {
    assertFormatting(
      RedundantAccessControl.self,
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

  // MARK: - RedundantFileprivate: Multiple types (should NOT change)

  @Test func redundantFileprivate_notChangedWhenMultipleTypes() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_notChangedWhenAccessedFromSubclass() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_notChangedWhenAccessedFromFunction() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_notChangedWhenAccessedFromTopLevelVar() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_notChangedWhenAccessedFromTopLevelCode() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_notChangedWhenExtensionOfDifferentType() {
    assertFormatting(
      RedundantAccessControl.self,
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

  // MARK: - RedundantFileprivate: Nested types (should NOT change)

  @Test func redundantFileprivate_notChangedWhenHasNestedType() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_notChangedWhenHasNestedEnum() {
    assertFormatting(
      RedundantAccessControl.self,
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

  // MARK: - RedundantFileprivate: Members that should NOT be touched

  @Test func redundantFileprivate_privateNotChanged() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_internalIsRemovedByRedundantInternalLogic() {
    // With the merged rule, `internal` is also removed (redundant internal logic).
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        struct Foo {
            1️⃣internal var x = 1
        }
        """,
      expected: """
        struct Foo {
            var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal' access modifier"),
      ]
    )
  }

  @Test func redundantFileprivate_publicIsRemovedByRedundantPublicLogic() {
    // With the merged rule, `public` on a member of a non-public type is also removed.
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        struct Foo {
            1️⃣public var x = 1
        }
        """,
      expected: """
        struct Foo {
            var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func redundantFileprivate_fileScopeFileprivateNotChanged() {
    // File-scope fileprivate is handled by FileScopedDeclarationPrivacy, not this rule.
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        fileprivate var foo = "foo"
        """,
      expected: """
        fileprivate var foo = "foo"
        """,
      findings: []
    )
  }

  // MARK: - RedundantFileprivate: Edge cases

  @Test func redundantFileprivate_emptyFile() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """

        """,
      expected: """

        """,
      findings: []
    )
  }

  @Test func redundantFileprivate_onlyImports() {
    assertFormatting(
      RedundantAccessControl.self,
      input: """
        import Foundation
        """,
      expected: """
        import Foundation
        """,
      findings: []
    )
  }

  @Test func redundantFileprivate_nestedTypeExtensionNotTreatedAsSameType() {
    // Extension of Foo.Bar is not the same logical type as Foo.
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_multipleFileprivateMembers() {
    assertFormatting(
      RedundantAccessControl.self,
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

  @Test func redundantFileprivate_extensionWithProtocolConformance() {
    // Extension with protocol conformance of the same type — still single type.
    assertFormatting(
      RedundantAccessControl.self,
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
