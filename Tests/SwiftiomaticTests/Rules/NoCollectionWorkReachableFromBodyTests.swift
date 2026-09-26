@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoCollectionWorkReachableFromBodyTests: RuleTesting {
  private static func call(_ method: String, _ member: String) -> String {
    "'.\(method)' in '\(member)' runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
  }

  private static func loop(_ keyword: String, _ member: String) -> String {
    "'\(keyword)' loop in '\(member)' runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
  }

  private static func opaqueCall(_ function: String, _ collection: String) -> String {
    "'\(function)' takes the collection '\(collection)' and runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
  }

  @Test func sameFileStaticFunctionOnOtherTypeFollowed() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      enum SidebarRow {
        case project(Project)

        static func rows(projects: [Project]) -> [SidebarRow] {
          projects.1️⃣map { SidebarRow.project($0) }
        }
      }

      struct ProjectList: View {
        let projects: [Project]

        var body: some View {
          List(sidebarRows) { row in Text("x") }
        }

        private var sidebarRows: [SidebarRow] {
          SidebarRow.rows(projects: projects)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.call("map", "SidebarRow.rows"))]
    )
  }

  @Test func staticCallInsideFollowedStaticFunctionFollowed() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      enum Grouping {
        static func sorted(_ projects: [Project]) -> [Project] {
          projects.1️⃣sorted { $0.name < $1.name }
        }
      }

      enum SidebarRow {
        case project(Project)

        static func rows(projects: [Project]) -> [SidebarRow] {
          Self.loose(Grouping.sorted(projects))
        }

        static func loose(_ projects: [Project]) -> [SidebarRow] {
          projects.2️⃣map { SidebarRow.project($0) }
        }
      }

      struct ProjectList: View {
        let projects: [Project]

        var body: some View {
          List(sidebarRows) { row in Text("x") }
        }

        private var sidebarRows: [SidebarRow] {
          SidebarRow.rows(projects: projects)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("sorted", "Grouping.sorted")),
        FindingSpec("2️⃣", message: Self.call("map", "SidebarRow.loose")),
      ]
    )
  }

  @Test func outOfFileStaticFunctionTakingCollectionFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct ProjectList: View {
        @FetchAll(ProjectFolder.all) private var folders: [ProjectFolder]
        var projects: [Project]
        let count: Int

        var body: some View {
          List(sidebarRows) { row in Text("x") }
            .font(Font.system(size: CGFloat(count)))
          Text(Formatter.format(count))
        }

        private var sidebarRows: [SidebarRow] {
          SidebarRow.1️⃣rows(projects: projects, folders: folders)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.opaqueCall("SidebarRow.rows", "projects"))]
    )
  }

  @Test func gutterVisibleMarkersFilterFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct EditorGutterView: View {
        @Environment(\\.editorState) private var editorState

        var body: some View {
          ForEach(visibleMarkers, id: \\.id) { marker in Text(marker.name) }
        }

        private var visibleMarkers: [GutterMarker] {
          editorState.gutterMarkers.1️⃣filter { editorState.gutterPositions[$0.id] != nil }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.call("filter", "visibleMarkers"))]
    )
  }

  @Test func breadcrumbItemsReachedThroughShadowingLocal() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct EditorBreadcrumbBar: View {
        let crumbNames: [String]

        private var items: [Item] {
          crumbNames.enumerated().1️⃣map { index, name in Item(id: index, label: name) }
        }

        var body: some View {
          let items = items
          HStack { ForEach(items) { item in Text(item.label) } }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.call("map", "items"))]
    )
  }

  @Test func transitiveMethodAndLoopFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Summary: View {
        let values: [Int]

        var body: some View { Text(title) }

        private var title: String { "Total \\(total())" }

        private func total() -> Int {
          var sum = 0
          1️⃣for value in values { sum += value }
          return sum + values.2️⃣reduce(0, +) + ordered.count
        }

        private var ordered: [Int] { values.3️⃣sorted() }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.loop("for", "total")),
        FindingSpec("2️⃣", message: Self.call("reduce", "total")),
        FindingSpec("3️⃣", message: Self.call("sorted", "ordered")),
      ]
    )
  }

  @Test func everyOverloadFollowed() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Summary: View {
        let values: [Int]

        var body: some View { Text(summary()) }

        private func summary() -> String { "" }
        private func summary(_ limit: Int) -> String { values.1️⃣map(String.init).joined() }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.call("map", "summary"))]
    )
  }

  @Test func actionClosuresAndUnreachedMembersNotFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Picker: View {
        @State private var rows: [Row] = []
        let all: [Row]

        var body: some View {
          List(rows) { row in Text(row.name) }
            .task { rows = filtered() }
            .onChange(of: all) { rows = filtered() }
          Button("Sort") { rows = rows.sorted() }
          SymbolButton(.add) { Task.immediate { await add() } }
          Task { await add() }
        }

        private func filtered() -> [Row] { all.filter(\\.isVisible) }

        private var unused: [Row] { all.filter(\\.isVisible) }

        private func add() async { rows = all.map { $0 } }
      }
      """,
      findings: []
    )
  }

  @Test func inlineWorkInBodyNotFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Rows: View {
        let values: [Int]

        var body: some View {
          Text(values.map(String.init).joined())
        }
      }
      """,
      findings: []
    )
  }

  @Test func nonViewTypeNotFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Model {
        let values: [Int]
        var body: String { summary }
        private var summary: String { values.map(String.init).joined() }
      }
      """,
      findings: []
    )
  }
}
