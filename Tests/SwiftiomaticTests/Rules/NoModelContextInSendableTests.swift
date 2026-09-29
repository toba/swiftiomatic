import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoModelContextInSendableTests: RuleTesting {
    private static func message(_ property: String, _ type: String) -> String {
        "'\(property)' stores a 'ModelContext' in the Sendable type '\(type)'; store the 'ModelContainer' and create a context where you use it"
    }

    @Test func actorPropertyFlagged() {
        assertLint(
            NoModelContextInSendable.self,
            """
            actor Importer {
                private let 1️⃣context: ModelContext
                var 2️⃣backup = ModelContext(container)
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("context", "Importer")),
                FindingSpec("2️⃣", message: Self.message("backup", "Importer")),
            ]
        )
    }

    @Test func uncheckedSendableClassFlagged() {
        assertLint(
            NoModelContextInSendable.self,
            """
            final class Store: @unchecked Sendable {
                let 1️⃣context: SwiftData.ModelContext
                var 2️⃣other: ModelContext?
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("context", "Store")),
                FindingSpec("2️⃣", message: Self.message("other", "Store")),
            ]
        )
    }

    @Test func sendableStructFlagged() {
        assertLint(
            NoModelContextInSendable.self,
            """
            struct Handle: Hashable, Sendable {
                var 1️⃣context: ModelContext!
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("context", "Handle"))]
        )
    }

    @Test func extensionConformanceFlagged() {
        assertLint(
            NoModelContextInSendable.self,
            """
            final class Store {
                let 1️⃣context: ModelContext
            }

            extension Store: @unchecked Sendable {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("context", "Store"))]
        )
    }

    @Test func nonSendableTypeNotFlagged() {
        assertLint(
            NoModelContextInSendable.self,
            """
            @MainActor final class ViewModel {
                let context: ModelContext
            }

            struct Row {
                var context: ModelContext
            }
            """,
            findings: []
        )
    }

    @Test func containerAndComputedNotFlagged() {
        assertLint(
            NoModelContextInSendable.self,
            """
            actor Importer {
                let container: ModelContainer
                var context: ModelContext { ModelContext(container) }

                func run() {
                    let context = ModelContext(container)
                    _ = context
                }
            }
            """,
            findings: []
        )
    }
}
