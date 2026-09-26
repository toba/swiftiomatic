@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoBindingConstructionInViewTests: RuleTesting {
  private static let message =
    "'Binding(get:set:)' built in a view gives a new binding each update, and SwiftUI cannot compare it. Project a binding with '$' from the owner of the value, or move the logic into the model"

  @Test func guidanceIsShould() {
    #expect(NoBindingConstructionInView.guidance == .should)
  }

  /// The Thesis `ProjectNodeRow` and `OutlineList` shape: a local binding in `body`.
  @Test func localBindingInBodyFlagged() {
    assertLint(
      NoBindingConstructionInView.self,
      """
      struct ProjectNodeRow: View {
        @Binding var expanded: Set<Node.ID>
        var body: some View {
          let isExpanded = 1️⃣Binding<Bool>(
            get: { expanded.contains(node.id) },
            set: { if $0 { expanded.insert(node.id) } else { expanded.remove(node.id) } },
          )
          DisclosureGroup(isExpanded: isExpanded) { Text("x") }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  /// The Thesis `CitationStylePopover`, `ReferenceInspector` and `ReferenceContributorsEditor`
  /// shapes: a binding built inline as an argument, in a closure, and in a helper.
  @Test func directClosureAndHelperBindingsFlagged() {
    assertLint(
      NoBindingConstructionInView.self,
      """
      private struct ManagerForm: View {
        var manager: ReferenceManagerState
        var body: some View {
          Button("Disconnect") {}
            .confirmationDialog(
              "Keep synced references?",
              isPresented: 1️⃣Binding(
                get: { manager.pendingDisconnect != nil },
                set: { if !$0 { manager.pendingDisconnect = nil } },
              ),
              presenting: manager.pendingDisconnect,
            ) { _ in }
          Menu {
            Toggle("Institution", isOn: 2️⃣Binding(get: { isInstitution }, set: { setInstitution($0) }))
          } label: { Text("x") }
        }

        private func bind(_ keyPath: WritableKeyPath<MutablePerson, String?>) -> Binding<String> {
          3️⃣Binding(get: { "" }, set: { _ in })
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
        FindingSpec("3️⃣", message: Self.message),
      ]
    )
  }

  @Test func viewModifierBodyFlagged() {
    assertLint(
      NoBindingConstructionInView.self,
      """
      struct Sheet: ViewModifier {
        func body(content: Content) -> some View {
          content.sheet(isPresented: 1️⃣SwiftUI.Binding(get: { true }, set: { _ in })) { Text("x") }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func nonViewAndOtherBindingsNotFlagged() {
    assertLint(
      NoBindingConstructionInView.self,
      """
      @Observable final class Model {
        var flag = false
        var binding: Binding<Bool> { Binding(get: { self.flag }, set: { self.flag = $0 }) }
      }
      struct Row: View {
        @Binding var text: String
        var body: some View {
          TextField("x", text: $text)
          Toggle("y", isOn: .constant(true))
          Toggle("z", isOn: Binding($optional)!)
        }
      }
      """,
      findings: []
    )
  }
}
