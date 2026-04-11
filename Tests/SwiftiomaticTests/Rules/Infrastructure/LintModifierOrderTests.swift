import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct LintModifierOrderTests {
  @Test func attributeTypeMethod() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [
          Example(
            """
            public class SomeClass {
               class public func someFunc() {}
            }
            """,
          ),
          Example(
            """
            public class SomeClass {
               static public func someFunc() {}
            }
            """,
          ),
        ],
        triggeringExamples: [
          Example(
            """
            public class SomeClass {
               public class func someFunc() {}
            }
            """,
          ),
          Example(
            """
            public class SomeClass {
               public static func someFunc() {}
            }
            """,
          ),
        ],
        corrections: [:],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: ["preferred_modifier_order": ["typeMethods", "acl"]],
    )
  }

  @Test func rightOrderedModifierGroups() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [
          Example("public protocol Foo: class {}\n" + "public weak internal(set) var bar: Foo? \n"),
          Example(
            "open final class Foo {" + "  fileprivate static  func bar() {} \n"
              + "  open class func barFoo() {} }",
          ),
          Example("public struct Foo {" + "  private mutating func bar() {} }"),
        ],
        triggeringExamples: [
          Example(
            "public protocol Foo: class {} \n" + "public internal(set) weak var bar: Foo? \n"),
          Example(
            "final public class Foo {" + "  static fileprivate func bar() {} \n"
              + "  class open func barFoo() {} }",
          ),
          Example("public struct Foo {" + "  mutating private func bar() {} }"),
        ],
        corrections: [:],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: [
        "preferred_modifier_order": [
          "acl",
          "typeMethods",
          "owned",
          "setterACL",
          "final",
          "mutators",
          "override",
        ]
      ],
    )
  }

  @Test func atPrefixedGroup() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [
          Example(
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
          ),
          Example(
            """
            @objcMembers
            public final class Bar {}
            """,
          ),
          Example(
            """
            class Foo {
                @IBOutlet internal weak var bar: UIView!
            }
            """,
          ),
          Example(
            """
            class Foo {
                @IBAction internal func bar() {}
            }
            """,
          ),
          Example(
            """
            class Bar: Foo {
                @IBAction override internal func bar() {}
            }
            """,
          ),
          Example(
            #"""
            public class Foo {
               @NSCopying public final var foo:NSString = "s"
            }
            """#,
          ),
          Example(
            #"""
            public class Foo {
               @NSCopying public final var foo: NSString
            }
            """#,
          ),
        ],
        triggeringExamples: [
          Example(
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
          ),
          Example(
            """
            @objcMembers
            final public class Bar {}
            """,
          ),
          Example(
            """
            class Foo {
                @IBOutlet weak internal var bar: UIView!
            }
            """,
          ),
          Example(
            """
            class Foo {
                @IBAction internal func bar() {}
            }

            class Bar: Foo {
                @IBAction internal override func bar() {}
            }
            """,
          ),
          Example(
            #"""
            public class Foo {
                @NSCopying final public var foo:NSString = "s"
            }
            """#,
          ),
          Example(
            """
            public class Foo {
                @NSManaged final public var foo: NSString
            }
            """,
          ),
        ],
        corrections: [:],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: ["preferred_modifier_order": ["override", "acl", "owned", "final"]],
    )
  }

  @Test func nonSpecifiedModifiersDontInterfere() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [
          Example(
            """
            class Foo {
                weak final override private var bar: UIView?
            }
            """,
          ),
          Example(
            """
            class Foo {
                final weak override private var bar: UIView?
            }
            """,
          ),
          Example(
            """
            class Foo {
                final override weak private var bar: UIView?
            }
            """,
          ),
          Example(
            """
            class Foo {
                final override private weak var bar: UIView?
            }
            """,
          ),
        ],
        triggeringExamples: [
          Example(
            """
            class Foo {
                weak override final private var bar: UIView?
            }
            """,
          ),
          Example(
            """
            class Foo {
                override weak final private var bar: UIView?
            }
            """,
          ),
          Example(
            """
            class Foo {
                override final weak private var bar: UIView?
            }
            """,
          ),
          Example(
            """
            class Foo {
                override final private weak var bar: UIView?
            }
            """,
          ),
        ],
        corrections: [:],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl"]],
    )
  }

  @Test func correctionsAreAppliedCorrectly() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [],
        triggeringExamples: [],
        corrections: [
          Example(
            """
            class Foo {
                private final override var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  final override private var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                private final var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  final private var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                class private final var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  final private class var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                @objc
                private
                class
                final
                override
                var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  @objc
                  final
                  override
                  private
                  class
                  var bar: UIView?
              }
              """,
            ),
          Example(
            """
            private final class Foo {}
            """,
          ):
            Example(
              """
              final private class Foo {}
              """,
            ),
        ],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: [
        "preferred_modifier_order": [
          "final",
          "override",
          "acl",
          "typeMethods",
        ]
      ],
    )
  }

  @Test func correctionsAreNotAppliedToIrrelevantModifier() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [],
        triggeringExamples: [],
        corrections: [
          Example(
            """
            class Foo {
                weak class final var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  weak final class var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                static weak final var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  final static weak var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                class final weak var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  final class weak var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                @objc
                private private(set) class final var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  @objc
                  final private private(set) class var bar: UIView?
              }
              """,
            ),
          Example(
            """
            class Foo {
                var bar: UIView?
            }
            """,
          ):
            Example(
              """
              class Foo {
                  var bar: UIView?
              }
              """,
            ),
        ],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: [
        "preferred_modifier_order": [
          "final",
          "override",
          "acl",
          "typeMethods",
        ]
      ],
    )
  }

  @Test func typeMethodClassCorrection() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [],
        triggeringExamples: [],
        corrections: [
          Example(
            """
            private final class Foo {}
            """,
          ):
            Example(
              """
              final private class Foo {}
              """,
            ),
          Example(
            """
            public protocol Foo: class {}\n
            """,
          ):
            Example(
              """
              public protocol Foo: class {}\n
              """,
            ),
        ],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: ["preferred_modifier_order": ["final", "typeMethods", "acl"]],
    )
  }

  @Test func violationMessage() async {
    let ruleID = ModifierOrderRule.identifier
    guard let config = makeConfig(["preferred_modifier_order": ["acl", "final"]], ruleID) else {
      Issue.record("Failed to create configuration")
      return
    }
    let allViolations = await violations(Example("final public var foo: String"), config: config)
    let modifierOrderRuleViolation = allViolations.first { $0.ruleIdentifier == ruleID }
    if let violation = modifierOrderRuleViolation {
      #expect(violation.reason == "public modifier should come before final")
    } else {
      Issue.record("A modifier order violation should have been triggered!")
    }
  }

  @Test func isolationModifierOrder() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [
          Example(
            """
            @MainActor
            class Foo {
                nonisolated public func bar() {}
            }
            """,
          ),
          Example(
            """
            actor MyActor: CustomStringConvertible {
                nonisolated var description: String {
                    "MyActor instance"
                }
            }
            """,
          ),
          Example(
            """
            class RegularClass {
                @MainActor public func bar() {}
            }
            """,
          ),
        ],
        triggeringExamples: [
          Example(
            """
            @MainActor
            class Foo {
                public nonisolated func bar() {}
            }
            """,
          ),
          Example(
            """
            @MainActor
            class RegularClass {
                private nonisolated func heavyWork() {}
            }
            """,
          ),
        ],
        corrections: [
          Example(
            """
            @MainActor
            class Foo {
                public nonisolated func bar() {}
            }
            """,
          ):
            Example(
              """
              @MainActor
              class Foo {
                  nonisolated public func bar() {}
              }
              """,
            )
        ],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: [
        "preferred_modifier_order": [
          "override",
          "isolation",
          "acl",
          "final",
        ]
      ],
    )
  }

  @Test func isolationModifierCustomOrder() async {
    let descriptionOverride = TestExamples(from: ModifierOrderRule.self)
      .with(
        nonTriggeringExamples: [
          Example(
            """
            @MainActor
            class Foo {
                public nonisolated final func bar() {}
            }
            """,
          )
        ],
        triggeringExamples: [
          Example(
            """
            @MainActor
            class Foo {
                nonisolated public func bar() {}
            }
            """,
          )
        ],
        corrections: [
          Example(
            """
            @MainActor
            class Foo {
                nonisolated public func bar() {}
            }
            """,
          ):
            Example(
              """
              @MainActor
              class Foo {
                  public nonisolated func bar() {}
              }
              """,
            )
        ],
      )

    await verifyRule(
      descriptionOverride,
      ruleConfiguration: [
        "preferred_modifier_order": [
          "override",
          "acl",
          "isolation",
          "final",
        ]
      ],
    )
  }
}
