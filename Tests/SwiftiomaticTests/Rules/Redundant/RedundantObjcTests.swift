@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantObjcTests: RuleTesting {
  @Test func objcWithIBAction() {
    assertFormatting(
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
      RedundantObjc.self,
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
