@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DeinitObserverRemovalTests: RuleTesting {

    @Test func removeSelfOutsideDeinitTriggers() {
        assertLint(
            DeinitObserverRemoval.self,
            """
            class Foo {
                func bar() {
                    1️⃣NotificationCenter.default.removeObserver(self)
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "remove 'self' as a notification observer only in 'deinit'")
            ]
        )
    }

    @Test func removeSelfInDeinitAccepted() {
        assertLint(
            DeinitObserverRemoval.self,
            """
            class Foo {
                deinit {
                    NotificationCenter.default.removeObserver(self)
                }
            }
            """,
            findings: []
        )
    }

    @Test func removeOtherObjectAccepted() {
        assertLint(
            DeinitObserverRemoval.self,
            """
            class Foo {
                func bar() {
                    NotificationCenter.default.removeObserver(otherObject)
                }
            }
            """,
            findings: []
        )
    }

    @Test func multiArgumentRemoveObserverIgnored() {
        assertLint(
            DeinitObserverRemoval.self,
            """
            class Foo {
                func bar() {
                    NotificationCenter.default.removeObserver(self, name: .foo, object: nil)
                }
            }
            """,
            findings: []
        )
    }

    @Test func unrelatedRemoveObserverIgnored() {
        assertLint(
            DeinitObserverRemoval.self,
            """
            class Foo {
                func bar() {
                    other.removeObserver(self)
                }
            }
            """,
            findings: []
        )
    }
}
