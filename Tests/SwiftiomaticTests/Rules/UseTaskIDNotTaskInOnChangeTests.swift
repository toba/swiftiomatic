@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTaskIDNotTaskInOnChangeTests: RuleTesting {
  private static let message =
    "a 'Task' started in '.onChange(of:)' is not cancelled when the value changes again or the view goes away. Use '.task(id:)' with the same value"

  @Test func guidanceIsShould() {
    #expect(UseTaskIDNotTaskInOnChange.guidance == .should)
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
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
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
