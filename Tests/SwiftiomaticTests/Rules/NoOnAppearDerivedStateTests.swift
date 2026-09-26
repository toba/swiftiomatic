@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoOnAppearDerivedStateTests: RuleTesting {
  private static func message(_ target: String, _ source: String) -> String {
    "'.onAppear' derives '\(target)' from '\(source)' once, so '\(target)' goes stale when '\(source)' changes. Compute '\(target)' where it is read, or use '.onChange(of: \(source), initial: true)'"
  }

  @Test func guidanceIsConsider() {
    #expect(NoOnAppearDerivedState.guidance == .consider)
  }

  @Test func stateDerivedFromInputFlagged() {
    assertLint(
      NoOnAppearDerivedState.self,
      """
      private struct SymbolCell: View {
        @State private var isSelected = false
        @State private var isHovered = false

        var name: String
        @Binding var selection: String?

        var body: some View {
          Image(systemName: name)
            .onAppear { 1️⃣isSelected = selection == name }
            .onTapGesture { selection = name }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("isSelected", "selection"))]
    )
  }

  @Test func constantsSelfUpdatesAndNonStateTargetsNotFlagged() {
    assertLint(
      NoOnAppearDerivedState.self,
      """
      struct Row: View {
        @State private var isFocused = false
        @State private var count = 0
        @State private var draft = ""
        let isInitiallyFocused: Bool
        let model: Model

        var body: some View {
          Text("x").onAppear {
            if isInitiallyFocused { isFocused = true }
            count = count + 1
            model.title = draft
            let local = 3
            draft = String(local)
          }
        }
      }
      """
    )
  }
}
