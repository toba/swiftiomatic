import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoAccountChangedWithSyncEngineTests: RuleTesting {
    private static let message =
        "'CKAccountChanged' duplicates the '.accountChange' event of 'CKSyncEngine'; handle the account change in the sync engine delegate"

    @Test func sameFileSyncEngineFlagged() {
        assertLint(
            NoAccountChangedWithSyncEngine.self,
            """
            final class SyncManager {
                var engine: CKSyncEngine?

                func observe() {
                    NotificationCenter.default.addObserver(
                        self, selector: #selector(changed), name: .1️⃣CKAccountChanged, object: nil)
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func otherFileSyncEngineFlagged() {
        assertLint(
            NoAccountChangedWithSyncEngine.self,
            """
            func observe() async {
                for await _ in NotificationCenter.default.notifications(
                    named: NSNotification.Name.1️⃣CKAccountChanged) {}
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)],
            otherFiles: [
                "/tmp/SyncEngine.swift": """
                final class Sync {
                    let engine: CKSyncEngine
                    init(engine: CKSyncEngine) { self.engine = engine }
                }
                """
            ]
        )
    }

    @Test func noSyncEngineNotFlagged() {
        assertLint(
            NoAccountChangedWithSyncEngine.self,
            """
            func observe() {
                NotificationCenter.default.addObserver(
                    self, selector: #selector(changed), name: .CKAccountChanged, object: nil)
            }
            """,
            findings: [],
            otherFiles: [
                "/tmp/Other.swift": """
                final class Store {
                    let database: CKDatabase
                }
                """
            ]
        )
    }

    @Test func syncEngineInCommentNotFlagged() {
        assertLint(
            NoAccountChangedWithSyncEngine.self,
            """
            // Move to CKSyncEngine later.
            let name = Notification.Name.CKAccountChanged
            """,
            findings: [],
            otherFiles: [
                "/tmp/Notes.swift": """
                // CKSyncEngine is not used yet.
                let x = "CKSyncEngine"
                """
            ]
        )
    }
}
