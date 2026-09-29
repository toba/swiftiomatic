package import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoWorkInViewInitializerTests: RuleTesting {
    private static let message =
        "This view initializer does work. A parent re-creates the view on each of its updates, so the work repeats. Store the inputs, and move effects to 'onAppear', 'onChange(of:initial:)' or 'task(id:)'"
    private static let ownerNote =
        "SwiftUI constructs this view type again each time its parent evaluates 'body'"

    @Test func guidanceIsConsider() { #expect(NoWorkInViewInitializer.guidance == .consider) }

    @Test func enumPickerFilteringFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            public struct 2️⃣EnumPicker<Item: Pickable>: View {
              @Binding private var selection: Item?
              private let label: LocalizedStringKey
              private let presentable: [Item]

              public init(_ label: LocalizedStringKey, selection: Binding<Item?>, exclude: [Item] = []) {
                self.label = label
                1️⃣presentable = Item.allCases(excluding: exclude)
                _selection = selection
              }

              public var body: some View { Text(label) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("2️⃣", message: Self.ownerNote)])
            ]
        )
    }

    @Test func localBindingAndCallFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct 4️⃣Chart: View {
              let points: [Point]

              init(values: [Double]) {
                1️⃣let sorted = values.sorted()
                2️⃣points = sorted.map(Point.init)
                3️⃣print(points.count)
              }

              var body: some View { Text("x") }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("4️⃣", message: Self.ownerNote)]),
                FindingSpec(
                    "2️⃣", message: Self.message, notes: [NoteSpec("4️⃣", message: Self.ownerNote)]),
                FindingSpec(
                    "3️⃣", message: Self.message, notes: [NoteSpec("4️⃣", message: Self.ownerNote)]),
            ]
        )
    }

    @Test func popoverPickerBuilderCallNotFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            public struct PopoverPicker<Popover: View>: View {
              private var label: LocalizedStringKey
              private var popover: Popover
              private var description: String
              private let popoverFrame: ViewFrameIntent?

              public init(
                _ label: LocalizedStringKey,
                description: String,
                popoverFrame: ViewFrameIntent? = nil,
                @ViewBuilder popover: () -> Popover
              ) {
                self.label = label
                self.popover = popover()
                self.description = description
                self.popoverFrame = popoverFrame
              }

              public var body: some View { popover }
            }
            """
        )
    }

    @Test func storedBuilderAndWrapperSetupNotFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            public struct ConditionalScrollView<Content: View>: View {
              public var scrollable: Bool
              @ViewBuilder public var content: (ScrollViewProxy?) -> Content
              @State private var count: Int
              @Binding var selection: String
              var mode: Mode
              var limit: Int?

              public init(
                scrollable: Bool,
                start: Int,
                selection: Binding<String>,
                @ContentBuilder content: @escaping (ScrollViewProxy?) -> Content
              ) {
                self.scrollable = scrollable
                self.content = content
                _count = State(initialValue: start)
                _selection = selection
                mode = .automatic
                limit = nil
              }

              public var body: some View { content(nil) }
            }
            """
        )
    }

    @Test func delegatingInitFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct 2️⃣Label: View {
              let title: String

              init(_ title: String) { self.title = title }
              init() { 1️⃣self.init("Untitled") }

              var body: some View { Text(title) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("2️⃣", message: Self.ownerNote)])
            ]
        )
    }

    @Test func delegatingInitInExtensionFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct 3️⃣GitHubAccountLabel: View {
              let name: String?
              let login: String
              var size: CGFloat = 44

              var body: some View { Text(login) }
            }

            extension GitHubAccountLabel {
              init(_ account: GitHubAccount, size: CGFloat = 44) {
                1️⃣self.init(name: account.name, login: account.login, size: size)
              }

              init(_ account: LinkedAccount, size: CGFloat = 44) {
                2️⃣self.init(name: account.name, login: account.login, size: size)
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("3️⃣", message: Self.ownerNote)]),
                FindingSpec(
                    "2️⃣", message: Self.message, notes: [NoteSpec("3️⃣", message: Self.ownerNote)]),
            ]
        )
    }

    @Test func wrapperSetupWithQueryCallFlaggedWithOwnerNote() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct 2️⃣TaskList: View {
              let issue: Issue

              @FetchAll private var tasks: [IssueTask]

              init(issue: Issue) {
                self.issue = issue
                1️⃣_tasks = FetchAll(Self.query(for: issue.id))
              }

              var body: some View { Text("x") }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("2️⃣", message: Self.ownerNote)])
            ]
        )
    }

    @Test func unannotatedClosureCallFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct 2️⃣Card<Content: View>: View {
              let content: Content

              init(content: () -> Content) {
                1️⃣self.content = content()
              }

              var body: some View { content }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("2️⃣", message: Self.ownerNote)])
            ]
        )
    }

    @Test func superInitNotFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            final class Wrapper: View {
              let title: String

              init(title: String) {
                self.title = title
                super.init()
              }

              var body: some View { Text(title) }
            }
            """
        )
    }

    @Test func nonViewInitNotFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct Model {
              let items: [Int]
              init(values: [Int]) { items = values.sorted() }
            }
            """
        )
    }

    private static let initialValueMessage =
        "SwiftUI evaluates this initial value each time a parent re-creates the view, so the work repeats. Pass the value in, or create it in a model"

    @Test func stateInitialValueCallFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            public struct 3️⃣MathView: View {
              private let latex: String
              @State private var cache = 1️⃣RenderCache()
              private var formatter = 2️⃣NumberFormatter.make(style: .decimal)

              public init(latex: String) { self.latex = latex }

              public var body: some View { Text(latex) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.initialValueMessage,
                    notes: [NoteSpec("3️⃣", message: Self.ownerNote)]),
                FindingSpec(
                    "2️⃣", message: Self.initialValueMessage,
                    notes: [NoteSpec("3️⃣", message: Self.ownerNote)]),
            ]
        )
    }

    /// The Thesis `MathPalette` shape: calls inside a collection literal default.
    @Test func callsInLiteralInitialValueFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct 2️⃣MathPalette: View {
              private let columns = 1️⃣[GridItem(.flexible()), GridItem(.flexible())]
              private let names = ["alpha", "beta"]
              private let pair = (0, "zero")

              var body: some View { LazyVGrid(columns: columns) {} }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.initialValueMessage,
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote)])
            ]
        )
    }

    @Test func plainInitialValuesAndStateObjectNotFlagged() {
        assertLint(
            NoWorkInViewInitializer.self,
            """
            struct Counter: View {
              @StateObject private var model = Model()
              @State private var count = 0
              @State private var items: [Item] = []
              @State private var mode = Mode.idle
              @AppStorage("size") private var size = 12.0
              static let shared = Cache()
              var total: Int { compute() }

              var body: some View { Text("x") }
            }

            struct Model {
              var cache = RenderCache()
            }
            """,
            findings: []
        )
    }
}
