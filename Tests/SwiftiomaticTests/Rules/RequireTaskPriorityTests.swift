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

    @Test func settingsInspectorHelperFlagged() {
        // From Thesis `SettingsInspector`: a helper on a `View` that persists a setting.
        assertLint(
            RequireTaskPriority.self,
            """
            struct SettingsInspector: View {
              @State private var numbering = NumberingSettings()

              var body: some View {
                Button("Save") { saveNumbering(numbering) }
              }

              private func saveBibliography(_ settings: BibliographySettings) {
                1️⃣Task(name: "SettingsInspector") { await project.saveBibliography(settings, using: sqlite) }
              }

              private func saveNumbering(_ settings: NumberingSettings) {
                numbering = settings
                2️⃣Task(name: "SettingsInspector") { await project.saveNumbering(settings, using: sqlite) }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.initMessage),
                FindingSpec("2️⃣", message: Self.initMessage),
            ]
        )
    }

    @Test func mainActorClosureFlagged() {
        // From Thesis `View+windowFrameAutosave` and toba-ui `SubtleScroller`.
        assertLint(
            RequireTaskPriority.self,
            """
            private final class WindowFrameView: NSView {
              private func restoreFrame() {
                guard let frame = store.restore() else { return }
                1️⃣Task(name: "restore-window-frame") { @MainActor [weak self] in
                  self?.window?.setFrame(frame, display: true)
                }
              }
            }

            private struct ScrollerCustomizer: NSViewRepresentable {
              func updateNSView(_ view: NSView, context: Context) {
                2️⃣Task(name: "SubtleScroller") { @MainActor [coordinator = context.coordinator] in
                  coordinator.isInstalled = false
                }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.initMessage),
                FindingSpec("2️⃣", message: Self.initMessage),
            ]
        )
    }

    @Test func mainActorDeclarationFlagged() {
        assertLint(
            RequireTaskPriority.self,
            """
            @MainActor
            final class Controller {
              func buttonTapped() {
                1️⃣Task {
                  await save()
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.initMessage)]
        )
    }

    @Test func viewCallbacksFlagged() {
        // From Thesis `OutlineView` and `GoalsInspector`: tasks started in `onChange` and actions.
        assertLint(
            RequireTaskPriority.self,
            """
            struct OutlineView: View {
              var body: some View {
                List(rows) { row in Text(row.title) }
                  .onChange(of: project.numberingRevision) {
                    1️⃣Task(name: "OutlineView.refreshNumbers") {
                      await editor.document?.refreshResolvedNumbers()
                    }
                  }
              }
            }

            struct IssueListToolbar: ToolbarContent {
              var body: some ToolbarContent {
                ToolbarItem {
                  Button("Refresh") { 2️⃣Task { await refresh() } }
                }
              }
            }

            extension View {
              func attachments(_ urls: [URL]) -> some View {
                onChange(of: urls) { _, new in
                  Task.3️⃣immediate { for url in new { await load(url) } }
                }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.initMessage),
                FindingSpec("2️⃣", message: Self.initMessage),
                FindingSpec("3️⃣", message: Self.staticMessage("immediate")),
            ]
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
