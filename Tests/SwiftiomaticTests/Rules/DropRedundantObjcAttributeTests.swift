@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantObjcAttributeTests: RuleTesting {
  @Test func objcWithIBAction() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        1️⃣@objc @IBAction func buttonTapped() {}
        """,
      expected: """
        @IBAction func buttonTapped() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcWithIBOutlet() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        1️⃣@objc @IBOutlet var label: UILabel!
        """,
      expected: """
        @IBOutlet var label: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcWithNSManaged() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        1️⃣@objc @NSManaged var name: String
        """,
      expected: """
        @NSManaged var name: String
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcWithIBInspectable() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        1️⃣@objc @IBInspectable var borderWidth: CGFloat
        """,
      expected: """
        @IBInspectable var borderWidth: CGFloat
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcAloneNotFlagged() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        @objc func myMethod() {}
        """,
      expected: """
        @objc func myMethod() {}
        """,
      findings: []
    )
  }

  @Test func objcWithExplicitNameNotFlagged() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        @objc(buttonTapped:) @IBAction func buttonTapped(_ sender: Any) {}
        """,
      expected: """
        @objc(buttonTapped:) @IBAction func buttonTapped(_ sender: Any) {}
        """,
      findings: []
    )
  }

  @Test func ibActionAloneNotFlagged() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        @IBAction func buttonTapped() {}
        """,
      expected: """
        @IBAction func buttonTapped() {}
        """,
      findings: []
    )
  }

  @Test func noAttributesNotFlagged() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        func myMethod() {}
        """,
      expected: """
        func myMethod() {}
        """,
      findings: []
    )
  }

  @Test func objcWithGKInspectable() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        1️⃣@objc @GKInspectable var speed: Float
        """,
      expected: """
        @GKInspectable var speed: Float
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func objcOnSeparateLineWithIBAction() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        1️⃣@objc
        @IBAction func buttonTapped() {}
        """,
      expected: """
        @IBAction func buttonTapped() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func implyingAttributeFirstObjcSecond() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        @IBAction 1️⃣@objc func buttonTapped() {}
        """,
      expected: """
        @IBAction func buttonTapped() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }

  @Test func nestedInClass() {
    assertFormatting(
      DropRedundantObjcAttribute.self,
      input: """
        class ViewController {
            1️⃣@objc @IBAction func tap() {}
        }
        """,
      expected: """
        class ViewController {
            @IBAction func tap() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@objc'; it is implied by another attribute"),
      ]
    )
  }
}
