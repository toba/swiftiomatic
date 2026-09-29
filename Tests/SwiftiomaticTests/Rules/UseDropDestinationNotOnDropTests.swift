import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseDropDestinationNotOnDropTests: RuleTesting {
  private static let message =
    "'.onDrop(of:)' hands the drop an untyped 'NSItemProvider'. Use '.dropDestination(for:)' with a 'Transferable' type"

  @Test func trailingClosureFlagged() {
    assertLint(
      UseDropDestinationNotOnDrop.self,
      """
      struct Board: View {
        var body: some View {
          Color.clear.1️⃣onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            load(providers)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func performArgumentFlagged() {
    assertLint(
      UseDropDestinationNotOnDrop.self,
      """
      struct Board: View {
        var body: some View {
          Color.clear
            .1️⃣onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func locationClosureFlagged() {
    assertLint(
      UseDropDestinationNotOnDrop.self,
      """
      struct Board: View {
        var body: some View {
          Color.clear.1️⃣onDrop(of: [.text], isTargeted: nil) { providers, location in
            true
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func delegateFormNotFlagged() {
    assertLint(
      UseDropDestinationNotOnDrop.self,
      """
      struct Board: View {
        var body: some View {
          Color.clear.onDrop(of: [.text], delegate: BoardDropDelegate(items: $items))
        }
      }
      """,
      findings: []
    )
  }

  @Test func otherOnDropNotFlagged() {
    assertLint(
      UseDropDestinationNotOnDrop.self,
      """
      model.onDrop(handler)
      onDrop(of: [.text]) { _ in true }
      """,
      findings: []
    )
  }

  @Test func dropDestinationNotFlagged() {
    assertLint(
      UseDropDestinationNotOnDrop.self,
      """
      struct Board: View {
        var body: some View {
          Color.clear.dropDestination(for: String.self) { items, location in
            true
          }
        }
      }
      """,
      findings: []
    )
  }
}
