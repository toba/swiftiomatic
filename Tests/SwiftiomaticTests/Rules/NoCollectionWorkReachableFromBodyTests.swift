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

  private static func owner(_ type: String) -> String {
    "'\(type)' reaches collection work from 'body'. SwiftUI repeats the work on each update of the view. Store the derived value, or move the work behind a child view"
  }

  private static func bodyRead(_ member: String) -> String {
    "'body' reads '\(member)', which walks a collection on every 'body' evaluation. Store the derived value and update it when its inputs change"
  }

  private static let bodyName =
    "'body' reaches collection work through a member it reads. SwiftUI repeats that work on each evaluation of 'body'. Store the derived value, or move the work behind a child view"

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

      struct 8️⃣ProjectList: View {
        let projects: [Project]

        var 7️⃣body: some View {
          List(9️⃣sidebarRows) { row in Text("x") }
        }

        private var sidebarRows: [SidebarRow] {
          SidebarRow.rows(projects: projects)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "SidebarRow.rows")),
        FindingSpec("8️⃣", message: Self.owner("ProjectList")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("sidebarRows")),
      ]
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

      struct 8️⃣ProjectList: View {
        let projects: [Project]

        var 7️⃣body: some View {
          List(9️⃣sidebarRows) { row in Text("x") }
        }

        private var sidebarRows: [SidebarRow] {
          SidebarRow.rows(projects: projects)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("sorted", "Grouping.sorted")),
        FindingSpec("2️⃣", message: Self.call("map", "SidebarRow.loose")),
        FindingSpec("8️⃣", message: Self.owner("ProjectList")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("sidebarRows")),
      ]
    )
  }

  @Test func outOfFileStaticFunctionTakingCollectionFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣ProjectList: View {
        @FetchAll(ProjectFolder.all) private var folders: [ProjectFolder]
        var projects: [Project]
        let count: Int

        var 7️⃣body: some View {
          List(9️⃣sidebarRows) { row in Text("x") }
            .font(Font.system(size: CGFloat(count)))
          Text(Formatter.format(count))
        }

        private var sidebarRows: [SidebarRow] {
          SidebarRow.1️⃣rows(projects: projects, folders: folders)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.opaqueCall("SidebarRow.rows", "projects")),
        FindingSpec("8️⃣", message: Self.owner("ProjectList")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("sidebarRows")),
      ]
    )
  }

  @Test func outOfFileStaticFunctionTakingDequeOrQualifiedArrayFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣Timeline: View {
        let events: Deque<Event>
        let marks: Swift.Array<Mark>

        var body: some View {
          Text(Summary.1️⃣text(events: events))
          Text(Summary.2️⃣label(marks: marks))
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.opaqueCall("Summary.text", "events")),
        FindingSpec("2️⃣", message: Self.opaqueCall("Summary.label", "marks")),
        FindingSpec("8️⃣", message: Self.owner("Timeline")),
      ]
    )
  }

  @Test func gutterVisibleMarkersFilterFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣EditorGutterView: View {
        @Environment(\\.editorState) private var editorState

        var 7️⃣body: some View {
          ForEach(9️⃣visibleMarkers, id: \\.id) { marker in Text(marker.name) }
        }

        private var visibleMarkers: [GutterMarker] {
          editorState.gutterMarkers.1️⃣filter { editorState.gutterPositions[$0.id] != nil }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("filter", "visibleMarkers")),
        FindingSpec("8️⃣", message: Self.owner("EditorGutterView")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("visibleMarkers")),
      ]
    )
  }

  @Test func breadcrumbItemsReachedThroughShadowingLocal() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣EditorBreadcrumbBar: View {
        let crumbNames: [String]

        private var items: [Item] {
          crumbNames.enumerated().1️⃣map { index, name in Item(id: index, label: name) }
        }

        var 7️⃣body: some View {
          let items = 9️⃣items
          HStack { ForEach(items) { item in Text(item.label) } }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "items")),
        FindingSpec("8️⃣", message: Self.owner("EditorBreadcrumbBar")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("items")),
      ]
    )
  }

  @Test func transitiveMethodAndLoopFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣Summary: View {
        let values: [Int]

        var 7️⃣body: some View { Text(9️⃣title) }

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
        FindingSpec("8️⃣", message: Self.owner("Summary")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("title")),
      ]
    )
  }

  @Test func everyOverloadFollowed() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣Summary: View {
        let values: [Int]

        var 7️⃣body: some View { Text(9️⃣summary()) }

        private func summary() -> String { "" }
        private func summary(_ limit: Int) -> String { values.1️⃣map(String.init).joined() }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "summary")),
        FindingSpec("8️⃣", message: Self.owner("Summary")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("summary")),
      ]
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

  @Test func buttonLabelArgumentFollowedAndDeferredClosuresSkipped() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      #"""
      struct 8️⃣Toolbar: View {
        let items: [Item]

        var body: some View {
          Button(action: { save(items.filter(\.isDirty)) }, label: {
            Text(items.1️⃣filter(\.isDirty).first?.name ?? "")
          })
          Toggle("Dirty", isOn: Binding(get: { true }, set: { _ in save(items.sorted()) }))
          Text("Drag")
            .draggable(items) { Text(items.map(\.name).joined()) }
            .onGeometryChange(for: Int.self) { _ in items.map(\.id).count } action: { _ in }
          Color.clear.task { Task.immediateDetached { save(items.sorted()) } }
        }
      }
      """#,
      findings: [
        FindingSpec("1️⃣", message: Self.call("filter", "body")),
        FindingSpec("8️⃣", message: Self.owner("Toolbar")),
      ]
    )
  }

  @Test func inlineWorkInBodyFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣Rows: View {
        let values: [Int]

        var body: some View {
          Text(values.1️⃣map(String.init).joined())
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "body")),
        FindingSpec("8️⃣", message: Self.owner("Rows")),
      ]
    )
  }

  @Test func dictionariesAndStreakBuiltInBodyFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣WritingActivityHeatMap: View {
        private let today: Date
        private let calendar: Calendar

        @Fetch private var activity: [DailyActivity] = []

        var body: some View {
          let peakByUnit = Dictionary(activity.1️⃣map { ($0.unit, $0.magnitude) }, uniquingKeysWith: max)
          let byDay = Dictionary(
            activity.2️⃣map { ($0.day, $0) },
            uniquingKeysWith: { lhs, rhs in
              intensity(lhs, peakByUnit: peakByUnit) >= intensity(rhs, peakByUnit: peakByUnit) ? lhs : rhs
            })
          let streak = DailyActivity.3️⃣currentStreak(
            through: activity, today: today, calendar: calendar)

          VStack {
            if streak > 0 { Text("\\(streak)-day streak") }
            grid(byDay: byDay)
          }
        }

        private func intensity(_ day: DailyActivity, peakByUnit: [Unit: Int]) -> Double { 0 }

        private func grid(byDay: [Date: DailyActivity]) -> some View { Text("grid") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "body")),
        FindingSpec("2️⃣", message: Self.call("map", "body")),
        FindingSpec("3️⃣", message: Self.opaqueCall("DailyActivity.currentStreak", "activity")),
        FindingSpec("8️⃣", message: Self.owner("WritingActivityHeatMap")),
      ]
    )
  }

  @Test func publicationsMappedInBodyFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣PublishView: View {
        @State private var state: PublicationState = .shared
        @State private var selection: Publication.ID?

        var body: some View {
          PreviewWindow(
            selections: state.publications.1️⃣map(\\.id),
            selection: $selection,
            displayName: { id in state.publications.first { $0.id == id }?.displayName ?? "-" },
            perform: { id in await publish(to: id) }
          )
          .task { await state.load() }
        }

        private func publish(to id: Publication.ID) async {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "body")),
        FindingSpec("8️⃣", message: Self.owner("PublishView")),
      ]
    )
  }

  @Test func functionReferencesPassedOutOfBodyNotFollowed() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct ProjectTree: View {
        let items: [MenuTreeItem]
        @State private var draggingID: Node.ID?

        private var drag: OutlineDrag<Node.ID> {
          OutlineDrag(
            draggingID: $draggingID,
            nestTarget: nestTarget,
            canDrop: canDrop,
            onDrop: self.move
          )
        }

        var body: some View {
          List {
            ForEach(items, id: \\.id) { item in ProjectTreeRow(item: item, drag: drag) }
          }
          .onDrop(
            of: [.text],
            delegate: RootDropDelegate(draggingID: $draggingID, canDrop: canDragOut, onDrop: clearFolder)
          )
        }

        private func nestTarget(_ dragged: Node.ID, _ target: Node.ID) -> Node.ID? {
          items.filter { $0.id != dragged }.first?.id
        }

        private func canDrop(_ dragged: Node.ID, _ target: Node.ID) -> Bool {
          items.flatMap(\\.children).isEmpty
        }

        private func move(_ dragged: Node.ID, _ target: Node.ID) {
          for item in items { print(item) }
        }

        private func canDragOut(_ dragged: Node.ID) -> Bool {
          var current: Node.ID? = dragged
          while let id = current { current = parent(of: id) }
          return true
        }

        private func clearFolder(_ dragged: Node.ID) {}
        private func parent(of id: Node.ID) -> Node.ID? { nil }
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

  @Test func ownerAndBodyReadReportedForContentViewShape() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣ContentView: View {
        @FetchAll(Project.all) private var fetchedProjects: [Project]
        @AppStorage(.selectedProjectID) private var selectedProjectID

        private var projects: [Project] { fetchedProjects.1️⃣sorted(by: Sort.text(\\.name)) }

        private var selectedProject: Project? {
          projects.first { $0.id.uuidString == selectedProjectID }
        }

        var 7️⃣body: some View {
          NavigationSplitView {
            ProjectListView(projects: 9️⃣projects, selection: 0️⃣selectedProject?.id)
          } detail: {
            Text(projects.first?.name ?? "")
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("sorted", "projects")),
        FindingSpec("8️⃣", message: Self.owner("ContentView")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("projects")),
        FindingSpec("0️⃣", message: Self.bodyRead("selectedProject")),
      ]
    )
  }

  @Test func bodyReadReportedOncePerMemberAndOnlyForMembersThatReachWork() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣IssueListView: View {
        let rows: [Row]
        private var title: String { "Issues" }
        private var rowKeys: [KeyedRow] { rows.1️⃣map(KeyedRow.init) }

        var 7️⃣body: some View {
          List {
            let lastID = rows.last?.id
            Text(title)
            ForEach(9️⃣rowKeys) { keyed in Text(keyed.name) }
            Text("\\(rowKeys.count)")
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "rowKeys")),
        FindingSpec("8️⃣", message: Self.owner("IssueListView")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("9️⃣", message: Self.bodyRead("rowKeys")),
      ]
    )
  }

  @Test func ownerReportedForBodyInExtension() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣Picker: View {
        let names: [String]
      }

      extension Picker {
        var body: some View {
          Text(names.1️⃣sorted().joined())
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("sorted", "body")),
        FindingSpec("8️⃣", message: Self.owner("Picker")),
      ]
    )
  }

  @Test func smallTransformOverLiteralCollectionNotFlagged() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Legend: View {
        private var labels: [String] { ["Open", "Closed"].map { $0.uppercased() } }

        var body: some View {
          HStack {
            ForEach(labels, id: \\.self) { Text($0) }
            ForEach([1, 2, 3].filter { $0 > 1 }, id: \\.self) { Text("\\($0)") }
            let sizes = ["s": 1, "m": 2].map { $0.key }
            Text(sizes.first ?? "")
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func viewWithoutReachedWorkHasNoOwnerFinding() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Badge: View {
        let count: Int
        private var label: String { "\\(count)" }

        var body: some View { Text(label) }
      }
      """,
      findings: []
    )
  }

  @Test func bodyNameReportedWhenBodyReachesWorkThroughMember() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣IssueListView: View {
        @FetchAll private var rows: [IssueListRow]
        @Binding var selection: Issue.ID?

        private var showsAvatar: Bool { true }

        private var rowKeys: [KeyedRow] {
          rows.1️⃣map { KeyedRow(row: $0, showsAvatar: showsAvatar) }
        }

        var 7️⃣body: some View {
          List(selection: $selection) {
            let lastID = rows.last?.id
            ForEach(9️⃣rowKeys) { keyed in Text(keyed.name) }
          }
          .onChange(of: rows.2️⃣map(\\.id), initial: true) { _, ids in
            selection = ids.first
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("map", "rowKeys")),
        FindingSpec("2️⃣", message: Self.call("map", "body")),
        FindingSpec("7️⃣", message: Self.bodyName),
        FindingSpec("8️⃣", message: Self.owner("IssueListView")),
        FindingSpec("9️⃣", message: Self.bodyRead("rowKeys")),
      ]
    )
  }

  @Test func bodyNameNotReportedWhenWorkIsOnlyInBody() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct 8️⃣CitationsSheet: View {
        @FetchAll private var citations: [Citation]

        private var writer: Writer { Writer() }

        var body: some View {
          let canWrite = writer.canWrite
          let sorted = citations.1️⃣sorted {
            $0.url.localizedCaseInsensitiveCompare($1.url) == .orderedAscending
          }
          ItemList(items: sorted, canWrite: canWrite)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.call("sorted", "body")),
        FindingSpec("8️⃣", message: Self.owner("CitationsSheet")),
      ]
    )
  }

  @Test func bodyNameNotReportedForMemberOverLiteralCollection() {
    assertLint(
      NoCollectionWorkReachableFromBody.self,
      """
      struct Legend: View {
        private var labels: [String] { ["Open", "Closed"].map { $0.uppercased() } }

        var body: some View {
          ForEach(labels, id: \\.self) { Text($0) }
        }
      }
      """,
      findings: []
    )
  }
}
