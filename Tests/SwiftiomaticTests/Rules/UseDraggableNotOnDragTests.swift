import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseDraggableNotOnDragTests: RuleTesting {
  private static let onDrag =
    "'.onDrag' hands SwiftUI an 'NSItemProvider' — conform the payload to 'Transferable' and use '.draggable'"
  private static let itemProvider =
    "'NSItemProvider' predates 'Transferable' — conform the payload type to 'Transferable' and use '.draggable'"

  @Test func onDragModifierFlagged() {
    assertLint(
      UseDraggableNotOnDrag.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").1️⃣onDrag { provider() }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.onDrag)]
    )
  }

  @Test func itemProviderFlagged() {
    assertLint(
      UseDraggableNotOnDrag.self,
      """
      func provider(for url: URL) -> 1️⃣NSItemProvider {
        2️⃣NSItemProvider(object: url as NSURL)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.itemProvider),
        FindingSpec("2️⃣", message: Self.itemProvider),
      ]
    )
  }

  @Test func draggableNotFlagged() {
    assertLint(
      UseDraggableNotOnDrag.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").draggable(item)
        }
      }
      """,
      findings: []
    )
  }
}
