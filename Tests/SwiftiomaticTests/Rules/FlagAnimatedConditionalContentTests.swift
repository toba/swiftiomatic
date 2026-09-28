import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagAnimatedConditionalContentTests: RuleTesting {
    private static let message =
        "'.animation(_:value:)' animates content that holds an 'if' or 'switch', so the changing parts can animate as separate pieces. When the parts must move as one unit, add 'geometryGroup()' around them"

    @Test func guidanceIsConsider() {
        #expect(FlagAnimatedConditionalContent.guidance == .consider)
    }

    /// The Thesis `ContentView` shape: a `Group` with a `switch` and an overlay with an `if`.
    @Test func animatedConditionalContentFlagged() {
        assertLint(
            FlagAnimatedConditionalContent.self,
            """
            struct ContentView: View {
              var body: some View {
                Group {
                  switch mode {
                  case .edit: EditorView()
                  case .read: ReaderView()
                  }
                }
                .overlay(alignment: .topLeading) {
                  if search.hasResults { SearchOverlay() }
                }
                .1️⃣animation(.smooth(duration: 0.15), value: search.hasResults)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func plainOrGroupedAnimationNotFlagged() {
        assertLint(
            FlagAnimatedConditionalContent.self,
            """
            struct StatusLabel: View {
              var body: some View {
                Text(title)
                  .frame(maxWidth: .infinity, alignment: isDone ? .trailing : .leading)
                  .animation(.default, value: isDone)
                HStack {
                  if isDone { Image(systemName: "checkmark") }
                  Text(title)
                }
                .geometryGroup()
                .animation(.default, value: isDone)
                VStack {
                  if isDone { Text("Done") }
                }
                .animation(.default)
              }
            }
            """,
            findings: []
        )
    }
}
