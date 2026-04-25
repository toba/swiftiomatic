@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WeakDelegatesTests: RuleTesting {

    @Test func plainDelegateInClassTriggers() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                1️⃣var delegate: SomeProtocol?
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "declare 'delegate' property as 'weak' to avoid retain cycles")
            ]
        )
    }

    @Test func suffixedDelegateInClassTriggers() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                1️⃣var scrollDelegate: ScrollDelegate?
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "declare 'delegate' property as 'weak' to avoid retain cycles")
            ]
        )
    }

    @Test func delegateWithDidSetTriggers() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                1️⃣var delegate: SomeProtocol? {
                    didSet {
                        print("Updated delegate")
                    }
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "declare 'delegate' property as 'weak' to avoid retain cycles")
            ]
        )
    }

    @Test func weakDelegateAccepted() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                weak var delegate: SomeProtocol?
                weak var someDelegate: SomeDelegateProtocol?
                weak var delegateScroll: ScrollDelegate?
            }
            """,
            findings: []
        )
    }

    @Test func unownedDelegateAccepted() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                unowned var delegate: SomeProtocol
            }
            """,
            findings: []
        )
    }

    @Test func nonDelegateNameIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                var scrollHandler: ScrollDelegate?
                var delegateNotified: Bool?
            }
            """,
            findings: []
        )
    }

    @Test func localVariableIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            func foo() {
                var delegate: SomeDelegate
            }
            """,
            findings: []
        )
    }

    @Test func protocolPropertyIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            protocol P {
                var delegate: AnyObject? { get set }
            }
            class Foo {
                protocol P {
                    var delegate: AnyObject? { get set }
                }
            }
            """,
            findings: []
        )
    }

    @Test func computedDelegateIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                var computedDelegate: ComputedDelegate {
                    return bar()
                }
                var explicitGetter: ComputedDelegate {
                    get {
                        return bar()
                    }
                }
            }
            """,
            findings: []
        )
    }

    @Test func adaptorAttributesIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            struct Foo {
                @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
            }
            struct Bar {
                @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
            }
            struct Baz {
                @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate
            }
            """,
            findings: []
        )
    }

    @Test func methodLocalDelegateIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                func makeDelegate() -> SomeDelegate {
                    let delegate = SomeDelegate()
                    return delegate
                }
            }
            """,
            findings: []
        )
    }

    @Test func computedPropertyLocalIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            class Foo {
                var bar: Bool {
                    let appDelegate = AppDelegate.bar
                    return appDelegate.bar
                }
            }
            """,
            findings: []
        )
    }

    @Test func topLevelDelegateIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            private var appDelegate: String?
            """,
            findings: []
        )
    }

    @Test func structDelegateIgnored() {
        assertLint(
            WeakDelegates.self,
            """
            struct Foo {
                var delegate: SomeDelegate?
            }
            """,
            findings: []
        )
    }
}
