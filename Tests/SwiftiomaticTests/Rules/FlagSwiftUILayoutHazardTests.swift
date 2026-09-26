import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagSwiftUILayoutHazardTests: RuleTesting {
    private static func geometryMessage(_ container: String) -> String {
        "'GeometryReader' directly inside '\(container)' gets no fixed size proposal and collapses or fills the axis. Measure with '.onGeometryChange' or read the geometry outside the scrolling container"
    }

    private static func nestedNavigationMessage(_ inner: String, _ outer: String) -> String {
        "'\(inner)' inside the content of another '\(outer)' makes a second navigation stack. Keep one navigation container and push with 'NavigationLink' or '.navigationDestination'"
    }

    private static func nestedNavigationViewMessage(_ view: String, _ outer: String) -> String {
        "'\(view)' declares its own navigation container and appears inside the content of '\(outer)'. Remove the inner container, or present the view modally"
    }

    private static func siblingScrollMessage(_ name: String, _ stack: String) -> String {
        "'\(name)' shares '\(stack)' with another unbounded scroll view on the same axis, so they split the space. Bound each one with '.frame' or merge them into one scroll view"
    }

    private static func ownerNote(_ name: String) -> String {
        "the enclosing '\(name)' starts here"
    }

    @Test func guidanceIsShould() { #expect(FlagSwiftUILayoutHazard.guidance == .should) }

    // MARK: GeometryReader

    @Test func geometryReaderInScrollViewFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            struct Gallery: View {
              var body: some View {
                2️⃣ScrollView {
                  1️⃣GeometryReader { proxy in
                    Text("\\(proxy.size.width)")
                  }
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.geometryMessage("ScrollView"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("ScrollView"))])
            ]
        )
    }

    @Test func geometryReaderThroughForEachInLazyStackFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            2️⃣LazyVStack {
              ForEach(items) { item in
                1️⃣GeometryReader { _ in Text(item.name) }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.geometryMessage("LazyVStack"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("LazyVStack"))])
            ]
        )
    }

    @Test func geometryReaderNotFlaggedWhenBoundedOrInModifier() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            ScrollView {
              VStack {
                GeometryReader { _ in Text("x") }
              }
              Text("row")
                .background { GeometryReader { _ in Color.clear } }
              Card { GeometryReader { _ in Text("y") } }
            }
            GeometryReader { _ in ScrollView { Text("z") } }
            """,
            findings: []
        )
    }

    // MARK: Nested navigation

    @Test func nestedNavigationStackFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            2️⃣NavigationStack {
              List {
                NavigationLink("Detail") {
                  1️⃣NavigationStack { Text("x") }
                }
              }
              .navigationDestination(for: Int.self) { _ in
                3️⃣NavigationSplitView { Text("a") } detail: { Text("b") }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.nestedNavigationMessage("NavigationStack", "NavigationStack"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("NavigationStack"))]),
                FindingSpec(
                    "3️⃣",
                    message: Self.nestedNavigationMessage("NavigationSplitView", "NavigationStack"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("NavigationStack"))]),
            ]
        )
    }

    @Test func sameFileViewWithOwnStackFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            struct Root: View {
              var body: some View {
                2️⃣NavigationStack {
                  NavigationLink("Detail") { 1️⃣Detail() }
                }
              }
            }

            struct Detail: View {
              var body: some View {
                NavigationStack { Text("detail") }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.nestedNavigationViewMessage("Detail", "NavigationStack"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("NavigationStack"))])
            ]
        )
    }

    @Test func navigationInSheetNotFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            struct Root: View {
              var body: some View {
                NavigationStack {
                  Text("x")
                    .sheet(isPresented: $show) { NavigationStack { Text("sheet") } }
                    .sheet(isPresented: $other) { Editor() }
                }
              }
            }

            struct Editor: View {
              var body: some View {
                NavigationStack { Text("editor") }
              }
            }
            """,
            findings: []
        )
    }

    // MARK: Sibling scroll views

    @Test func siblingListsFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            2️⃣VStack {
              1️⃣List(a) { Text($0) }
              Text("divider")
              3️⃣ScrollView { Text("b") }
                .padding()
              ScrollView(.horizontal) { Text("c") }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.siblingScrollMessage("List", "VStack"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("VStack"))]),
                FindingSpec(
                    "3️⃣", message: Self.siblingScrollMessage("ScrollView", "VStack"),
                    notes: [NoteSpec("2️⃣", message: Self.ownerNote("VStack"))]),
            ]
        )
    }

    @Test func boundedOrDifferentAxisSiblingsNotFlagged() {
        assertLint(
            FlagSwiftUILayoutHazard.self,
            """
            VStack {
              List(a) { Text($0) }
              ScrollView { Text("b") }
                .frame(height: 120)
            }
            HStack {
              ScrollView(.horizontal) { Text("a") }
              List(b) { Text($0) }
            }
            ZStack {
              List(a) { Text($0) }
              List(b) { Text($0) }
            }
            """,
            findings: []
        )
    }
}
