import Foundation
import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoOnChangeDerivedStateWriteTests: RuleTesting {
    private static func message(source: String, target: String) -> String {
        "'.onChange(of: \(source))' writes '\(target)', which makes a second update. Derive '\(target)' from '\(source)' in the same mutation, or compute it where it is read"
    }

    private static func sourceMessage(source: String, target: String) -> String {
        "'\(source)' drives a write to '\(target)' in '.onChange'. Update '\(target)' in the code that changes '\(source)'"
    }

    private static func targetMessage(source: String, target: String) -> String {
        "'\(target)' is set in '.onChange(of: \(source))'. Derive it from '\(source)', or set it in the code that changes '\(source)'"
    }

    @Test func guidanceIsConsider() { #expect(NoOnChangeDerivedStateWrite.guidance == .consider) }

    @Test func fontMenuFilterWriteFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct FontMenu: View {
              3️⃣@State private var filter = ""
              2️⃣@State private var visibleRows: [FontRow] = []
              @State private var allRows: [FontRow] = []

              var body: some View {
                TextField("Filter by name", text: $filter)
                  .onChange(of: filter) {
                    1️⃣visibleRows = allRows.filter { $0.name.contains(filter) }
                  }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message(source: "filter", target: "visibleRows")),
                FindingSpec(
                    "2️⃣", message: Self.targetMessage(source: "filter", target: "visibleRows")),
                FindingSpec(
                    "3️⃣", message: Self.sourceMessage(source: "filter", target: "visibleRows")),
            ]
        )
    }

    /// The Thesis `GoalsInspector` shape: the source is a member path on a `@State` value.
    @Test func memberPathSourceFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct GoalsInspector: View {
              3️⃣@State private var wordCountSettings = WordCountSettings()
              2️⃣@State private var goal = 0

              var body: some View {
                Form {}
                  .onChange(of: wordCountSettings.type) {
                    1️⃣goal = wordCountSettings.defaultGoal
                  }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message(source: "wordCountSettings.type", target: "goal")),
                FindingSpec(
                    "2️⃣",
                    message: Self.targetMessage(source: "wordCountSettings.type", target: "goal")),
                FindingSpec(
                    "3️⃣", message: Self.sourceMessage(source: "wordCountSettings", target: "goal")),
            ]
        )
    }

    @Test func selfQualifiedAndMemberWritesFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Editor: View {
              5️⃣@State private var text = ""
              3️⃣@State private var stats = Stats()
              4️⃣var count = 0

              var body: some View {
                TextEditor(text: $text)
                  .onChange(of: self.text) { old, new in
                    1️⃣self.stats.words = new.split(separator: " ").count
                    2️⃣count += 1
                  }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message(source: "text", target: "stats")),
                FindingSpec("2️⃣", message: Self.message(source: "text", target: "count")),
                FindingSpec("3️⃣", message: Self.targetMessage(source: "text", target: "stats")),
                FindingSpec("4️⃣", message: Self.targetMessage(source: "text", target: "count")),
                FindingSpec("5️⃣", message: Self.sourceMessage(source: "text", target: "stats")),
            ]
        )
    }

    @Test func actionArgumentFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Counter: View {
              3️⃣@State private var value = 0
              2️⃣@State private var doubled = 0

              var body: some View {
                Text("x").onChange(of: value, initial: true, { 1️⃣doubled = value * 2 })
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message(source: "value", target: "doubled")),
                FindingSpec("2️⃣", message: Self.targetMessage(source: "value", target: "doubled")),
                FindingSpec("3️⃣", message: Self.sourceMessage(source: "value", target: "doubled")),
            ]
        )
    }

    @Test func writeToTheObservedStateNotFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Field: View {
              @State private var text = ""

              var body: some View {
                TextField("x", text: $text).onChange(of: text) { text = String(text.prefix(10)) }
              }
            }
            """
        )
    }

    @Test func environmentValueNotFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Scene: View {
              @Environment(\\.scenePhase) private var scenePhase
              @State private var lastActive = Date()

              var body: some View {
                Text("x").onChange(of: scenePhase) { lastActive = .now }
              }
            }
            """
        )
    }

    @Test func bindingTheViewDoesNotOwnNotFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Picker: View {
              @Binding var selection: String
              @State private var history: [String] = []

              var body: some View {
                Text(selection).onChange(of: selection) { history = [selection] }
              }
            }
            """
        )
    }

    @Test func issueListSearchRequestDeclarationsFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct IssueListView: View {
              var project: Project
              @Binding var filters: IssueFilters

              /// What the rows are read for.
              2️⃣@State private var request: ListRequest?

              3️⃣@State private var searchText = ""
              @State private var showSettings = false

              var body: some View {
                List {}
                  .task(id: request) { await reload(request) }
                  .onChange(of: ListScope(project: project.id, openOnly: filters.openOnly), initial: true) {
                    _, scope in
                    request = ListRequest(scope: scope, search: searchText)
                  }
                  .onChange(of: searchText) { _, text in
                    1️⃣request = ListRequest(scope: ListScope(project: project.id), search: text)
                  }
                  .searchable(text: $searchText)
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message(source: "searchText", target: "request")),
                FindingSpec(
                    "2️⃣", message: Self.targetMessage(source: "searchText", target: "request")),
                FindingSpec(
                    "3️⃣", message: Self.sourceMessage(source: "searchText", target: "request")),
            ]
        )
    }

    @Test func eachDeclarationFlaggedOnce() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Counter: View {
              4️⃣@State private var value = 0
              3️⃣@State private var doubled = 0

              var body: some View {
                Text("x")
                  .onChange(of: value) { 1️⃣doubled = value * 2 }
                  .onChange(of: value) { 2️⃣doubled += 1 }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message(source: "value", target: "doubled")),
                FindingSpec("2️⃣", message: Self.message(source: "value", target: "doubled")),
                FindingSpec("3️⃣", message: Self.targetMessage(source: "value", target: "doubled")),
                FindingSpec("4️⃣", message: Self.sourceMessage(source: "value", target: "doubled")),
            ]
        )
    }

    @Test func sideEffectWithoutStoredWriteNotFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Field: View {
              @State private var text = ""
              @State private var count = 0

              var body: some View {
                TextField("x", text: $text).onChange(of: text) { Haptics.play(); print(count) }
              }
            }
            """
        )
    }

    @Test func shadowedLocalWriteNotFlagged() {
        assertLint(
            NoOnChangeDerivedStateWrite.self,
            """
            struct Row: View {
              @State private var value = 0
              @State private var total = 0

              var body: some View {
                Text("x").onChange(of: value) {
                  var total = 0
                  total = value
                  print(total)
                }
              }
            }
            """
        )
    }
}
