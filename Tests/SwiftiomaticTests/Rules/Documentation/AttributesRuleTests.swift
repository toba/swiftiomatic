import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct AttributesRuleTests {
  @Test func attributesWithAlwaysOnSameLine() async {
    // Test with custom `always_on_same_line`
    let nonTriggeringExamples = [
      Example("@objc var x: String"),
      Example("@objc func foo()"),
      Example("@nonobjc\n func foo()"),
      Example(
        """
        class Foo {
            @objc private var object: RLMWeakObjectHandle?
            @objc private var property: RLMProperty?
        }
        """,
      ),
      Example(
        """
        @objc(XYZFoo) class Foo: NSObject {}
        """,
      ),
    ]
    let triggeringExamples = [
      Example("@objc\n ↓var x: String"),
      Example("@objc\n ↓func foo()"),
      Example("@nonobjc ↓func foo()"),
    ]

    let alwaysOnSameLineDescription = TestExamples(from: AttributesRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      alwaysOnSameLineDescription,
      ruleConfiguration: ["always_on_same_line": ["@objc"]],
    )
  }

  @Test func attributesWithAlwaysOnLineAbove() async {
    // Test with custom `always_on_line_above`
    let nonTriggeringExamples = [
      Example("@objc\n var x: String"),
      Example("@objc\n func foo()"),
      Example("@nonobjc\n func foo()"),
    ]
    let triggeringExamples = [
      Example("@objc ↓var x: String"),
      Example("@objc ↓func foo()"),
      Example("@nonobjc ↓func foo()"),
    ]

    let alwaysOnNewLineDescription = TestExamples(from: AttributesRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      alwaysOnNewLineDescription,
      ruleConfiguration: ["always_on_line_above": ["@objc"]],
    )
  }

  @Test func attributesWithAttributesOnLineAboveButOnOtherDeclaration() async {
    let nonTriggeringExamples = [
      Example(
        """
        @IBDesignable open class TagListView: UIView {
            @IBInspectable open dynamic var textColor: UIColor = UIColor.white {
                didSet {}
            }
        }
        """,
      ),
      Example(
        """
        @objc public protocol TagListViewDelegate {
            @objc optional func tagDidSelect(_ title: String, sender: TagListView)
            @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
        }
        """,
      ),
    ]

    let triggeringExamples = [
      Example(
        """
        @IBDesignable open class TagListView: UIView {
            @IBInspectable
            open dynamic ↓var textColor: UIColor = UIColor.white {
                didSet {}
            }
        }
        """,
      ),
      Example(
        """
        @objc public protocol TagListViewDelegate {
            @objc
            optional ↓func tagDidSelect(_ title: String, sender: TagListView)
            @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
        }
        """,
      ),
    ]

    let alwaysOnNewLineDescription = TestExamples(from: AttributesRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      alwaysOnNewLineDescription,
      ruleConfiguration: [
        "always_on_same_line": [
          "@discardableResult", "@objc", "@IBAction", "@IBDesignable",
        ]
      ],
    )
  }

  @Test func attributesWithArgumentsAlwaysOnLineAboveFalse() async {
    let nonTriggeringExamples = [
      Example("@Environment(\\.presentationMode) private var presentationMode")
    ]
    let triggeringExamples = [
      Example(
        """
        @Environment(\\.presentationMode)
        private ↓var presentationMode
        """,
      )
    ]

    let argumentsAlwaysOnLineDescription = TestExamples(from: AttributesRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      argumentsAlwaysOnLineDescription,
      ruleConfiguration: ["attributes_with_arguments_always_on_line_above": false],
    )
  }

  @Test func attributesWithArgumentsAlwaysOnLineAboveTrue() async {
    let nonTriggeringExamples = [
      Example("@Environment(\\.presentationMode)\nprivate var presentationMode")
    ]
    let triggeringExamples = [
      Example("@Environment(\\.presentationMode) private ↓var presentationMode")
    ]

    let argumentsAlwaysOnLineDescription = TestExamples(from: AttributesRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      argumentsAlwaysOnLineDescription,
      ruleConfiguration: ["attributes_with_arguments_always_on_line_above": true],
    )
  }
}
