import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireBooleanAssertionNamesTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' is 'Bool' — start the name with 'is', 'has', 'can', 'should' or 'will' so it reads as an assertion"
  }

  @Test func booleanPropertyFlagged() {
    assertLint(
      RequireBooleanAssertionNames.self,
      """
      struct Session {
        var 1️⃣active: Bool
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("active"))]
    )
  }

  @Test func booleanMethodFlagged() {
    assertLint(
      RequireBooleanAssertionNames.self,
      """
      struct Session {
        func 1️⃣expired() -> Bool { false }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("expired"))]
    )
  }

  @Test func assertionPrefixNotFlagged() {
    assertLint(
      RequireBooleanAssertionNames.self,
      """
      struct Session {
        var isActive: Bool
        var hasToken: Bool
        var canRetry: Bool
        var shouldRefresh: Bool
        var willExpire: Bool
        func hasExpired() -> Bool { false }
      }
      """,
      findings: []
    )
  }

  @Test func nonBooleanNotFlagged() {
    assertLint(
      RequireBooleanAssertionNames.self,
      """
      struct Session {
        var count: Int
        func token() -> String { "" }
      }
      """,
      findings: []
    )
  }

  @Test func methodWithArgumentsNotFlagged() {
    assertLint(
      RequireBooleanAssertionNames.self,
      """
      struct Session {
        func matches(_ other: Session) -> Bool { false }
      }
      """,
      findings: []
    )
  }

  @Test func overrideNotFlagged() {
    assertLint(
      RequireBooleanAssertionNames.self,
      """
      final class Field: Control {
        override var active: Bool { true }
      }
      """,
      findings: []
    )
  }
}
