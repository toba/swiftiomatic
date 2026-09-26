@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ForEachRowReadsOnlyElementTests: RuleTesting {
  private static func message(_ call: String = "ForEach", _ names: String...) -> String {
    let list = names.map { "'\($0)'" }.joined(separator: ", ")
    return "'\(call)' row reads \(list) from the enclosing view. Extract the row into a 'View' that takes the values as inputs so the row depends only on its element"
  }

  private static func read(_ name: String) -> String { "the row reads '\(name)' here" }

  @Test func gutterRowReadsEditorState() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct EditorGutterView: View {
        @Environment(\\.editorState) private var editorState
        static let width: CGFloat = 18

        var body: some View {
          0️⃣ForEach(visibleMarkers, id: \\.id) { marker in
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
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "editorState"),
          notes: [NoteSpec("1️⃣", message: Self.read("editorState"))]),
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
            0️⃣ForEach(Array(items.enumerated()), id: \\.offset) { index, item in
              Text(item.label)
                .foregroundStyle(index == 1️⃣items.count - 1 ? .primary : .secondary)
            }
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "items"),
          notes: [NoteSpec("1️⃣", message: Self.read("items"))]),
      ]
    )
  }

  @Test func namedRowActionClosuresNotFlagged() {
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
                selection = row.name
                dismiss()
              }
            }
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func selfQualifiedReadFlaggedOnce() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        var highlight: Int

        var body: some View {
          0️⃣ForEach(items) { item in
            Text(item.name).bold(item.id == self.1️⃣highlight || item.id == highlight)
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "highlight"),
          notes: [NoteSpec("1️⃣", message: Self.read("highlight"))]),
      ]
    )
  }

  @Test func listRowClosureChecked() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        @State private var filter = ""

        var body: some View {
          0️⃣List(items) { item in Text(item.name).opacity(1️⃣filter.isEmpty ? 1 : 0.5) }
        }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("List", "filter"),
          notes: [NoteSpec("1️⃣", message: Self.read("filter"))]),
      ]
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

  @Test func bareArgumentOfCustomRowNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct CitationGroupForm: View {
        let citations: [Citation]
        let drag: (Node) -> Void
        let canWrite: Bool
        @State private var page = 0

        var body: some View {
          ForEach(citations.indices, id: \\.self) { index in
            CitationForm(index: index, citations: citations, drag: self.drag)
          }
          ForEach(items) { item in
            ProjectItemRow(item: item, canWrite: canWrite)
          }
          ForEach(rowKeys) { keyed in IssueListItem(keyed: keyed, reachedEnd: showMore) }
        }

        private func showMore() { page += 1 }
      }
      """,
      findings: []
    )
  }

  @Test func derivedValueOutsideCustomRowArgumentsFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct InspectorView: View {
        @State private var hovered: Int?

        var body: some View {
          0️⃣ForEach(tabs.indices, id: \\.self) { index in
            TabRow(tab: tabs[index])
              .opacity(1️⃣dividerVisible(before: index) ? 1 : 0)
            Text(tabs[index].name).bold(2️⃣hovered == index)
          }
        }

        private func dividerVisible(before index: Int) -> Bool { hovered != index }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "dividerVisible", "hovered"),
          notes: [
            NoteSpec("1️⃣", message: Self.read("dividerVisible")),
            NoteSpec("2️⃣", message: Self.read("hovered")),
          ]),
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
          0️⃣ForEach(items) { item in Text(item.name).bold(item.id == 1️⃣_highlight) }
        }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "_highlight"),
          notes: [NoteSpec("1️⃣", message: Self.read("_highlight"))]),
      ]
    )
  }

  @Test func impureSecondOverloadFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct Rows: View {
        var title: String

        var body: some View {
          0️⃣ForEach(items) { item in Text(1️⃣label(item.id)) }
        }

        private func label(_ id: Int) -> String { String(id) }
        private func label(_ name: String) -> String { name + title }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "label"),
          notes: [NoteSpec("1️⃣", message: Self.read("label"))]),
      ]
    )
  }

  @Test func composedRowReadingOutsideStateFlaggedAtRow() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct BackupBrowser: View {
        @State private var isRestoring = false

        var body: some View { Text("x") }

        private func snapshots(of project: ProjectBackups) -> some View {
          0️⃣List(project.snapshots) { snapshot in
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.date.formatted(date: .abbreviated, time: .shortened))
              }
              Spacer()
              Menu("Restore") {
                Button("Merge into Library") { 1️⃣restore(snapshot, mode: .keepIDs) }
                Button("Restore as Copy") { restore(snapshot, mode: .newCopy) }
              }
              .fixedSize()
              .disabled(2️⃣isRestoring)
            }
            .contextMenu {
              Button("Delete Backup", role: .destructive) { 3️⃣delete(snapshot) }
            }
          }
          .navigationTitle(project.name)
        }

        private func restore(_ snapshot: Snapshot, mode: IdentityMode) { isRestoring = true }
        private func delete(_ snapshot: Snapshot) { isRestoring = false }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("List", "restore", "isRestoring", "delete"),
          notes: [
            NoteSpec("1️⃣", message: Self.read("restore")),
            NoteSpec("2️⃣", message: Self.read("isRestoring")),
            NoteSpec("3️⃣", message: Self.read("delete")),
          ]),
      ]
    )
  }

  @Test func rowThatIsOneNamedViewNotFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct EditorThemePreferences: View {
        @State private var library = ThemeLibrary()
        @State private var editID: Theme.ID?
        @State private var themeState = ThemeState()

        var body: some View {
          ThemeCardGrid {
            ForEach($library.themes) { theme in
              EditorThemePreview(
                size: 125,
                theme: theme,
                selection: $themeState.selected,
                copy: { library.copy(theme.wrappedValue) },
                edit: { editID = theme.id },
                delete: { library.delete(theme.wrappedValue) }
              )
            }
          }
        }
      }

      struct NodeStatusPreferences: View {
        @State private var statuses: [NodeStatus] = []
        @State private var selection: NodeStatus?

        var body: some View {
          List(statuses) { status in
            NodeStatusRow(status: status, isSelected: selection?.id == status.id)
              .listRowInsets(.init(top: 0, leading: -6, bottom: 0, trailing: 0))
              .onTapGesture { selection = status }
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func bodyTimeModifierClosureOfCustomRowFlagged() {
    assertLint(
      ForEachRowReadsOnlyElement.self,
      """
      struct TagList: View {
        @State private var selection: Tag?
        @State private var hovered: Tag?

        var body: some View {
          0️⃣ForEach(tags) { tag in
            TagRow(tag: tag)
              .background {
                if 1️⃣selection == tag { Color.accentColor }
              }
              .overlay { Text(2️⃣hovered?.name ?? "") }
              .onTapGesture { selection = tag }
              .contextMenu {
                Button("Select") { selection = tag }
              }
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "0️⃣", message: Self.message("ForEach", "selection", "hovered"),
          notes: [
            NoteSpec("1️⃣", message: Self.read("selection")),
            NoteSpec("2️⃣", message: Self.read("hovered")),
          ]),
      ]
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
