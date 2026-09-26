@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoClosureInputInViewTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' stores a closure input. SwiftUI cannot compare a closure, so the view cannot skip 'body'. Store the value, or keep the action at the call site"
  }

  @Test func guidanceIsShould() {
    #expect(NoClosureInputInView.guidance == .should)
  }

  @Test func fontPreviewActionFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      private struct FontPreview: View {
        let row: FontRow
        1️⃣let didSelect: () -> Void

        var body: some View {
          Text(row.name).onTapGesture { didSelect() }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("didSelect"))]
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

        public var body: some View { Text(description()) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("description"))]
    )
  }

  @Test func attributedAndOptionalFunctionTypesFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct SymbolButton: View {
        1️⃣var action: @MainActor () -> Void
        2️⃣var onCancel: (() -> Void)?

        var body: some View { Button("Go", action: action) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("action")),
        FindingSpec("2️⃣", message: Self.message("onCancel")),
      ]
    )
  }

  @Test func viewModifierClosureFlagged() {
    assertLint(
      NoClosureInputInView.self,
      """
      struct Hover: ViewModifier {
        1️⃣let onHover: (Bool) -> Void

        func body(content: Content) -> some View { content.onHover(perform: onHover) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("onHover"))]
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
}
