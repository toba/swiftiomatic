@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireAccessInObservableMutexPropertyTests: RuleTesting {
    private static func getter(_ name: String) -> String {
        "call 'access(keyPath:)' in the getter of '\(name)'. Observation does not track the state that 'withLock' reads"
    }

    private static func setter(_ name: String) -> String {
        "call 'withMutation(keyPath:)' in the setter of '\(name)'. Observation does not see the change that 'withLock' makes"
    }

    @Test func implicitGetterFlagged() {
        assertLint(
            RequireAccessInObservableMutexProperty.self,
            """
            @Observable final class Counter {
              @ObservationIgnored private let state = Mutex(0)
              var 1️⃣count: Int { state.withLock { $0 } }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.getter("count"))]
        )
    }

    @Test func explicitGetterAndSetterFlagged() {
        assertLint(
            RequireAccessInObservableMutexProperty.self,
            """
            @Observable final class Counter {
              @ObservationIgnored private let state = Mutex(0)
              var count: Int {
                1️⃣get { state.withLock { $0 } }
                2️⃣set { state.withLock { $0 = newValue } }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.getter("count")),
                FindingSpec("2️⃣", message: Self.setter("count")),
            ]
        )
    }

    @Test func onlyUntrackedAccessorFlagged() {
        assertLint(
            RequireAccessInObservableMutexProperty.self,
            """
            @Observable final class Counter {
              @ObservationIgnored private let state = Mutex(0)
              var count: Int {
                get {
                  access(keyPath: \\.count)
                  return state.withLock { $0 }
                }
                1️⃣set { state.withLock { $0 = newValue } }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.setter("count"))]
        )
    }

    @Test func extensionOfObservableClassFlagged() {
        assertLint(
            RequireAccessInObservableMutexProperty.self,
            """
            @Observable final class Counter {
              @ObservationIgnored let state = Mutex(0)
            }

            extension Counter {
              var 1️⃣count: Int { state.withLock { $0 } }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.getter("count"))]
        )
    }

    @Test func trackedAccessorsNotFlagged() {
        assertLint(
            RequireAccessInObservableMutexProperty.self,
            """
            @Observable final class Counter {
              @ObservationIgnored private let state = Mutex(0)
              var count: Int {
                get {
                  access(keyPath: \\.count)
                  return state.withLock { $0 }
                }
                set {
                  withMutation(keyPath: \\.count) {
                    state.withLock { $0 = newValue }
                  }
                }
              }
              var total: Int {
                _$observationRegistrar.access(self, keyPath: \\.total)
                return state.withLock { $0 }
              }
            }
            """,
            findings: []
        )
    }

    @Test func nonObservableAndOtherShapesNotFlagged() {
        assertLint(
            RequireAccessInObservableMutexProperty.self,
            """
            final class Counter {
              private let state = Mutex(0)
              var count: Int { state.withLock { $0 } }
            }

            @Observable final class Model {
              @ObservationIgnored private let state = Mutex(0)
              var name = ""
              var label: String { name.uppercased() }
              static var shared: Int { lock.withLock { 0 } }
              func current() -> Int { state.withLock { $0 } }
              var stored = 0 {
                didSet { state.withLock { $0 = stored } }
              }
            }

            struct Snapshot {
              let state = Mutex(0)
              var count: Int { state.withLock { $0 } }
            }
            """,
            findings: []
        )
    }
}
