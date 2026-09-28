import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoLifecycleModifierOnViewListTests: RuleTesting {
    private static func conditional(_ modifier: String) -> String {
        "'.\(modifier)' on conditional content attaches to each branch, so it runs again when the branch changes. Attach it to one container, such as a 'VStack', or write it on each branch"
    }

    private static func list(_ modifier: String) -> String {
        "'.\(modifier)' on a list of views attaches to each view and runs once per view. Attach it to one container, such as a 'VStack', or move per-element work into the row"
    }

    @Test func guidanceIsShouldNot() {
        #expect(NoLifecycleModifierOnViewList.guidance == .shouldNot)
    }

    /// The jig `ClaudeAccountsView` and musup `TrackTable` shape: a `Group` around an `if`.
    @Test func groupAroundConditionalFlagged() {
        assertLint(
            NoLifecycleModifierOnViewList.self,
            """
            struct TrackTable: View {
              var body: some View {
                Group {
                  if tracks.isEmpty { empty() } else { table }
                }
                .1️⃣onChange(of: tracks) { reload() }
                .padding()
                .2️⃣task { await load() }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.conditional("onChange")),
                FindingSpec("2️⃣", message: Self.conditional("task")),
            ]
        )
    }

    /// The musup `TrackInspector` shape: a `@ViewBuilder` property whose content is an `if`.
    @Test func viewBuilderMemberWithConditionalFlagged() {
        assertLint(
            NoLifecycleModifierOnViewList.self,
            """
            struct TrackInspector: View {
              var body: some View {
                content
                  .1️⃣task(id: selection) { await load() }
              }
              @ViewBuilder private var content: some View {
                if tracks.isEmpty {
                  Text("None")
                } else {
                  panes
                }
              }
              @ViewBuilder private func rows() -> some View {
                switch mode {
                case .a: Text("a")
                case .b: Text("b")
                }
              }
              var other: some View {
                rows().2️⃣onAppear { start() }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.conditional("task")),
                FindingSpec("2️⃣", message: Self.conditional("onAppear")),
            ]
        )
    }

    /// The Thesis `ActivityIndicator` shape: a same-file view whose `body` is a bare `if`.
    @Test func sameFileViewWithConditionalOrListBodyFlagged() {
        assertLint(
            NoLifecycleModifierOnViewList.self,
            """
            struct ActivityIndicator: View {
              var body: some View {
                if isActive { ProgressView() }
              }
            }
            struct Rows: View {
              var body: some View {
                ForEach(accounts) { AccountRow(account: $0) }
              }
            }
            struct Screen: View {
              var body: some View {
                VStack {
                  ActivityIndicator().1️⃣task { await refresh() }
                  Rows().2️⃣onAppear { refresh() }
                }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.conditional("task")),
                FindingSpec("2️⃣", message: Self.list("onAppear")),
            ]
        )
    }

    @Test func groupOfSeveralViewsAndForEachFlagged() {
        assertLint(
            NoLifecycleModifierOnViewList.self,
            """
            struct Summary: View {
              var body: some View {
                VStack {
                  Group {
                    SummaryHeader(summary: summary)
                    TransactionList(transactions: transactions)
                  }
                  .1️⃣task { await model.refresh() }
                  ForEach(items) { Text($0.name) }
                    .2️⃣onReceive(timer) { _ in tick() }
                  Group { Text("a"); Text("b") }.3️⃣onDisappear { stop() }
                }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.list("task")),
                FindingSpec("2️⃣", message: Self.list("onReceive")),
                FindingSpec("3️⃣", message: Self.list("onDisappear")),
            ]
        )
    }

    @Test func singleViewsAndOtherModifiersNotFlagged() {
        assertLint(
            NoLifecycleModifierOnViewList.self,
            """
            struct Screen: View {
              var body: some View {
                VStack {
                  if isLoading { ProgressView() } else { ContentView() }
                }
                .task { await load() }
                Group {
                  let title = name.uppercased()
                  Text(title)
                }
                .onAppear { start() }
                Group {
                  if isLoading { ProgressView() } else { ContentView() }
                }
                .padding()
                .navigationTitle("x")
                plain.task { await load() }
                ElsewhereView().task { await load() }
                Single().onAppear { start() }
              }
              var plain: some View { Text("x") }
            }
            struct Single: View {
              var body: some View {
                List { ForEach(items) { Text($0) } }
              }
            }
            """,
            findings: []
        )
    }
}
