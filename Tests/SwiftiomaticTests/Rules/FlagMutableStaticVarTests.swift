@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagMutableStaticVarTests: RuleTesting {
  private static let message =
    "'static var' with mutable storage is not data-race-safe — use an actor, 'Mutex', '@TaskLocal', or convert to a computed 'static var { ... }'"

  @Test func staticVarStoredFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static 1️⃣var count = 0
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func staticVarTypedFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static 1️⃣var count: Int = 0
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func staticVarWithDidSetFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static 1️⃣var count = 0 {
          didSet { print(count) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func staticLetNotFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static let count = 0
      }
      """,
      findings: []
    )
  }

  @Test func staticVarComputedNotFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static var current: Int { compute() }
      }
      """,
      findings: []
    )
  }

  @Test func staticVarGetSetNotFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static var current: Int {
          get { _value }
          set { _value = newValue }
        }
      }
      """,
      findings: []
    )
  }

  @Test func instanceVarNotFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      struct Box {
        var count = 0
      }
      """,
      findings: []
    )
  }

  @Test func classVarStoredFlagged() {
    assertLint(
      FlagMutableStaticVar.self,
      """
      enum Counter {
        static 1️⃣var values: [Int] = []
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }
}
