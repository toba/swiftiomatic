@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoClosureInputInViewTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' stores a closure input. SwiftUI cannot compare a closure, so the view cannot skip 'body'. Store the value, or keep the action at the call site"
  }

  private static func useMessage(_ name: String) -> String {
    "This code uses the stored closure input '\(name)'. SwiftUI cannot compare a closure, so the view cannot skip 'body'. Pass a value or a binding instead"
  }

  private static func scopeMessage(_ member: String, _ name: String) -> String {
    "'\(member)' depends on the stored closure input '\(name)'. SwiftUI cannot compare a closure, so each parent update evaluates this view again"
  }

  @Test func guidanceIsShould() { #expect(NoClosureInputInView.guidance == .should) }

  @Test func fontPreviewActionFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      private struct FontPreview: View {
        let row: FontRow
        1️⃣let didSelect: () -> Void

        2️⃣var body: some View {
          Text(row.name).onTapGesture { 3️⃣didSelect() }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("didSelect")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "didSelect")),
        FindingSpec("3️⃣", message: Self.useMessage("didSelect")),
      ]
    )
  }

  @Test func popoverPickerDescriptionFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      public struct PopoverPicker<Popover: View>: View {
        private var label: LocalizedStringKey
        private var popover: Popover
        1️⃣private var description: () -> String

        2️⃣public var body: some View { Text(3️⃣description()) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("description")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "description")),
        FindingSpec("3️⃣", message: Self.useMessage("description")),
      ]
    )
  }

  @Test func attributedAndOptionalFunctionTypesFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct SymbolButton: View {
        1️⃣var action: @MainActor () -> Void
        2️⃣var onCancel: (() -> Void)?

        3️⃣var body: some View { Button("Go", action: 4️⃣action) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("action")),
        FindingSpec("2️⃣", message: Self.message("onCancel")),
        FindingSpec("3️⃣", message: Self.scopeMessage("body", "action")),
        FindingSpec("4️⃣", message: Self.useMessage("action")),
      ]
    )
  }

  @Test func viewModifierClosureFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct Hover: ViewModifier {
        1️⃣let onHover: (Bool) -> Void

        2️⃣func body(content: Content) -> some View { content.onHover(perform: 3️⃣onHover) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("onHover")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "onHover")),
        FindingSpec("3️⃣", message: Self.useMessage("onHover")),
      ]
    )
  }

  @Test func viewBuilderContentNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      public struct ConditionalScrollView<Content: View>: View {
        public var scrollable: Bool
        @ViewBuilder public var content: (ScrollViewProxy?) -> Content

        public var body: some View { content(nil) }
      }
      """
    )
  }

  @Test func contentBuilderAttributeNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct Panel: View {
        @ContentBuilder var content: () -> Body

        var body: some View { content() }
      }
      """
    )
  }

  @Test func closureReturningGenericViewParameterNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      public struct OptionSetPicker<Value: OptionSet, Label: View>: View {
        @Binding var selection: Value
        private var label: () -> Label

        public var body: some View { Button { } label: { label() } }
      }
      """
    )
  }

  @Test func computedAndStaticClosuresNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct Row: View {
        static let format: (Int) -> String = { "\\($0)" }
        var formatter: (Int) -> String { { "\\($0)" } }

        var body: some View { Text(Self.format(1)) }
      }
      """
    )
  }

  @Test func nonViewTypeNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct Handler {
        let action: () -> Void
      }
      """
    )
  }

  @Test func actionPassedToButtonFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      private struct SignInPrompt: View {
        let failure: String?
        1️⃣let signIn: () -> Void

        2️⃣var body: some View {
          VStack {
            Text("Connect")
            Button(action: 3️⃣signIn) {
              Label("Sign in", image: "Mark")
            }
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("signIn")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "signIn")),
        FindingSpec("3️⃣", message: Self.useMessage("signIn")),
      ]
    )
  }

  @Test func optionalActionTestedInModifiersFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      private struct CountColumn: View {
        let isBusy: Bool
        1️⃣let action: (() -> Void)?

        2️⃣var body: some View {
          Button {
            3️⃣action?()
          } label: {
            Text("1")
          }
          .allowsHitTesting(4️⃣action != nil && !isBusy)
          .accessibilityRemoveTraits(5️⃣self.action == nil ? .isButton : [])
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("action")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "action")),
        FindingSpec("3️⃣", message: Self.useMessage("action")),
        FindingSpec("4️⃣", message: Self.useMessage("action")),
        FindingSpec("5️⃣", message: Self.useMessage("action")),
      ]
    )
  }

  @Test func closureForwardedToChildViewFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct InspectorList<Model: Identifiable, Row: View>: View {
        let items: [Model]
        1️⃣let add: (String) -> Void
        @ViewBuilder let row: (Model) -> Row
        @State private var isAdding = false

        2️⃣var body: some View {
          List {
            ForEach(items) { item in row(item) }
            if isAdding {
              DraftField(isOpen: $isAdding, commit: 3️⃣add)
            }
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("add")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "add")),
        FindingSpec("3️⃣", message: Self.useMessage("add")),
      ]
    )
  }

  @Test func methodThatCallsClosureAndBodyThatCallsMethodFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct IssueComposer: View {
        @Environment(\\.dismiss) private var dismiss
        let project: Project?
        1️⃣let onCreate: (Issue.ID) -> Void
        @State private var subject = ""

        2️⃣var body: some View {
          NavigationStack {
            Form { TextField("Subject", text: $subject) }
              .toolbar { Button(role: .confirm, action: create) }
          }
        }

        /// Creates the issue.
        3️⃣private func create() {
          guard let project else { return }
          let issue = Issue(project: project, subject: subject)
          4️⃣onCreate(issue.id)
          dismiss()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("onCreate")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "onCreate")),
        FindingSpec("3️⃣", message: Self.scopeMessage("create", "onCreate")),
        FindingSpec("4️⃣", message: Self.useMessage("onCreate")),
      ]
    )
  }

  @Test func closureCalledInsideSubmitActionFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct ClosingReasonSheet: View {
        1️⃣let close: (String) -> Void
        @State private var reason = ""

        2️⃣var body: some View {
          let sheet = VStack {
            TextField("Why?", text: $reason)
              .onSubmit { if !reason.isEmpty { 3️⃣close(reason) } }
          }
          sheet.padding()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("close")),
        FindingSpec("2️⃣", message: Self.scopeMessage("body", "close")),
        FindingSpec("3️⃣", message: Self.useMessage("close")),
      ]
    )
  }

  @Test func initializerAssignmentNotFlaggedAsUse() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct ProjectComposer: View {
        1️⃣let onCreate: (Project) -> Void

        init(onCreate: @escaping (Project) -> Void) {
          self.onCreate = onCreate
        }

        var body: some View { Text("New") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("onCreate"))]
    )
  }

  @Test func builderContentUseNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct InspectorPane<Content: View, Add: View>: View {
        let title: String
        @ViewBuilder let content: () -> Content
        @ViewBuilder let add: () -> Add

        var body: some View {
          VStack {
            Text(title)
            content()
            add()
          }
        }
      }
      """
    )
  }

  @Test func sameNameOnOtherValueNotFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct CountStrip: View {
        let counts: [CountItem]

        var body: some View {
          ForEach(counts) { count in
            Text(count.text).onTapGesture { count.action?() }
          }
        }
      }
      """
    )
  }

  @Test func shadowedInputNameNotFlaggedAsUse() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct ActionList: View {
        1️⃣let action: () -> Void
        let items: [Item]

        var body: some View {
          ForEach(items) { action in Text(action.title) }
        }

        func label() -> String {
          let action = "Go"
          return action
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("action"))]
    )
  }
}
