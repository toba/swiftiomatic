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

  @Test func stateSeededThroughIfLetOfComputedPropertyFlagged() {
    assertLint(
      NoOnAppearDerivedState.self,
      """
      struct CitationForm: View {
        @Binding var citations: [Entry]
        let index: Int
        @State private var location = ""
        @State private var locationType: LocationType = .page
        @FocusState private var isLocationFocused: Bool

        private var citation: Citation { citations[index].citation }

        var body: some View {
          Form {}
            .onAppear {
              isLocationFocused = true

              if let referenceLocation = citation.referenceLocation {
                if let type = referenceLocation.type { 1️⃣locationType = type }
                2️⃣location = referenceLocation.value.plainText
              }
            }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("locationType", "citation")),
        FindingSpec("2️⃣", message: Self.message("location", "citation")),
      ]
    )
  }

  @Test func stateSeededThroughGuardLetAndShorthandBindingFlagged() {
    assertLint(
      NoOnAppearDerivedState.self,
      """
      struct Editor: View {
        let initial: String?
        let fallback: Draft?
        @State private var text = ""
        @State private var title = ""

        var body: some View {
          Text("x").onAppear {
            if let fallback { 1️⃣title = fallback.title }
            guard let value = initial else { return }
            2️⃣text = value
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("title", "fallback")),
        FindingSpec("2️⃣", message: Self.message("text", "initial")),
      ]
    )
  }

  @Test func computedPropertyWithoutStoredInputsNotFlagged() {
    assertLint(
      NoOnAppearDerivedState.self,
      """
      struct Row: View {
        @State private var label = ""
        private var placeholder: String { "None" }

        var body: some View {
          Text(label).onAppear {
            if let first = placeholder.first { label = String(first) }
          }
        }
      }
      """
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
