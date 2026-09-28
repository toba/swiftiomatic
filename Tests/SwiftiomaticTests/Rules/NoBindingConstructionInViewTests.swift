import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoBindingConstructionInViewTests: RuleTesting {
    private static let message =
        "'Binding(get:set:)' built in a view allocates two closures on each update and gives a binding that SwiftUI cannot compare. Project the binding with '$' through a labeled subscript or a property on the owner of the value, such as '$model[isSaved: id]'"

    private static func helper(_ name: String) -> String {
        "'\(name)' builds a 'Binding(get:set:)', which allocates two closures on each update of this view and gives a binding that SwiftUI cannot compare. Project the binding with '$' through a labeled subscript or a property on the owner of the value"
    }

    @Test func guidanceIsShouldNot() { #expect(NoBindingConstructionInView.guidance == .shouldNot) }

    /// The jig `ContentView` and Thesis `AcademicDisciplinePicker` shape: a computed binding in the
    /// trailing-closure form, and the jig `ProjectList` shape: the same form as a modifier
    /// argument.
    @Test func trailingClosureFormsFlagged() {
        assertLint(
            NoBindingConstructionInView.self,
            """
            struct ContentView: View {
              @Binding private var selection: Set<Item>
              @State private var removing: Project?
              private var singleSelection: Binding<Item?> {
                1️⃣Binding { selection.first } set: { newValue in
                  selection = newValue.map { [$0] } ?? []
                }
              }
              private var named: Binding<String> {
                2️⃣Binding(get: { "" }) { _ in }
              }
              var body: some View {
                List {}
                  .confirmationDialog(
                    "Remove",
                    isPresented: 3️⃣Binding { removing != nil } set: { if !$0 { removing = nil } }
                  ) {}
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

    /// The jig, Thesis and musup shape: a model helper in another file builds the binding, and a
    /// view reads the helper.
    @Test func otherFileModelHelperFlagged() {
        assertLint(
            NoBindingConstructionInView.self,
            """
            struct Editor: View {
              let model: EditorModel
              var body: some View {
                Toggle("Saved", isOn: model.1️⃣isSaved(id))
                Text(model.title)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.helper("EditorModel.isSaved"))],
            otherFiles: [
                "/tmp/EditorModel.swift": """
                @Observable final class EditorModel {
                  var saved: Set<Int> = []
                  var title = ""
                  func isSaved(_ id: Int) -> Binding<Bool> {
                    Binding(get: { self.saved.contains(id) }, set: { _ in })
                  }
                }
                """
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
                Toggle("w", isOn: Binding(projectedValue: $flag))
              }
            }
            """,
            findings: []
        )
    }
}
