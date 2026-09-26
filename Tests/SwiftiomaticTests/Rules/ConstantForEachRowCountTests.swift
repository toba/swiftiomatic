@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ConstantForEachRowCountTests: RuleTesting {
  private static let ifWithoutElse =
    "'if' without 'else' in a 'ForEach' row changes the row's view count. Add an 'else' branch or move the condition into a row 'View'"
  private static let nestedForEach =
    "'ForEach' directly inside a 'ForEach' row changes the row's view count. Wrap it in a container or a row 'View'"
  private static func severalViews(_ count: Int) -> String {
    "'ForEach' row builds \(count) top-level views. Wrap them in one container or a row 'View' so each element makes one view"
  }

  private static func variableHelper(_ name: String) -> String {
    "'\(name)' builds a variable number of views, so this 'ForEach' row changes its view count. Give the helper one root view or extract a row 'View'"
  }

  private static func rowBodyViews(_ name: String, _ count: Int) -> String {
    "'\(name)' body builds \(count) top-level views, so each 'ForEach' element makes \(count) rows. Wrap them in one container"
  }

  private static func rowBodyIfWithoutElse(_ name: String) -> String {
    "'if' without 'else' at the root of the '\(name)' row body changes the row's view count. Add an 'else' branch or wrap the body in one container"
  }

  private static func rowBodyBranch(_ name: String) -> String {
    "'\(name)' row body starts with a branch, so a lazy container runs every row's body to count its rows. Move the branch inside one root view"
  }

  @Test func namedRowBodyWithSeveralViewsAndIfFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      struct NumberingInspectorSection: View {
        let settings: NumberingSettings

        var body: some View {
          Section(header: Text("Numbering")) {
            ForEach(NumberingSettings.numberableTypes, id: \\.rawValue) { type in
              NumberingTypeRow(type: type, numbering: binding(for: type))
            }
          }
        }
      }

      private struct NumberingTypeRow: View {
        let type: NodeType
        @Binding var numbering: NodeNumbering?

        var body: some View {
          1️⃣Toggle(isOn: enabled) { Text(type.numberingTitle) }

          2️⃣if numbering != nil {
            Picker("Style", selection: field(\\.style, default: .arabic)) {
              ForEach(NumberStyle.allCases, id: \\.rawValue) { Text($0.title).tag($0) }
            }
            Toggle("Include Parent Number", isOn: field(\\.includesParentNumber, default: false))
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.rowBodyViews("NumberingTypeRow", 2)),
        FindingSpec("2️⃣", message: Self.rowBodyIfWithoutElse("NumberingTypeRow")),
      ]
    )
  }

  @Test func namedRowBodyRootSwitchFlaggedOnce() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      struct ProjectTree: View {
        var body: some View {
          List {
            ForEach(items, id: \\.id) { item in
              ProjectTreeRow(item: item, expandedFolders: $expandedFolders)
            }
          }
        }
      }

      struct ProjectTreeRow: View {
        let item: MenuTreeItem
        @Binding var expandedFolders: Set<ProjectFolder.ID>

        var body: some View {
          1️⃣switch item.kind {
            case let .folder(folder):
              let folderID = folder.id
              DisclosureGroup(
                isExpanded: .constant(true),
                content: {
                  ForEach(item.children ?? [], id: \\.id) { child in
                    ProjectTreeRow(item: child, expandedFolders: $expandedFolders)
                  }
                },
                label: { Text(folder.name) }
              )

            case let .project(node):
              ProjectNodeRow(node: node)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.rowBodyBranch("ProjectTreeRow"))]
    )
  }

  @Test func namedRowWithOneRootViewNotFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      struct Rows: View {
        var body: some View {
          ForEach(items) { item in ItemView(item: item).padding() }
        }
      }

      struct ItemView: View {
        let item: Item

        var body: some View {
          HStack {
            if item.isOn { Image(systemName: "star") }
            Text(item.name)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func helperInSwitchCaseFollowed() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      struct ProjectList: View {
        var body: some View {
          List {
            ForEach(sidebarRows) { row in
              switch row {
                case let .folder(folder, held): 1️⃣folderRow(folder, holding: held)
                case let .project(project): projectRow(project)
              }
            }
          }
        }

        @ViewBuilder
        private func folderRow(_ folder: Folder, holding held: [Project]) -> some View {
          let isOpen = expansion(of: folder)
          Button("x") { isOpen.wrappedValue.toggle() }
          if isOpen.wrappedValue { ForEach(held) { projectRow($0) } }
        }

        private func projectRow(_ project: Project) -> some View {
          Text(project.name)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.variableHelper("folderRow"))]
    )
  }

  @Test func helperAtTopLevelAndNestedHelperFollowed() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      struct Rows: View {
        var body: some View {
          ForEach(items) { item in 1️⃣row(item) }
          ForEach(items) { item in self.2️⃣outer }
          ForEach(items) { item in plain(item) }
        }

        @ViewBuilder private func row(_ item: Item) -> some View {
          if item.isVisible { Text(item.name) }
        }

        @ViewBuilder private var outer: some View { inner }

        @ViewBuilder private var inner: some View {
          Text("a")
          Text("b")
        }

        @ViewBuilder private func plain(_ item: Item) -> some View {
          if item.isOn { Text("on") } else { Text("off") }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.variableHelper("row")),
        FindingSpec("2️⃣", message: Self.variableHelper("outer")),
      ]
    )
  }

  @Test func breadcrumbSeparatorFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      HStack {
        1️⃣ForEach(Array(items.enumerated()), id: \\.offset) { index, item in
          2️⃣if index > 0 {
            Image(systemName: "chevron.compact.right")
          }
          Text(item.label)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.severalViews(2)),
        FindingSpec("2️⃣", message: Self.ifWithoutElse),
      ]
    )
  }

  @Test func loneIfWithoutElseFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(items) { item in
        1️⃣if item.isVisible {
          Text(item.name)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.ifWithoutElse)]
    )
  }

  @Test func elseIfChainWithoutFinalElseFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(items) { item in
        1️⃣if item.isA {
          Text("a")
        } else if item.isB {
          Text("b")
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.ifWithoutElse)]
    )
  }

  @Test func nestedForEachFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(sections) { section in
        1️⃣ForEach(section.rows) { row in
          Text(row.name)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.nestedForEach)]
    )
  }

  @Test func contentLabelClosureChecked() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      1️⃣ForEach(items, content: { item in
        Text(item.name)
        Divider()
      })
      """,
      findings: [FindingSpec("1️⃣", message: Self.severalViews(2))]
    )
  }

  @Test func constantRowsNotFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(items) { item in
        let label = item.name
        if item.isOn {
          Text(label).bold()
        } else {
          Text(label)
        }
      }
      ForEach(items) { item in
        switch item.kind {
        case .a: Text("a")
        case .b: Text("b")
        }
      }
      ForEach(sections) { section in
        HStack {
          ForEach(section.rows) { row in Text(row.name) }
        }
      }
      ForEach(items) { item in ItemView(item: item).padding() }
      """,
      findings: []
    )
  }
}
