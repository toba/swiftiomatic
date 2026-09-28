import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagWholeValueModelViewInputTests: RuleTesting {
    private static func message(_ name: String, _ type: String, _ count: Int) -> String {
        "'\(name)' stores the whole value model '\(type)' (\(count) stored properties) as an input. A change to any property updates this view. Pass only the properties the view reads"
    }

    private static func partialMessage(_ name: String, _ type: String, _ read: String) -> String {
        "'\(name)' stores the whole value '\(type)' as an input but reads only \(read). A change to any other property still updates this view. Pass only the properties the view reads"
    }

    private static func rowInput(_ name: String, _ type: String, _ view: String) -> String {
        "'\(name)' stores the whole value '\(type)' in '\(view)', which a 'ForEach' or 'List' repeats for each element. Each parent update compares the value once per row. Pass only the values the row reads, or keep the data in an '@Observable' class"
    }

    private static func rowArgument(_ label: String, _ type: String, _ view: String) -> String {
        "Every '\(view)' row receives the same '\(type)' value as '\(label)'. Each parent update compares it once per row. Pass only the values the row reads, or keep the data in an '@Observable' class"
    }

    private static func collectionModel(_ type: String, _ count: Int) -> String {
        "'\(type)' holds \(count) collection properties. A repeated row view that stores it compares every collection on each parent update. Pass rows only the values they read, or keep the data in an '@Observable' class"
    }

    @Test func guidanceIsShould() { #expect(FlagWholeValueModelViewInput.guidance == .should) }

    /// The Thesis `NodeDescriptor` shape: the input struct is declared in another module of the
    /// project.
    @Test func otherFileLargeStructInputFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct NodeRow: View {
              1️⃣let node: NodeDescriptor

              var body: some View { Text(node.title) }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("node", "NodeDescriptor", 5))],
            otherFiles: [
                "/tmp/Core/NodeDescriptor.swift": """
                public struct NodeDescriptor {
                  public var id: Int
                  public var title: String
                  public var kind: String
                  public var depth: Int
                  public var parent: Int?
                }
                """
            ]
        )
    }

    @Test func largeStructInputFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Book {
              var title: String
              var author: String
              var pages: Int
              var rating: Double
              var notes: String
              static let empty = Book(title: "", author: "", pages: 0, rating: 0, notes: "")
              var summary: String { title + author }
            }

            struct BookRow: View {
              1️⃣let book: Book
              2️⃣@Binding var draft: Book

              var body: some View { Text(book.title) }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("book", "Book", 5)),
                FindingSpec("2️⃣", message: Self.message("draft", "Book", 5)),
            ]
        )
    }

    @Test func storedPropertiesInExtensionsCount() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Profile {
              var name: String
              var email: String
              var avatar: URL
            }

            extension Profile {
              struct Nested {}
            }

            struct Profile2 {
              let a, b, c, d, e: Int
            }

            struct Card: View {
              let profile: Profile
              1️⃣let other: Profile2?

              var body: some View { Text(profile.name) }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("other", "Profile2", 5))]
        )
    }

    @Test func smallStructNotFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            private struct FontRow: Equatable, Identifiable {
              let name: String
              let fit: RowFit
              var id: String { name }
            }

            private struct FontPreview: View {
              let row: FontRow
              var body: some View { Text(row.name) }
            }
            """
        )
    }

    /// The Thesis `EditorBreadcrumbBar` shape: a same-file struct under the size threshold that the
    /// view reads only in part, also through a qualified name. A qualified type from another file,
    /// such as `Project.ViewModel` , can be a class, so it is not reported.
    @Test func smallSameFileStructReadInPartFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Item {
              let title: String
              let icon: String
              let depth: Int
              let id: UUID
            }

            enum Grid {
              struct Week {
                let days: [Day]
                let index: Int
                let label: String
                let isCurrent: Bool
              }
            }

            private struct Crumb: View {
              1️⃣let item: Item
              var body: some View {
                Label(item.title, systemImage: item.icon).padding(.leading, CGFloat(item.depth))
              }
            }

            private struct WeekColumn: View {
              2️⃣let week: Grid.Week
              let project: Project.ViewModel
              var body: some View {
                VStack {
                  Text(week.label)
                  Text("\\(week.index)")
                  ForEach(week.days) { Text($0.name) }
                  Text(project.title)
                  Text(project.subtitle)
                  Text(project.status)
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.partialMessage("item", "Item", "'depth', 'icon', 'title'")),
                FindingSpec(
                    "2️⃣", message: Self.partialMessage("week", "Week", "'days', 'index', 'label'")),
            ]
        )
    }

    @Test func stateAndGenericParameterNotFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Value {
              var a = 0, b = 0, c = 0, d = 0, e = 0
            }

            struct Editor: View {
              @State private var draft = Value()
              var body: some View { Text("x") }
            }

            private struct OptionSetRow<Value: OptionSet>: View {
              var value: Value
              var body: some View { Text("x") }
            }
            """
        )
    }

    @Test func viewTypeInputNotFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Header: View {
              var a = 0, b = 0, c = 0, d = 0, e = 0
              var body: some View { Text("x") }
            }

            struct Page: View {
              let header: Header
              var body: some View { header }
            }
            """
        )
    }

    @Test func outOfFileModelReadByPropertiesFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            private struct TagSummary: View {
              1️⃣let tag: TagJSON

              var body: some View {
                VStack {
                  Text(tag.name)
                  if !tag.detail.isEmpty { Text(tag.detail) }
                  Text("\\(tag.issueCount) issues")
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.partialMessage("tag", "TagJSON", "'detail', 'issueCount', 'name'")
                )
            ]
        )
    }

    @Test func outOfFileInputUsedWholeNotFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Row: View {
              let tag: TagJSON
              let other: TagJSON
              let date: Date
              let symbol: StatusSymbol

              var body: some View {
                VStack {
                  Text(tag.name); Text(tag.detail); Text(tag.owner)
                  TagEditor(tag: tag)
                  Text(other.name); Text(other.detail)
                  Text(date.year); Text(date.month); Text(date.day)
                  Text(symbol.a); symbol.b.c; symbol.d(); Text(symbol.e)
                }
              }
            }
            """
        )
    }

    @Test func deferredUseAndSameFileViewForwardDoNotCountAsWholeUse() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            private struct LintAlertRow: View {
              1️⃣let alert: LintAlert

              var body: some View {
                HStack(spacing: 8) {
                  Button { Dispatcher.emit(RevealLintAlert(alert)) } label: {
                    Label {
                      Text(alert.message)
                    } icon: {
                      Image(systemName: alert.level.symbolName).foregroundStyle(alert.level.tint)
                    }
                  }
                  if !alert.suggestions.isEmpty { QuickFixControl(alert: alert) }
                }
              }
            }

            private struct QuickFixControl: View {
              let alert: LintAlert

              var body: some View {
                if alert.suggestions.count == 1, let replacement = alert.suggestions.first {
                  Button {
                    Dispatcher.emit(ApplyLintFix(alert: alert, replacement: replacement))
                  } label: { Image(systemName: "wand.and.sparkles") }
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.partialMessage(
                        "alert", "LintAlert", "'level', 'message', 'suggestions'"))
            ]
        )
    }

    @Test func wholeUseInLabelClosureStillCounts() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Row: View {
              let tag: TagJSON

              var body: some View {
                Button { open() } label: {
                  Text(tag.name); Text(tag.detail); Text(tag.owner)
                  TagBadge(tag: tag)
                }
              }
            }
            """
        )
    }
    @Test func observableClassInputNotFlagged() {
        // From Thesis `AskInspector.swift`. `AskState` is an `@Observable` class in another file.
        // The `@Bindable` and `@Environment(AskState.self)` uses show that it is an observable
        // reference.
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct QuestionField: View {
              @Bindable var ask: AskState
              var body: some View { TextField("", text: $ask.question) }
            }

            private struct StreamedAnswer: View {
              let ask: AskState
              var body: some View {
                Text(ask.answer)
                Text(ask.phase.title)
                ForEach(ask.sources) { Text($0.title) }
              }
            }

            private struct Sources: View {
              @Environment(SourceStore.self) private var environmentStore
              let store: SourceStore
              var body: some View {
                Text(store.first)
                Text(store.second)
                Text(store.third)
              }
            }
            """
        )
    }

    @Test func sharedOutOfFileValueInRepeatedRowFlagged() {
        // From jig `ProjectList.swift`. `ProjectRowNumbers` lives in another file. Every folder row
        // stores the same lookup table.
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct ProjectList: View {
              @State private var collapsed = Set<String>()

              var body: some View {
                List {
                  let numbers = rowNumbers
                  ForEach(rows) { row in
                    switch row {
                      case let .folder(folder, held):
                        FolderHeaderRow(
                          folder: folder,
                          held: held,
                          1️⃣numbers: numbers,
                          collapsed: $collapsed)
                      case let .project(project):
                        let model = numbers.model(for: project)
                        ProjectRow(model: model, folders: allFolders)
                    }
                  }
                }
              }
            }

            private struct FolderHeaderRow: View {
              let folder: ProjectFolder
              let held: [Project]
              2️⃣let numbers: ProjectRowNumbers
              @Binding var collapsed: Set<String>

              var body: some View { Text(numbers.model(for: folder).title) }
            }

            private struct ProjectRow: View {
              let model: ProjectRowModel
              let folders: [ProjectFolder]
              var body: some View { Text(model.title) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.rowArgument("numbers", "ProjectRowNumbers", "FolderHeaderRow")),
                FindingSpec(
                    "2️⃣", message: Self.rowInput("numbers", "ProjectRowNumbers", "FolderHeaderRow")),
            ]
        )
    }

    @Test func sharedSameFileCollectionModelInRepeatedRowFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Lookup {
              var names: [Int: String]
              var tags: Set<Int>
            }

            struct Parent: View {
              let lookup: Lookup
              let items: [Item]

              var body: some View {
                ForEach(items) { item in
                  ItemRow(item: item, 1️⃣lookup: lookup)
                }
              }
            }

            struct ItemRow: View {
              let item: Item
              2️⃣let lookup: Lookup
              var body: some View { Text(lookup.names[item.id] ?? "") }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.rowArgument("lookup", "Lookup", "ItemRow")),
                FindingSpec("2️⃣", message: Self.rowInput("lookup", "Lookup", "ItemRow")),
            ]
        )
    }

    @Test func elementDerivedAndSmallSharedRowInputsNotFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Small {
              var name: String
              var count: Int
            }

            final class Store {
              var names: [Int: String] = [:]
              var tags: Set<Int> = []
            }

            struct Parent: View {
              @Environment(Library.self) private var library
              @State private var selection: Item.ID?
              let small: Small
              let store: Store
              let title: String
              let items: [Item]

              var body: some View {
                ForEach(items) { item in
                  let model = RowModel(item: item)
                  ItemRow(
                    item: item,
                    model: model,
                    small: small,
                    store: store,
                    title: title,
                    library: library,
                    selection: $selection)
                }
                ForEach(items) { ItemRow(item: $0, model: RowModel(item: $0)) }
              }
            }

            struct ItemRow: View {
              let item: Item
              let model: RowModel
              var small: Small?
              var store: Store?
              var title = ""
              var library: Library?
              @Binding var selection: Item.ID?
              var body: some View { Text(item.name) }
            }
            """
        )
    }

    @Test func sharedValueOutsideRepeatedRowNotFlagged() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Parent: View {
              let numbers: ProjectRowNumbers
              var body: some View {
                VStack { Summary(numbers: numbers) }
              }
            }

            struct Summary: View {
              let numbers: ProjectRowNumbers
              var body: some View { Text(numbers.total) }
            }
            """
        )
    }

    @Test func structOfCollectionsInViewFileFlagged() {
        // From jig `ProjectRow.swift`. The table the sidebar rows receive holds a dictionary per
        // count.
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct 1️⃣ProjectRowNumbers {
              private let issueCounts: [Project.ID: ProjectIssueCounts]
              private let versions: [Project.ID: String]
              private let citations: Dictionary<Project.ID, Int>
              private let pulling: Set<Project.ID>
              private let title: String
              static let empty: [Int] = []

              func isPulling(_ project: Project.ID) -> Bool { pulling.contains(project) }
            }

            struct ProjectRow: View {
              let model: ProjectRowModel
              var body: some View { Text(model.title) }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.collectionModel("ProjectRowNumbers", 4))]
        )
    }

    @Test func structOfCollectionsNotFlaggedWhenSmallOrOutsideViewFile() {
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Filters {
              var tags: [String]
              var owners: [String]
              var title: String
            }

            struct Page: View {
              var body: some View { Text("x") }
            }
            """
        )
        assertLint(
            FlagWholeValueModelViewInput.self,
            """
            struct Tables {
              var a: [Int: String]
              var b: [Int: String]
              var c: Set<Int>
            }
            """
        )
    }
}
