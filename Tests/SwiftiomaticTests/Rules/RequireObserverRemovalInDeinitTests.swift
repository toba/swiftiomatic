@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireObserverRemovalInDeinitTests: RuleTesting {

    @Test func removeSelfOutsideDeinitTriggers() {
        assertLint(
            RequireObserverRemovalInDeinit.self,
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
            RequireObserverRemovalInDeinit.self,
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
            RequireObserverRemovalInDeinit.self,
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
            RequireObserverRemovalInDeinit.self,
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
            RequireObserverRemovalInDeinit.self,
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
