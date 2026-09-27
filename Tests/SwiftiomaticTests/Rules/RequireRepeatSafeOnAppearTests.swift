@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireRepeatSafeOnAppearTests: RuleTesting {
  private static func message(_ write: String) -> String {
    "'.onAppear' runs each time the view appears, and '\(write)' does not give the same result when it repeats. Guard it, or move it to the owner of the state"
  }

  private static func callMessage(_ call: String) -> String {
    "'.onAppear' runs each time the view appears, so '\(call)' runs again on each appearance. Make sure the call is repeat-safe, or guard it with state so that it runs once"
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

  @Test func paginationCallFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      private struct IssueListItem: View {
        let isLast: Bool
        let reachedEnd: () -> Void

        var body: some View {
          IssueRow()
            .tag(1)
            .onAppear { if isLast { 1️⃣reachedEnd() } }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.callMessage("reachedEnd()"))]
    )
  }

  @Test func selfMethodCallFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Detail: View {
        var body: some View {
          Text("x").onAppear(perform: { 1️⃣self.loadDetails(for: id) })
        }

        func loadDetails(for id: Int) {}
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.callMessage("self.loadDetails(for: id)"))]
    )
  }

  @Test func callGuardedByStateNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct BirdDetailView: View {
        @State private var displayName = ""
        @State private var didLoad = false

        var body: some View {
          Text(displayName)
            .onAppear {
              guard displayName.isEmpty else { return }
              prepareName()
            }
            .onDisappear { }
            .onAppear { if !didLoad { load() } }
        }

        func prepareName() {}
        func load() {}
      }
      """
    )
  }

  @Test func harmlessCallsNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("x").onAppear {
            print("appeared")
            withAnimation { isShown = true }
            proxy.scrollTo(id)
            Task { await model.refresh() }
          }
        }
      }
      """
    )
  }

  @Test func freeFunctionCallNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Gauge: View {
        let a: Int
        let b: Int

        var body: some View {
          Text("x").onAppear { limit = max(a, b) }
        }
      }
      """
    )
  }

  @Test func callGuardedByStateInMainDeclarationFromExtensionNotFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Feed: View {
        @State private var didLoad = false

        var body: some View { content }

        func load() {}
      }

      extension Feed {
        var content: some View {
          Text("x").onAppear { if !didLoad { load() } }
        }
      }
      """
    )
  }

  @Test func unguardedMethodCallInExtensionFlagged() {
    assertLint(
      RequireRepeatSafeOnAppear.self,
      """
      struct Feed: View {
        var body: some View { content }

        func load() {}
      }

      extension Feed {
        var content: some View {
          Text("x").onAppear { 1️⃣load() }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.callMessage("load()"))]
    )
  }
}
