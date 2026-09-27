import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseAsyncDeferNotTaskTests: RuleTesting {
    private static let message =
        "a 'defer' body may await (SE-0493) — drop the 'Task' and call the cleanup directly so it finishes before the scope exits"

    @Test func taskInAsyncFunctionDeferFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async throws {
              let importer = Importer()
              defer { 1️⃣Task { await importer.close() } }
              try await importer.run()
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskDetachedFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              defer { 1️⃣Task.detached { await close() } }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskImmediateFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              defer { 1️⃣Task.immediate { await close() } }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskInAsyncClosureDeferFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            let work = {
              defer { 1️⃣Task { await close() } }
              await run()
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskInAsyncGetterFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            struct S {
              var value: Int {
                get async {
                  defer { 1️⃣Task { await close() } }
                  return 0
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskInSynchronousClosureNotFlagged() {
        // `forEach` takes a non-async closure, so `defer { await close() }` would not compile here.
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              items.forEach { item in
                defer { Task { await close() } }
                use(item)
              }
            }
            """,
            findings: []
        )
    }

    @Test func taskInTaskClosureFlagged() {
        // A `Task` body is always async, even with no `await` outside the defer.
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() {
              Task {
                defer { 1️⃣Task { await close() } }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskInExplicitlyAsyncClosureFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            let work: () async -> Void = { () async -> Void in
              defer { 1️⃣Task { await close() } }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskInSyncFunctionNotFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() {
              defer { Task { await close() } }
            }
            """,
            findings: []
        )
    }

    @Test func awaitingDeferNotFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              defer { await close() }
            }
            """,
            findings: []
        )
    }

    @Test func taskOutsideDeferNotFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              Task { await close() }
            }
            """,
            findings: []
        )
    }

    @Test func taskValueReferenceNotFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              defer { Task.isCancelled ? a() : b() }
            }
            """,
            findings: []
        )
    }

    @Test func taskInTaskModifierWithoutAwaitNotFlagged() {
        // Only a `Task` body counts as async by its call. A `.task` or task group closure counts
        // only when it awaits.
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func content() -> some View {
              Text("a").task {
                defer { Task { await close() } }
                start()
              }
            }
            """,
            findings: []
        )
    }

    @Test func taskInClosureWithNestedAwaitFlagged() {
        // Any `await` in the closure body outside the defer counts, including one in a nested
        // closure.
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() {
              run {
                defer { 1️⃣Task { await close() } }
                items.forEach { _ in Task { await step() } }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskGroupCallNotFlagged() {
        assertLint(
            UseAsyncDeferNotTask.self,
            """
            func load() async {
              defer { Task.yield() }
            }
            """,
            findings: []
        )
    }
}
