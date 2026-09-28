import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseTaskIDNotTaskInOnChangeTests: RuleTesting {
    private static let message =
        "a 'Task' started in '.onChange(of:)' is not cancelled when the value changes again or the view goes away. Use '.task(id:)' with the same value"

    @Test func guidanceIsShould() { #expect(UseTaskIDNotTaskInOnChange.guidance == .should) }

    private static func helperMessage(_ helper: String) -> String {
        "'\(helper)' starts a 'Task' that '.onChange(of:)' does not cancel when the value changes again or the view goes away. Make the work async and await it from '.task(id:)' with the same value"
    }

    /// The musup `TrackInspector` and Thesis `SidebarRow` shapes: the action calls a method of the
    /// view, and that method or one it calls starts the task.
    @Test func taskStartedByHelperMethodFlagged() {
        assertLint(
            UseTaskIDNotTaskInOnChange.self,
            """
            struct TrackInspector: View {
              var body: some View {
                Form {}
                  .onChange(of: focused) { previous, _ in 1️⃣commit(previous) }
                  .onChange(of: pendingRenameID, initial: true) { 2️⃣self.claimPendingRename() }
                  .onChange(of: other) { plain(); recurse(); model.save() }
              }
              private func commit(_ field: Field?) { write(field) }
              private func write(_ field: Field?) {
                Task(name: "Write the track tags") { await save(field) }
              }
              private func claimPendingRename() { beginRename() }
              private func beginRename() { Task.immediate { focus = .name } }
              private func plain() { print("x") }
              private func recurse() { recurse() }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.helperMessage("commit")),
                FindingSpec("2️⃣", message: Self.helperMessage("claimPendingRename")),
            ]
        )
    }

    /// The Thesis `OutlineView` shape: a named task in an `.onChange(of:)` action.
    @Test func namedTaskInOnChangeFlagged() {
        assertLint(
            UseTaskIDNotTaskInOnChange.self,
            """
            struct OutlineView: View {
              var body: some View {
                OutlineList(rows)
                  .onChange(of: project.numberingRevision) {
                    // The write has landed, so refetch the numbers.
                    1️⃣Task(name: "OutlineView.refreshNumbers") {
                      await editor.document?.refreshResolvedNumbers()
                      deriveRows()
                    }
                  }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func taskFormsFlagged() {
        assertLint(
            UseTaskIDNotTaskInOnChange.self,
            """
            Text("x")
              .onChange(of: query, initial: true) { _, new in
                if !new.isEmpty {
                  1️⃣Task { await search(new) }
                }
                2️⃣Task.immediate { await log(new) }
                let handle = 3️⃣Task<Void, Never> { await save() }
              }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message),
                FindingSpec("2️⃣", message: Self.message),
                FindingSpec("3️⃣", message: Self.message),
            ]
        )
    }

    @Test func immediateDetachedFlaggedAndYieldNotFlagged() {
        assertLint(
            UseTaskIDNotTaskInOnChange.self,
            """
            Text("x")
              .onChange(of: query) {
                1️⃣Task.immediateDetached { await search(query) }
                2️⃣Task.detached(priority: .low) { await log(query) }
                Task.yield()
              }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message), FindingSpec("2️⃣", message: Self.message),
            ]
        )
    }

    @Test func taskInNestedClosureOrOtherModifierNotFlagged() {
        assertLint(
            UseTaskIDNotTaskInOnChange.self,
            """
            Text("x")
              .onChange(of: value) {
                Button("Go") { Task { await go() } }
                withAnimation { offset = 1 }
              }
              .onAppear { Task { await load() } }
              .task(id: value) { await load() }
              .onChange(of: value) { offset = 2 }
            """,
            findings: []
        )
    }
}
