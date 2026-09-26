@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagStatefulForEachOverIndicesTests: RuleTesting {
  private static func message(_ row: String, _ state: String) -> String {
    "'ForEach' over indices keys each row by position, and '\(row)' holds '\(state)'. An insert or a remove moves that state to a different row. Key the rows by a stable 'id'"
  }

  @Test func focusedByIndexFlaggedThroughIgnoreDirective() {
    assertLint(
      FlagStatefulForEachOverIndices.self,
      """
      struct CitationGroupForm: View {
        var citations: Citation.ViewModel
        @FocusState private var focusedIndex: Int?

        var body: some View {
          VStack(alignment: .leading) {
            // sm:ignore:next flagForEachIDSelfInView flagForEachOverIndices - indices are stable
            ForEach(1️⃣citations.indices, id: \\.self) { index in
              CitationForm(index: index, citations: citations)
                .focused($focusedIndex, equals: index)
            }
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("CitationForm", "@FocusState"))]
    )
  }

  @Test func sameFileRowWithStateFlagged() {
    assertLint(
      FlagStatefulForEachOverIndices.self,
      """
      struct List: View {
        var body: some View {
          ForEach(1️⃣0..<items.count, id: \\.self) { i in
            ItemRow(index: i)
          }
        }
      }

      struct ItemRow: View {
        let index: Int
        @State private var isExpanded = false
        var body: some View { Text("x") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("ItemRow", "@State"))]
    )
  }

  @Test func statelessRowsNotFlagged() {
    assertLint(
      FlagStatefulForEachOverIndices.self,
      """
      struct List: View {
        @FocusState private var focused: Int?

        var body: some View {
          ForEach(items.indices, id: \\.self) { i in
            ItemRow(index: i)
          }
          ForEach(items.indices, id: \\.self) { i in
            Text("\\(i)").focused($focused, equals: 0)
          }
          ForEach(items) { item in
            StatefulRow(item: item).focused($focused, equals: item.id)
          }
        }
      }

      struct ItemRow: View {
        let index: Int
        var body: some View { Text("x") }
      }

      struct StatefulRow: View {
        @State private var isOn = false
        var body: some View { Text("x") }
      }
      """
    )
  }

  @Test func flagForEachOverIndicesLeavesStatefulRowsToThisRule() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      struct CitationGroupForm: View {
        @FocusState private var focusedIndex: Int?

        var body: some View {
          ForEach(citations.indices, id: \\.self) { index in
            CitationForm(index: index).focused($focusedIndex, equals: index)
          }
        }
      }
      """
    )
  }
}
