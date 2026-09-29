import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseAnimationWithValueTests: RuleTesting {
  private static let message =
    "'.animation(_:)' without 'value:' is deprecated and animates every change. Use '.animation(_:value:)' or '.animation(_:body:)'"

  @Test func oneArgumentFormFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Row: View {
        var body: some View {
          Text("row")
            .1️⃣animation(.default)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func oneArgumentNilFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").1️⃣animation(nil)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func contentReceiverFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Fade: ViewModifier {
        func body(content: Content) -> some View {
          content.1️⃣animation(.easeIn(duration: 0.2))
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func valueFormNotFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Row: View {
        var body: some View {
          Text("row")
            .animation(.default, value: isOn)
            .animation(nil, value: isOn)
        }
      }
      """,
      findings: []
    )
  }

  @Test func bodyClosureFormNotFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").animation(.smooth) { content in
            content.opacity(isOn ? 1 : 0)
          }
          Text("row").animation(.smooth, body: { $0.scaleEffect(2) })
        }
      }
      """,
      findings: []
    )
  }

  @Test func bindingAnimationNotFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Row: View {
        var body: some View {
          Toggle("On", isOn: $isOn.animation(.spring))
          Toggle("On", isOn: self.$isOn.animation(.spring))
        }
      }
      """,
      findings: []
    )
  }

  @Test func transitionAnimationNotFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      struct Row: View {
        var body: some View {
          Text("row")
            .transition(.opacity.animation(.easeIn))
            .transition(AnyTransition.slide.animation(.default))
        }
      }
      """,
      findings: []
    )
  }

  @Test func noArgumentsNotFlagged() {
    assertLint(
      UseAnimationWithValue.self,
      """
      let binding = $isOn.animation()
      """,
      findings: []
    )
  }
}
