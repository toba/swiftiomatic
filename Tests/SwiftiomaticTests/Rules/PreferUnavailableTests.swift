@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferUnavailableTests: RuleTesting {

  @Test func emptyAvailableWithElseBody() {
    assertFormatting(
      PreferUnavailable.self,
      input: """
        if 1️⃣#available(iOS 14.0) {
        } else {
            legacyTrackingLogic()
        }
        """,
      expected: """
        if #unavailable(iOS 14.0) {
            legacyTrackingLogic()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '#unavailable' instead of '#available' with an empty body"),
      ]
    )
  }

  @Test func emptyUnavailableWithElseBody() {
    assertFormatting(
      PreferUnavailable.self,
      input: """
        if 1️⃣#unavailable(iOS 13) {
        } else {
            modernCode()
        }
        """,
      expected: """
        if #available(iOS 13) {
            modernCode()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '#available' instead of '#unavailable' with an empty body"),
      ]
    )
  }

  @Test func nonEmptyAvailableBodyNotChanged() {
    assertFormatting(
      PreferUnavailable.self,
      input: """
        if #available(iOS 9.0, *) {
            doSomething()
        } else {
            legacyDoSomething()
        }
        """,
      expected: """
        if #available(iOS 9.0, *) {
            doSomething()
        } else {
            legacyDoSomething()
        }
        """,
      findings: []
    )
  }

  @Test func chainedAvailabilityNotChanged() {
    assertFormatting(
      PreferUnavailable.self,
      input: """
        if #available(macOS 11.0, *) {
        } else if #available(macOS 10.15, *) {
            print("do some stuff")
        }
        """,
      expected: """
        if #available(macOS 11.0, *) {
        } else if #available(macOS 10.15, *) {
            print("do some stuff")
        }
        """,
      findings: []
    )
  }
}
