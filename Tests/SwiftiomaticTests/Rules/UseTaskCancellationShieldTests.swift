import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseTaskCancellationShieldTests: RuleTesting {
    private static let message =
        "a cancelled task can skip this cleanup — wrap it in 'withTaskCancellationShield' so it runs to completion (SE-0504)"

    @Test func awaitingDeferFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer { 1️⃣await connection.close() }
              await run()
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func multipleAwaitsEachFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer {
                1️⃣await flush()
                2️⃣await close()
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message), FindingSpec("2️⃣", message: Self.message),
            ]
        )
    }

    @Test func shieldedDeferNotFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer {
                await withTaskCancellationShield { await connection.close() }
              }
            }
            """,
            findings: []
        )
    }

    @Test func shieldedMultiStatementDeferNotFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer {
                await withTaskCancellationShield {
                  await flush()
                  await close()
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func awaitInsideNestedTaskNotFlagged() {
        // The await runs in an unstructured task, which the shield cannot reach.
        // 'UseAsyncDeferNotTask' owns this shape.
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer { Task { await connection.close() } }
            }
            """,
            findings: []
        )
    }

    @Test func awaitInsideNestedClosureNotFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer { items.forEach { _ in Task { await close() } } }
            }
            """,
            findings: []
        )
    }

    @Test func synchronousDeferNotFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              defer { connection.close() }
            }
            """,
            findings: []
        )
    }

    @Test func awaitOutsideDeferNotFlagged() {
        assertLint(
            UseTaskCancellationShield.self,
            """
            func load() async {
              await connection.close()
            }
            """,
            findings: []
        )
    }

    @Test func offByDefault() {
        #expect(UseTaskCancellationShield.defaultValue.lint == .no)
        #expect(UseTaskCancellationShield.defaultValue.rewrite == false)
    }
}
