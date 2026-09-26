@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseOnChangeInitialNotOnAppearTests: RuleTesting {
  private static func message(_ value: String) -> String {
    "'.onAppear' and '.onChange(of: \(value))' run the same action. Use '.onChange(of: \(value), initial: true)' and remove '.onAppear'"
  }

  @Test func guidanceIsConsider() {
    #expect(UseOnChangeInitialNotOnAppear.guidance == .consider)
  }

  @Test func sameActionFlagged() {
    assertLint(
      UseOnChangeInitialNotOnAppear.self,
      """
      struct SidebarRow: View {
        @Binding var pendingRenameID: ID?

        var body: some View {
          HStack { Text("x") }
            .contextMenu { menuItems(beginRename) }
            .1️⃣onAppear { claimPendingRename() }
            .onChange(of: pendingRenameID) { claimPendingRename() }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("pendingRenameID"))]
    )
  }

  @Test func reversedOrderAndIgnoredParametersFlagged() {
    assertLint(
      UseOnChangeInitialNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("x")
            .onChange(of: query) { _, _ in
              search()
            }
            .padding()
            .1️⃣onAppear {
              search()
            }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("query"))]
    )
  }

  @Test func differentActionsOrInitialNotFlagged() {
    assertLint(
      UseOnChangeInitialNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("x")
            .onAppear { textIsFocused = true }
            .onChange(of: text) { queueSearch() }
          Text("y")
            .onAppear { load() }
            .onChange(of: id, initial: false) { load() }
          Text("z")
            .onAppear { load() }
            .onChange(of: id) { old, new in load(new) }
          VStack {
            Text("a").onAppear { load() }
          }
          .onChange(of: id) { load() }
        }
      }
      """
    )
  }
}
