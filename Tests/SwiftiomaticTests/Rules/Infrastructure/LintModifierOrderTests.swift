import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct LintModifierOrderTests {
  // MARK: - typeMethods before acl

  @Test func typeMethodsBeforeAcl_classPublicFuncDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      public class SomeClass {
         class public func someFunc() {}
      }
      """,
      configuration: ["preferred_modifier_order": ["typeMethods", "acl"]])
  }

  @Test func typeMethodsBeforeAcl_staticPublicFuncDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      public class SomeClass {
         static public func someFunc() {}
      }
      """,
      configuration: ["preferred_modifier_order": ["typeMethods", "acl"]])
  }

  @Test func typeMethodsBeforeAcl_publicClassFuncViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      public class SomeClass {
         public class func someFunc() {}
      }
      """,
      configuration: ["preferred_modifier_order": ["typeMethods", "acl"]])
  }

  @Test func typeMethodsBeforeAcl_publicStaticFuncViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      public class SomeClass {
         public static func someFunc() {}
      }
      """,
      configuration: ["preferred_modifier_order": ["typeMethods", "acl"]])
  }

  // MARK: - Right-ordered modifier groups

  private static let rightOrderedConfig: [String: any Sendable] = [
    "preferred_modifier_order": [
      "acl",
      "typeMethods",
      "owned",
      "setterACL",
      "final",
      "mutators",
      "override",
    ]
  ]

  @Test func rightOrdered_weakInternalSetDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      "public protocol Foo: class {}\npublic weak internal(set) var bar: Foo? \n",
      configuration: Self.rightOrderedConfig)
  }

  @Test func rightOrdered_openFinalClassDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      "open final class Foo {"
        + "  fileprivate static  func bar() {} \n"
        + "  open class func barFoo() {} }",
      configuration: Self.rightOrderedConfig)
  }

  @Test func rightOrdered_privateMutatingDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      "public struct Foo {  private mutating func bar() {} }",
      configuration: Self.rightOrderedConfig)
  }

  @Test func rightOrdered_internalSetWeakViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      "public protocol Foo: class {} \npublic internal(set) weak var bar: Foo? \n",
      configuration: Self.rightOrderedConfig)
  }

  @Test func rightOrdered_finalPublicClassViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      "final public class Foo {"
        + "  static fileprivate func bar() {} \n"
        + "  class open func barFoo() {} }",
      configuration: Self.rightOrderedConfig)
  }

  @Test func rightOrdered_mutatingPrivateViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      "public struct Foo {  mutating private func bar() {} }",
      configuration: Self.rightOrderedConfig)
  }

  // MARK: - @-prefixed group

  private static let atPrefixedConfig: [String: any Sendable] = [
    "preferred_modifier_order": ["override", "acl", "owned", "final"]
  ]

  @Test func atPrefixed_objcOverrideInternalDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      #"""
      class Foo {
          @objc
          internal var bar: String {
             return "foo"
          }
      }
      class Bar: Foo {
         @objc
         override internal var bar: String {
             return "bar"
         }
      }
      """#,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_objcMembersPublicFinalDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      @objcMembers
      public final class Bar {}
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_ibOutletInternalWeakDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Foo {
          @IBOutlet internal weak var bar: UIView!
      }
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_ibActionInternalDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Foo {
          @IBAction internal func bar() {}
      }
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_ibActionOverrideInternalDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Bar: Foo {
          @IBAction override internal func bar() {}
      }
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_nsCopyingPublicFinalDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      #"""
      public class Foo {
         @NSCopying public final var foo:NSString = "s"
      }
      """#,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_nsCopyingPublicFinalVarDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      #"""
      public class Foo {
         @NSCopying public final var foo: NSString
      }
      """#,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_objcInternalOverrideViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      #"""
      class Foo {
          @objc
          internal var bar: String {
             return "foo"
          }
      }
      class Bar: Foo {
         @objc
          internal override var bar: String {
             return "bar"
          }
      }
      """#,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_objcMembersFinalPublicViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      @objcMembers
      final public class Bar {}
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_ibOutletWeakInternalViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      class Foo {
          @IBOutlet weak internal var bar: UIView!
      }
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_ibActionInternalOverrideViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      class Foo {
          @IBAction internal func bar() {}
      }

      class Bar: Foo {
          @IBAction internal override func bar() {}
      }
      """,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_nsCopyingFinalPublicViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      #"""
      public class Foo {
          @NSCopying final public var foo:NSString = "s"
      }
      """#,
      configuration: Self.atPrefixedConfig)
  }

  @Test func atPrefixed_nsManagedFinalPublicViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      public class Foo {
          @NSManaged final public var foo: NSString
      }
      """,
      configuration: Self.atPrefixedConfig)
  }

  // MARK: - Non-specified modifiers don't interfere

  private static let finalOverrideAclConfig: [String: any Sendable] = [
    "preferred_modifier_order": ["final", "override", "acl"]
  ]

  @Test func nonSpecified_weakFinalOverridePrivateDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Foo {
          weak final override private var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_finalWeakOverridePrivateDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Foo {
          final weak override private var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_finalOverrideWeakPrivateDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Foo {
          final override weak private var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_finalOverridePrivateWeakDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class Foo {
          final override private weak var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_weakOverrideFinalPrivateViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      class Foo {
          weak override final private var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_overrideWeakFinalPrivateViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      class Foo {
          override weak final private var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_overrideFinalWeakPrivateViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      class Foo {
          override final weak private var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  @Test func nonSpecified_overrideFinalPrivateWeakViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      class Foo {
          override final private weak var bar: UIView?
      }
      """,
      configuration: Self.finalOverrideAclConfig)
  }

  // MARK: - Corrections

  private static let correctionConfig: [String: any Sendable] = [
    "preferred_modifier_order": [
      "final",
      "override",
      "acl",
      "typeMethods",
    ]
  ]

  @Test func correctsPrivateFinalOverride() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            private final override var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            final override private var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsPrivateFinal() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            private final var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            final private var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsClassPrivateFinal() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            class private final var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            final private class var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsObjcPrivateClassFinalOverride() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            @objc
            private
            class
            final
            override
            var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            @objc
            final
            override
            private
            class
            var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsPrivateFinalClass() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        private final class Foo {}
        """,
      expected: """
        final private class Foo {}
        """,
      configuration: Self.correctionConfig)
  }

  // MARK: - Corrections not applied to irrelevant modifiers

  @Test func correctsWeakClassFinal() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            weak class final var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            weak final class var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsStaticWeakFinal() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            static weak final var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            final static weak var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsClassFinalWeak() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            class final weak var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            final class weak var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func correctsObjcPrivatePrivateSetClassFinal() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            @objc
            private private(set) class final var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            @objc
            final private private(set) class var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  @Test func noChangeForUnmodifiedVar() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        class Foo {
            var bar: UIView?
        }
        """,
      expected: """
        class Foo {
            var bar: UIView?
        }
        """,
      configuration: Self.correctionConfig)
  }

  // MARK: - typeMethod class correction

  @Test func correctsPrivateFinalClassDecl() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        private final class Foo {}
        """,
      expected: """
        final private class Foo {}
        """,
      configuration: ["preferred_modifier_order": ["final", "typeMethods", "acl"]])
  }

  @Test func protocolClassNotCorrected() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: "public protocol Foo: class {}\n",
      expected: "public protocol Foo: class {}\n",
      configuration: ["preferred_modifier_order": ["final", "typeMethods", "acl"]])
  }

  // MARK: - Violation message

  @Test func violationMessage() async {
    await assertLint(
      ModifierOrderRule.self,
      "final public 1️⃣var foo: String",
      findings: [
        FindingSpec("1️⃣", message: "public modifier should come before final")
      ],
      configuration: ["preferred_modifier_order": ["acl", "final"]])
  }

  // MARK: - Isolation modifier order

  private static let isolationConfig: [String: any Sendable] = [
    "preferred_modifier_order": [
      "override",
      "isolation",
      "acl",
      "final",
    ]
  ]

  @Test func isolation_nonisolatedPublicDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      @MainActor
      class Foo {
          nonisolated public func bar() {}
      }
      """,
      configuration: Self.isolationConfig)
  }

  @Test func isolation_nonisolatedVarDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      actor MyActor: CustomStringConvertible {
          nonisolated var description: String {
              "MyActor instance"
          }
      }
      """,
      configuration: Self.isolationConfig)
  }

  @Test func isolation_mainActorPublicFuncDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      class RegularClass {
          @MainActor public func bar() {}
      }
      """,
      configuration: Self.isolationConfig)
  }

  @Test func isolation_publicNonisolatedViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      @MainActor
      class Foo {
          public nonisolated func bar() {}
      }
      """,
      configuration: Self.isolationConfig)
  }

  @Test func isolation_privateNonisolatedViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      @MainActor
      class RegularClass {
          private nonisolated func heavyWork() {}
      }
      """,
      configuration: Self.isolationConfig)
  }

  @Test func isolation_correctsPublicNonisolated() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        @MainActor
        class Foo {
            public nonisolated func bar() {}
        }
        """,
      expected: """
        @MainActor
        class Foo {
            nonisolated public func bar() {}
        }
        """,
      configuration: Self.isolationConfig)
  }

  // MARK: - Isolation modifier custom order (acl before isolation)

  private static let isolationCustomConfig: [String: any Sendable] = [
    "preferred_modifier_order": [
      "override",
      "acl",
      "isolation",
      "final",
    ]
  ]

  @Test func isolationCustom_publicNonisolatedFinalDoesNotTrigger() async {
    await assertNoViolation(
      ModifierOrderRule.self,
      """
      @MainActor
      class Foo {
          public nonisolated final func bar() {}
      }
      """,
      configuration: Self.isolationCustomConfig)
  }

  @Test func isolationCustom_nonisolatedPublicViolates() async {
    await assertViolates(
      ModifierOrderRule.self,
      """
      @MainActor
      class Foo {
          nonisolated public func bar() {}
      }
      """,
      configuration: Self.isolationCustomConfig)
  }

  @Test func isolationCustom_correctsNonisolatedPublic() async {
    await assertFormatting(
      ModifierOrderRule.self,
      input: """
        @MainActor
        class Foo {
            nonisolated public func bar() {}
        }
        """,
      expected: """
        @MainActor
        class Foo {
            public nonisolated func bar() {}
        }
        """,
      configuration: Self.isolationCustomConfig)
  }
}
