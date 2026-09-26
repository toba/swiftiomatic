@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ForEachRowReadsOnlyElementTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'ForEach' row reads '\(name)' from the enclosing view. Pass the value into a row 'View' so the row depends only on its element"
  }

  @Test func gutterRowReadsEditorState() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct EditorGutterView: View {
        @Environment(\\.editorState) private var editorState
        static let width: CGFloat = 18

        var body: some View {
          ForEach(visibleMarkers, id: \\.id) { marker in
            markerView(marker)
              .position(
                x: Self.width / 2,
                y: 1️⃣editorState.gutterPositions[marker.id] ?? 0
              )
          }
        }

        private func markerView(_ marker: GutterMarker) -> some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("editorState")),
      ]
    )
  }

  @Test func breadcrumbRowReadsItemsCount() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct EditorBreadcrumbBar: View {
        let items: [Item]

        var body: some View {
          HStack {
            ForEach(Array(items.enumerated()), id: \\.offset) { index, item in
              Text(item.label)
                .foregroundStyle(index == 1️⃣items.count - 1 ? .primary : .secondary)
            }
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("items"))]
    )
  }

  @Test func fontPickerRowReadsSelectionAndDismissInActionClosure() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct FontMenu: View {
        @Environment(\\.dismiss) private var dismiss
        @Binding var selection: String

        var body: some View {
          LazyVStack {
            ForEach(visibleRows) { row in
              FontPreview(row: row) {
                1️⃣selection = row.name
                2️⃣dismiss()
              }
            }
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("selection")),
        FindingSpec("2️⃣", message: Self.message("dismiss")),
      ]
    )
  }

  @Test func selfQualifiedReadFlaggedOnce() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        var highlight: Int

        var body: some View {
          ForEach(items) { item in
            Text(item.name).bold(item.id == self.1️⃣highlight || item.id == highlight)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("highlight"))]
    )
  }

  @Test func listRowClosureChecked() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        @State private var filter = ""

        var body: some View {
          List(items) { item in Text(item.name).opacity(1️⃣filter.isEmpty ? 1 : 0.5) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("filter"))]
    )
  }

  @Test func privateLetStaticAndProjectedBindingNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct OptionSetList: View {
        @Binding var selection: Value
        private let cellSize: CGFloat = 16
        static let spacing: CGFloat = 3

        var body: some View {
          List(Value.allCases) { OptionSetRow(value: $0, selection: $selection) }
          ForEach(items) { item in
            Text(item.name)
              .frame(width: cellSize)
              .padding(Self.spacing)
              .padding(OptionSetList.spacing)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func shadowedNamesNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        var items: [Item]
        var selection: Int

        var body: some View {
          ForEach(items) { selection in
            let items = selection.children
            Text(items.first?.name ?? "")
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func derivedArgumentOfCustomRowNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct TableSizePicker: View {
        @State private var hover: (rows: Int, columns: Int)?
        @State private var selection: Tag?
        let depth: Int

        var body: some View {
          ForEach(1...8, id: \\.self) { row in
            TableSizeCell(isSelected: isSelected(row: row, column: 1))
          }
          ForEach(tags) { tag in TagRow(tag: tag, isSelected: selection == tag).padding(4) }
          ForEach(children) { child in NodeRow(node: child, depth: depth + 1) }
        }

        private func isSelected(row: Int, column: Int) -> Bool {
          hover.map { row <= $0.rows && column <= $0.columns } ?? false
        }
      }
      """,
      findings: []
    )
  }

  @Test func bareForwardingToCustomRowFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct CitationGroupForm: View {
        let citations: [Citation]
        let drag: (Node) -> Void

        var body: some View {
          ForEach(citations.indices, id: \\.self) { index in
            CitationForm(index: index, citations: 1️⃣citations, drag: self.2️⃣drag)
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("citations")),
        FindingSpec("2️⃣", message: Self.message("drag")),
      ]
    )
  }

  @Test func derivedValueOutsideCustomRowArgumentsFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct InspectorView: View {
        @State private var hovered: Int?

        var body: some View {
          ForEach(tabs.indices, id: \\.self) { index in
            TabRow(tab: tabs[index])
              .opacity(1️⃣dividerVisible(before: index) ? 1 : 0)
            Text(tabs[index].name).bold(2️⃣hovered == index)
          }
        }

        private func dividerVisible(before index: Int) -> Bool { hovered != index }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("dividerVisible")),
        FindingSpec("2️⃣", message: Self.message("hovered")),
      ]
    )
  }

  @Test func pureHelperMethodNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct LanguagePicker: View {
        private let prefix = "Lang: "

        var body: some View {
          ForEach(locales, id: \\.self) { locale in Text(displayName(of: locale)) }
        }

        private func displayName(of locale: Locale) -> String { prefix + Self.name(locale) + format(locale) }
        private func format(_ locale: Locale) -> String { locale.identifier }
        private static func name(_ locale: Locale) -> String { locale.identifier }
      }
      """,
      findings: []
    )
  }

  @Test func underscoreNamedMemberResolvesToItself() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        var _highlight: Int

        var body: some View {
          ForEach(items) { item in Text(item.name).bold(item.id == 1️⃣_highlight) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("_highlight"))]
    )
  }

  @Test func impureSecondOverloadFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        var title: String

        var body: some View {
          ForEach(items) { item in Text(1️⃣label(item.id)) }
        }

        private func label(_ id: Int) -> String { String(id) }
        private func label(_ name: String) -> String { name + title }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("label"))]
    )
  }

  @Test func nonViewTypeNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Builder {
        var selection: Int

        func build() -> some View {
          ForEach(items) { item in Text(item.name).bold(item.id == selection) }
        }
      }
      """,
      findings: []
    )
  }
}
