import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireSyncEngineSavedStateTests: RuleTesting {
    private static let message =
        "'stateSerialization: nil' makes the sync engine start over on every launch; pass the state that the last '.stateUpdate' event saved"

    @Test func nilStateFlagged() {
        assertLint(
            RequireSyncEngineSavedState.self,
            """
            let configuration = CKSyncEngine.Configuration(
                database: container.privateCloudDatabase,
                1️⃣stateSerialization: nil,
                delegate: self
            )
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func explicitInitFlagged() {
        assertLint(
            RequireSyncEngineSavedState.self,
            """
            let configuration = CKSyncEngine.Configuration.init(
                database: database, 1️⃣stateSerialization: nil, delegate: self)
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func savedStateNotFlagged() {
        assertLint(
            RequireSyncEngineSavedState.self,
            """
            let configuration = CKSyncEngine.Configuration(
                database: database,
                stateSerialization: store.lastStateSerialization,
                delegate: self
            )
            """,
            findings: []
        )
    }

    @Test func otherConfigurationNotFlagged() {
        assertLint(
            RequireSyncEngineSavedState.self,
            """
            let configuration = Engine.Configuration(stateSerialization: nil)
            let other = Configuration(stateSerialization: nil)
            """,
            findings: []
        )
    }
}
