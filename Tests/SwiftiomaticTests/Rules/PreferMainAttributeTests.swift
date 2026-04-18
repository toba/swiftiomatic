@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ApplicationMainTests: RuleTesting {
  @Test func uiApplicationMain() {
    assertFormatting(
      PreferMainAttribute.self,
      input: """
        1️⃣@UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """,
      expected: """
        @main
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '@UIApplicationMain' with '@main'"),
      ]
    )
  }

  @Test func nsApplicationMain() {
    assertFormatting(
      PreferMainAttribute.self,
      input: """
        1️⃣@NSApplicationMain
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """,
      expected: """
        @main
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '@NSApplicationMain' with '@main'"),
      ]
    )
  }

  @Test func alreadyMain() {
    assertFormatting(
      PreferMainAttribute.self,
      input: """
        @main
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """,
      expected: """
        @main
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """,
      findings: []
    )
  }

  @Test func otherAttributesNotModified() {
    assertFormatting(
      PreferMainAttribute.self,
      input: """
        @objc
        class Foo {}
        """,
      expected: """
        @objc
        class Foo {}
        """,
      findings: []
    )
  }
}
