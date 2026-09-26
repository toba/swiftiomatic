import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireTaskPriorityTests: RuleTesting {
    private static let initMessage =
        "'Task { ... }' has no priority; pass 'priority:' to state how urgent the work is"
    private static func staticMessage(_ name: String) -> String {
        "'Task.\(name)' has no priority; pass 'priority:' to state how urgent the work is"
    }

    @Test func taskInitWithoutPriorityFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            func refresh() {
              1️⃣Task(name: "refresh") {
                await work()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.initMessage)]
        )
    }

    @Test func detachedWithoutPriorityFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            func refresh() {
              Task.1️⃣detached {
                await work()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.staticMessage("detached"))]
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
            findings: [FindingSpec("1️⃣", message: Self.staticMessage("detached"))]
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

    @Test func mainActorClosureNotFlagged() {
        // From toba-ui `SubtleScroller`.
        assertLint(
            RequireTaskPriority.self,
            """
            private struct ScrollerCustomizer: NSViewRepresentable {
              func updateNSView(_ view: NSView, context: Context) {
                Task(name: "SubtleScroller") { @MainActor [coordinator = context.coordinator] in
                  coordinator.isInstalled = false
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func mainActorClosureOutsideUITypeNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            func refresh() {
              Task { @MainActor in
                label.text = "done"
              }
            }
            """,
            findings: []
        )
    }

    @Test func mainActorDeclarationNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            @MainActor
            final class Controller {
              func buttonTapped() {
                Task {
                  await save()
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func viewCallbackNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            struct Row: View {
              var body: some View {
                Button("Save") {
                  Task {
                    await save()
                  }
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func toolbarContentBodyNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            struct IssueListToolbar: ToolbarContent {
              var body: some ToolbarContent {
                ToolbarItem {
                  Button("Refresh") { Task { await refresh() } }
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func viewExtensionModifierNotFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            extension View {
              func attachments(_ urls: [URL]) -> some View {
                onChange(of: urls) { _, new in
                  Task { for url in new { await load(url) } }
                }
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
