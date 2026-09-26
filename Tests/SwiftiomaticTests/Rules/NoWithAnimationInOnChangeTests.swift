import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoWithAnimationInOnChangeTests: RuleTesting {
    private static let message =
        "'withAnimation' inside '.onChange(of:)' can lose to a non-animated transaction in the same update. Put '.animation(_:value:)' on the view that animates"
    private static let closureNote = "the '.onChange(of:)' action closure starts here"

    @Test func guidanceIsConsider() { #expect(NoWithAnimationInOnChange.guidance == .consider) }

    @Test func withAnimationInTrailingClosureFlagged() {
        assertLint(
            NoWithAnimationInOnChange.self,
            """
            struct Panel: View {
              @State private var expanded = false
              var body: some View {
                Text("x")
                  .onChange(of: selection) 2️⃣{
                    1️⃣withAnimation(.spring) {
                      expanded = true
                    }
                  }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("2️⃣", message: Self.closureNote)])
            ]
        )
    }

    @Test func withAnimationInLabeledActionFlagged() {
        assertLint(
            NoWithAnimationInOnChange.self,
            """
            Text("x").onChange(of: value, initial: true, 2️⃣{ old, new in
              print(old)
              1️⃣withAnimation { offset = new }
            })
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message, notes: [NoteSpec("2️⃣", message: Self.closureNote)])
            ]
        )
    }

    @Test func nestedWithAnimationNotFlagged() {
        assertLint(
            NoWithAnimationInOnChange.self,
            """
            Text("x").onChange(of: value) {
              Task { withAnimation { offset = 1 } }
              if value { helper { withAnimation { offset = 2 } } }
            }
            """,
            findings: []
        )
    }

    @Test func otherModifiersNotFlagged() {
        assertLint(
            NoWithAnimationInOnChange.self,
            """
            Button("Go") { withAnimation { expanded.toggle() } }
              .onAppear { withAnimation { shown = true } }
              .onChange(of: value) { offset = 1 }
            """,
            findings: []
        )
    }
}
