import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireTaskPriorityTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "'Task.\(name)' does not inherit the priority of its caller. Pass 'priority:' to state how urgent the work is"
    }

    @Test func guidanceIsConsider() { #expect(RequireTaskPriority.guidance == .consider) }

    @Test func detachedWithoutPriorityFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            func refresh() {
              Task.1️⃣detached {
                await work()
              }
              Task.2️⃣immediateDetached(name: "sync") {
                await sync()
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("detached")),
                FindingSpec("2️⃣", message: Self.message("immediateDetached")),
            ]
        )
    }

    @Test func detachedMainActorClosureStillFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            struct Row: View {
              var body: some View {
                Text("x").onAppear {
                  Task.1️⃣detached { @MainActor in
                    await work()
                  }
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("detached"))]
        )
    }

    @Test func taskWithPriorityNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            func refresh() {
              Task(name: "refresh", priority: .utility) {
                await work()
              }
              Task.detached(priority: .background) {
                await work()
              }
            }
            """,
            findings: []
        )
    }

    /// `Task { }` and `Task.immediate { }` inherit the priority of the caller, so they need no
    /// explicit priority. From Thesis `SettingsInspector` and `OutlineView`.
    @Test func inheritingTasksNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            struct SettingsInspector: View {
              var body: some View {
                Button("Save") { Task(name: "SettingsInspector") { await save() } }
                  .onChange(of: revision) {
                    Task.immediate { await refresh() }
                  }
              }
            }

            @MainActor
            final class Controller {
              func buttonTapped() {
                Task { await save() }
              }
            }
            """,
            findings: []
        )
    }

    @Test func otherTaskMembersNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            func check() async {
              if Task.isCancelled { return }
              await Task.yield()
              try await Task.sleep(for: .seconds(1))
            }
            """,
            findings: []
        )
    }
}
