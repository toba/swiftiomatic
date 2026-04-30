@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WeakLetForUnreassignedWeakVarTests: RuleTesting {
  @Test func weakVarNeverReassigned() {
    assertLint(
      WeakLetForUnreassignedWeakVar.self,
      """
      class Foo {
        weak 1️⃣var delegate: AnyObject?
        init(delegate: AnyObject?) {
          self.delegate = delegate
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'delegate' is declared 'weak var' but never reassigned — prefer 'weak let' (SE-0481)"),
      ]
    )
  }

  @Test func weakVarReassignedOutsideInit() {
    assertLint(
      WeakLetForUnreassignedWeakVar.self,
      """
      class Foo {
        weak var delegate: AnyObject?
        func update(_ d: AnyObject) {
          self.delegate = d
        }
      }
      """,
      findings: []
    )
  }

  @Test func weakVarReassignedBareNameOutsideInit() {
    assertLint(
      WeakLetForUnreassignedWeakVar.self,
      """
      class Foo {
        weak var delegate: AnyObject?
        func update(_ d: AnyObject) {
          delegate = d
        }
      }
      """,
      findings: []
    )
  }

  @Test func weakVarOnActor() {
    assertLint(
      WeakLetForUnreassignedWeakVar.self,
      """
      actor Foo {
        weak 1️⃣var delegate: AnyObject?
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'delegate' is declared 'weak var' but never reassigned — prefer 'weak let' (SE-0481)"),
      ]
    )
  }

  @Test func nonWeakVarIgnored() {
    assertLint(
      WeakLetForUnreassignedWeakVar.self,
      """
      class Foo {
        var count: Int = 0
      }
      """,
      findings: []
    )
  }

  @Test func weakLetIgnored() {
    assertLint(
      WeakLetForUnreassignedWeakVar.self,
      """
      class Foo {
        weak let delegate: AnyObject?
        init(delegate: AnyObject?) {
          self.delegate = delegate
        }
      }
      """,
      findings: []
    )
  }
}
