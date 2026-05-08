@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseWeakLetForUnreassignedTests: RuleTesting {
  @Test func weakVarNeverReassigned() {
    assertLint(
      UseWeakLetForUnreassigned.self,
      """
      class Foo {
        private weak 1️⃣var delegate: AnyObject?
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

  @Test func internalWeakVarNotFlagged() {
    // Internal/public/package properties may be reassigned from outside the
    // declaring type; only flag private/fileprivate where mutation is local.
    assertLint(
      UseWeakLetForUnreassigned.self,
      """
      class Child {
        weak var parent: Parent?
      }
      class Parent {
        init(children: [Child]) {
          for child in children { child.parent = self }
        }
      }
      """,
      findings: []
    )
  }

  @Test func fileprivateWeakVarFlagged() {
    assertLint(
      UseWeakLetForUnreassigned.self,
      """
      class Foo {
        fileprivate weak 1️⃣var delegate: AnyObject?
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
      UseWeakLetForUnreassigned.self,
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
      UseWeakLetForUnreassigned.self,
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
      UseWeakLetForUnreassigned.self,
      """
      actor Foo {
        private weak 1️⃣var delegate: AnyObject?
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'delegate' is declared 'weak var' but never reassigned — prefer 'weak let' (SE-0481)"),
      ]
    )
  }

  @Test func nonWeakVarIgnored() {
    assertLint(
      UseWeakLetForUnreassigned.self,
      """
      class Foo {
        var count: Int = 0
      }
      """,
      findings: []
    )
  }

  @Test func smIgnoreLoneLineSuppressesPerMember() {
    assertLint(
      UseWeakLetForUnreassigned.self,
      """
      class Foo {
        var a: Int = 0
        // sm:ignore useWeakLetForUnreassigned
        private weak var delegate: AnyObject?
      }
      """,
      findings: []
    )
  }

  @Test func smIgnoreTrailingSuppressesPerMember() {
    assertLint(
      UseWeakLetForUnreassigned.self,
      """
      class Foo {
        private weak var delegate: AnyObject? // sm:ignore useWeakLetForUnreassigned
      }
      """,
      findings: []
    )
  }

  @Test func weakLetIgnored() {
    assertLint(
      UseWeakLetForUnreassigned.self,
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
