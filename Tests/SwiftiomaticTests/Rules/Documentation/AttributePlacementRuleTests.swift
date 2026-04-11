import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct AttributesRuleTests {
  // MARK: - Non-triggering (default configuration)

  @Test func objcOnSameLineAsVarDoesNotTrigger() async {
    await assertNoViolation(AttributesRule.self, "@objc var x: String")
  }

  @Test func objcPrivateVarOnSameLineDoesNotTrigger() async {
    await assertNoViolation(AttributesRule.self, "@objc private var x: String")
  }

  @Test func availableOnOwnLineBeforeLetDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self, "@available(iOS 9.0, *)\n let stackView: UIStackView")
  }

  @Test func objcBeforeFuncOnOwnLineDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self, "@objc\n @IBAction func buttonPressed(button: UIButton)")
  }

  @Test func discardableResultOnOwnLineDoesNotTrigger() async {
    await assertNoViolation(AttributesRule.self, "@discardableResult\n func a() -> Int")
  }

  @Test func testableImportOnSameLineDoesNotTrigger() async {
    await assertNoViolation(AttributesRule.self, "@testable import SomeFramework")
  }

  @Test func nonobjcBeforeClassOnOwnLineDoesNotTrigger() async {
    await assertNoViolation(AttributesRule.self, "@nonobjc\n final class X {}")
  }

  @Test func attributeWithEmptyNewLineAboveDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self,
      """
      extension Property {

          @available(*, unavailable, renamed: "isOptional")
          public var optional: Bool { fatalError() }
      }
      """)
  }

  @Test func autoclosureInParameterDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self,
      "func increase(f: @autoclosure () -> Int) -> Int")
  }

  @Test func escapingClosureParameterDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self,
      "func foo(completionHandler: @escaping () -> Void)")
  }

  @Test func nsApplicationMainWithMainActorDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self,
      """
      import AppKit

      @NSApplicationMain
      @MainActor
      final class AppDelegate: NSAppDelegate {}
      """)
  }

  // MARK: - Triggering (default configuration)

  @Test func objcOnOwnLineBeforeVarTriggers() async {
    await assertLint(
      AttributesRule.self, "@objc\n 1️⃣var x: String",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func objcWithBlankLineBeforeVarTriggers() async {
    await assertLint(
      AttributesRule.self, "@objc\n\n 1️⃣var x: String",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ibOutletOnOwnLineBeforeVarTriggers() async {
    await assertLint(
      AttributesRule.self, "@IBOutlet\n private 1️⃣var label: UILabel",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func availableOnSameLineAsLetTriggers() async {
    await assertLint(
      AttributesRule.self, "@available(iOS 9.0, *) 1️⃣let stackView: UIStackView",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ibActionOnOwnLineBeforeFuncTriggers() async {
    await assertLint(
      AttributesRule.self, "@IBAction\n 1️⃣func buttonPressed(button: UIButton)",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func nonobjcOnSameLineBeforeClassTriggers() async {
    await assertLint(
      AttributesRule.self, "@nonobjc final 1️⃣class X {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func uiApplicationMainOnSameLineAsClassTriggers() async {
    await assertLint(
      AttributesRule.self,
      "@UIApplicationMain 1️⃣class AppDelegate: NSObject, UIApplicationDelegate {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func discardableResultOnSameLineAsFuncTriggers() async {
    await assertLint(
      AttributesRule.self, "@discardableResult 1️⃣func a() -> Int",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func testableOnOwnLineBeforeImportTriggers() async {
    await assertLint(
      AttributesRule.self, "@testable\n1️⃣import SomeFramework",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func availableWithBlankLineBeforeClassTriggers() async {
    await assertLint(
      AttributesRule.self, "@available(iOS 9.0, *)\n\n 1️⃣class UIStackView {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func environmentOnSameLineAsVarTriggersDefaultConfig() async {
    await assertLint(
      AttributesRule.self,
      #"""
      struct S: View {
          @Environment(\.colorScheme) 1️⃣var first: ColorScheme
          @Persisted var id: Int
          @FetchRequest(
                animation: nil
          )
          var entities: FetchedResults
      }
      """#,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Custom always_on_same_line

  @Test func objcOnSameLineDoesNotTriggerWithAlwaysOnSameLine() async {
    await assertNoViolation(
      AttributesRule.self, "@objc var x: String",
      configuration: ["always_on_same_line": ["@objc"]])
  }

  @Test func objcOnSameLineAsFuncDoesNotTriggerWithAlwaysOnSameLine() async {
    await assertNoViolation(
      AttributesRule.self, "@objc func foo()",
      configuration: ["always_on_same_line": ["@objc"]])
  }

  @Test func nonobjcOnOwnLineDoesNotTriggerWithAlwaysOnSameLineObjc() async {
    await assertNoViolation(
      AttributesRule.self, "@nonobjc\n func foo()",
      configuration: ["always_on_same_line": ["@objc"]])
  }

  @Test func objcOnOwnLineBeforeVarTriggersWithAlwaysOnSameLine() async {
    await assertLint(
      AttributesRule.self, "@objc\n 1️⃣var x: String",
      findings: [FindingSpec("1️⃣")],
      configuration: ["always_on_same_line": ["@objc"]])
  }

  @Test func objcOnOwnLineBeforeFuncTriggersWithAlwaysOnSameLine() async {
    await assertLint(
      AttributesRule.self, "@objc\n 1️⃣func foo()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["always_on_same_line": ["@objc"]])
  }

  @Test func nonobjcOnSameLineAsFuncTriggersWithAlwaysOnSameLineObjc() async {
    await assertLint(
      AttributesRule.self, "@nonobjc 1️⃣func foo()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["always_on_same_line": ["@objc"]])
  }

  // MARK: - Custom always_on_line_above

  @Test func objcOnOwnLineBeforeVarDoesNotTriggerWithAlwaysOnLineAbove() async {
    await assertNoViolation(
      AttributesRule.self, "@objc\n var x: String",
      configuration: ["always_on_line_above": ["@objc"]])
  }

  @Test func objcOnOwnLineBeforeFuncDoesNotTriggerWithAlwaysOnLineAbove() async {
    await assertNoViolation(
      AttributesRule.self, "@objc\n func foo()",
      configuration: ["always_on_line_above": ["@objc"]])
  }

  @Test func objcOnSameLineAsVarTriggersWithAlwaysOnLineAbove() async {
    await assertLint(
      AttributesRule.self, "@objc 1️⃣var x: String",
      findings: [FindingSpec("1️⃣")],
      configuration: ["always_on_line_above": ["@objc"]])
  }

  @Test func objcOnSameLineAsFuncTriggersWithAlwaysOnLineAbove() async {
    await assertLint(
      AttributesRule.self, "@objc 1️⃣func foo()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["always_on_line_above": ["@objc"]])
  }

  @Test func nonobjcOnSameLineAsFuncTriggersWithAlwaysOnLineAbove() async {
    await assertLint(
      AttributesRule.self, "@nonobjc 1️⃣func foo()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["always_on_line_above": ["@objc"]])
  }

  // MARK: - always_on_same_line overrides on other declarations

  @Test func ibDesignableWithIBInspectableOnSameLineDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self,
      """
      @IBDesignable open class TagListView: UIView {
          @IBInspectable open dynamic var textColor: UIColor = UIColor.white {
              didSet {}
          }
      }
      """,
      configuration: [
        "always_on_same_line": ["@discardableResult", "@objc", "@IBAction", "@IBDesignable"]
      ])
  }

  @Test func objcOptionalFuncOnSameLineDoesNotTrigger() async {
    await assertNoViolation(
      AttributesRule.self,
      """
      @objc public protocol TagListViewDelegate {
          @objc optional func tagDidSelect(_ title: String, sender: TagListView)
          @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
      }
      """,
      configuration: [
        "always_on_same_line": ["@discardableResult", "@objc", "@IBAction", "@IBDesignable"]
      ])
  }

  @Test func ibInspectableOnOwnLineTriggers() async {
    await assertLint(
      AttributesRule.self,
      """
      @IBDesignable open class TagListView: UIView {
          @IBInspectable
          open dynamic 1️⃣var textColor: UIColor = UIColor.white {
              didSet {}
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "always_on_same_line": ["@discardableResult", "@objc", "@IBAction", "@IBDesignable"]
      ])
  }

  @Test func objcOnOwnLineBeforeOptionalFuncTriggers() async {
    await assertLint(
      AttributesRule.self,
      """
      @objc public protocol TagListViewDelegate {
          @objc
          optional 1️⃣func tagDidSelect(_ title: String, sender: TagListView)
          @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "always_on_same_line": ["@discardableResult", "@objc", "@IBAction", "@IBDesignable"]
      ])
  }

  // MARK: - attributes_with_arguments_always_on_line_above = false

  @Test func environmentOnSameLineDoesNotTriggerWhenArgsOnLineAboveFalse() async {
    await assertNoViolation(
      AttributesRule.self,
      #"@Environment(\.presentationMode) private var presentationMode"#,
      configuration: ["attributes_with_arguments_always_on_line_above": false])
  }

  @Test func environmentOnOwnLineTriggersWhenArgsOnLineAboveFalse() async {
    await assertLint(
      AttributesRule.self,
      """
      @Environment(\\.presentationMode)
      private 1️⃣var presentationMode
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["attributes_with_arguments_always_on_line_above": false])
  }

  // MARK: - attributes_with_arguments_always_on_line_above = true

  @Test func environmentOnOwnLineDoesNotTriggerWhenArgsOnLineAboveTrue() async {
    await assertNoViolation(
      AttributesRule.self,
      #"@Environment(\.presentationMode)"# + "\nprivate var presentationMode",
      configuration: ["attributes_with_arguments_always_on_line_above": true])
  }

  @Test func environmentOnSameLineTriggersWhenArgsOnLineAboveTrue() async {
    await assertLint(
      AttributesRule.self,
      #"@Environment(\.presentationMode) private 1️⃣var presentationMode"#,
      findings: [FindingSpec("1️⃣")],
      configuration: ["attributes_with_arguments_always_on_line_above": true])
  }
}
