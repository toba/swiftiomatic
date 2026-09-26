@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForwardedViewInputTests: RuleTesting {
  private static func message(_ name: String, _ child: String) -> String {
    "'\(name)' is stored only to pass it unchanged to '\(child)'. Build the child in the parent and pass it in as content, or let the child read the value itself"
  }

  @Test func inputForwardedToChildFlagged() {
    assertLint(
      NoForwardedViewInput.self,
      """
      struct InspectorPane<Content: View>: View {
        @Environment(\\.inspectorError) private var error

        1️⃣let group: IssueGroup
        @ViewBuilder let content: () -> Content

        var body: some View {
          VStack(spacing: 0) {
            InspectorTitle(group: group)
            content()
            MessageBanner(message: error)
          }
        }
      }

      struct Banner: View {
        2️⃣let message: String?

        var body: some View { MessageBanner(message: self.message).padding() }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("group", "InspectorTitle")),
        FindingSpec("2️⃣", message: Self.message("message", "MessageBanner")),
      ]
    )
  }

  @Test func inputUsedOrAdaptedNotFlagged() {
    assertLint(
      NoForwardedViewInput.self,
      """
      struct Row: View {
        let item: Item
        let title: String
        let count: Int
        let unused: Int
        @Binding var isOpen: Bool
        let commit: (String) -> Void

        init(item: Item, title: String, count: Int, unused: Int, isOpen: Binding<Bool>, commit: @escaping (String) -> Void) {
          self.item = item
          self.title = title
          self.count = count
          self.unused = unused
          _isOpen = isOpen
          self.commit = commit
        }

        var body: some View {
          ItemView(item: item).id(item.id)
          Text(title.uppercased())
          Counter(value: count + 1)
          Editor(isOpen: $isOpen, commit: commit)
        }
      }

      struct Caption: View {
        let name: String
        var body: some View { Text(name) }
      }
      """
    )
  }
  @Test func inputPassedToNonViewOrFeedingDynamicPropertyNotFlagged() {
    // From Thesis `WritingActivityHeatMap.swift`
    assertLint(
      NoForwardedViewInput.self,
      """
      struct WritingActivityHeatMap: View {
        private let gridStart: Date
        private let columns: Int
        1️⃣private let label: String

        @Fetch private var activity: [DailyActivity] = []

        init(projectID: Node.ID?, label: String) {
          let gridStart = Date.now
          self.gridStart = gridStart
          columns = 3
          self.label = label
          _activity = Fetch(wrappedValue: [], Request(projectID: projectID, since: gridStart))
        }

        var body: some View {
          let grid = HeatMapGrid(activity, gridStart: gridStart, columns: columns)
          Summary(label: label)
        }
      }

      private struct HeatMapGrid {
        let cells: [Int]
        init(_ activity: [DailyActivity], gridStart: Date, columns: Int) { cells = [] }
      }

      private struct Summary: View {
        let label: String
        var body: some View { Text(label) }
      }

      struct Filtered: View {
        private let start: String
        @Fetch private var items: [Item] = []

        init(start: String) {
          self.start = start
          _items = Fetch(wrappedValue: [], Request(since: start))
        }

        var body: some View { Summary(label: start) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("label", "Summary")),
      ]
    )
  }
}
