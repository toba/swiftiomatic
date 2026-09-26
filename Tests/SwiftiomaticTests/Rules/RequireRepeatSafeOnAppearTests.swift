@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireRepeatSafeOnAppearTests: RuleTesting {
  private static func message(_ write: String) -> String {
    "'.onAppear' runs each time the view appears, and '\(write)' does not give the same result when it repeats. Guard it, or move it to the owner of the state"
  }

  @Test func guidanceIsConsider() {
    #expect(RequireRepeatSafeOnAppear.guidance == .consider)
  }

  @Test func compoundAssignmentFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Counter: View {
        @State private var visits = 0

        var body: some View {
          Text("x").onAppear { 1️⃣visits += 1 }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("visits += 1"))]
    )
  }

  @Test func appendAndInsertFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Log: View {
        @State private var events: [String] = []
        @State private var seen: Set<String> = []

        var body: some View {
          Text("x").onAppear(perform: {
            1️⃣events.append("appeared")
            2️⃣seen.insert("x")
            3️⃣isExpanded.toggle()
          })
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("events.append(\"appeared\")")),
        FindingSpec("2️⃣", message: Self.message("seen.insert(\"x\")")),
        FindingSpec("3️⃣", message: Self.message("isExpanded.toggle()")),
      ]
    )
  }

  @Test func selfReferentialAssignmentFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Counter: View {
        var body: some View {
          Text("x").onAppear { 1️⃣self.count = count + 1 }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("self.count = count + 1"))]
    )
  }

  @Test func enumPickerFocusNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      public struct EnumPicker<Item: Pickable>: View {
        @FocusState private var isFocused: Bool
        private let isInitiallyFocused: Bool

        public var body: some View {
          Picker(label, selection: $selection) { Text("x") }
            .focused($isFocused)
            .onAppear { if isInitiallyFocused { isFocused = true } }
        }
      }
      """
    )
  }

  @Test func plainAssignmentsAndComparisonsNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("x").onAppear {
            offset = .zero
            isActive = count >= 1
            items = items.isEmpty ? defaults : items
          }
        }
      }
      """
    )
  }

  @Test func otherModifiersNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Button("Add") { count += 1 }.onDisappear { events.append("gone") }
        }
      }
      """
    )
  }
}
