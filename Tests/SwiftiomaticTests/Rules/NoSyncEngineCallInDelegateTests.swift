import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoSyncEngineCallInDelegateTests: RuleTesting {
    private static func message(_ call: String, _ method: String) -> String {
        "'\(call)()' inside '\(method)' makes the sync engine call its delegate again; let the engine schedule its own work"
    }

    @Test func fetchChangesInHandleEventFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            final class SyncDelegate: CKSyncEngineDelegate {
                func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
                    switch event {
                    case .accountChange:
                        try? await syncEngine.1️⃣fetchChanges()
                    default:
                        break
                    }
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("fetchChanges", "handleEvent(_:syncEngine:)"))
            ]
        )
    }

    @Test func sendChangesInNextBatchFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            extension SyncDelegate {
                func nextRecordZoneChangeBatch(
                    _ context: CKSyncEngine.SendChangesContext,
                    syncEngine: CKSyncEngine
                ) async -> CKSyncEngine.RecordZoneChangeBatch? {
                    try? await self.engine.1️⃣sendChanges(options)
                    return nil
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("sendChanges", "nextRecordZoneChangeBatch"))
            ]
        )
    }

    @Test func callInTaskInsideDelegateFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
                Task { try await syncEngine.1️⃣sendChanges() }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("sendChanges", "handleEvent(_:syncEngine:)"))
            ]
        )
    }

    @Test func callOutsideDelegateNotFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            final class SyncManager {
                func refresh() async throws {
                    try await engine.fetchChanges()
                    try await engine.sendChanges()
                }
            }
            """,
            findings: []
        )
    }

    @Test func otherHandleEventNotFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            func handleEvent(_ event: AppEvent) async throws {
                try await engine.fetchChanges()
            }
            """,
            findings: []
        )
    }

    @Test func nestedFunctionInDelegateNotFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
                func later() async throws { try await engine.fetchChanges() }
            }
            """,
            findings: []
        )
    }

    @Test func otherMethodNameNotFlagged() {
        assertLint(
            NoSyncEngineCallInDelegate.self,
            """
            func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
                try? await store.fetchChangesSince(token)
                fetchChanges()
            }
            """,
            findings: []
        )
    }
}
