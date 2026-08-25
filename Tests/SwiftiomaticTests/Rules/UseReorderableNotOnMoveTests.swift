import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseReorderableNotOnMoveTests: RuleTesting {
    private static let message =
        "'onMove' only reorders inside a 'List' or a 'Form' — use '.reorderable()' with '.reorderContainer(for:move:)', which works in any container"

    @Test func onMoveInLazyVStackFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                LazyVStack {
                  ForEach(items) { Row($0) }
                    .1️⃣onMove { from, to in move(from, to) }
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func onMoveInScrollViewFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                ScrollView {
                  ForEach(items) { Row($0) }
                    .1️⃣onMove(perform: move)
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func onMoveInListNotFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                List {
                  ForEach(items) { Row($0) }
                    .onMove(perform: move)
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func onMoveInListWithSelectionNotFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                List(selection: $selected) {
                  ForEach(items) { Row($0) }
                    .onMove(perform: move)
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func onMoveInModuleQualifiedListNotFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                SwiftUI.List {
                  ForEach(items) { Row($0) }
                    .onMove(perform: move)
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func onMoveInFormNotFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                Form {
                  ForEach(items) { Row($0) }
                    .onMove(perform: move)
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func reorderableNotFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            struct V: View {
              var body: some View {
                LazyVStack {
                  ForEach(items) { Row($0) }
                    .reorderable()
                }
                .reorderContainer(for: Item.self) { difference in
                  difference.apply(to: &items)
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func unrelatedModifierNotFlagged() {
        assertLint(
            UseReorderableNotOnMove.self,
            """
            let view = ForEach(items) { Row($0) }.onDelete(perform: delete)
            """,
            findings: []
        )
    }
}
