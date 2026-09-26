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
}
