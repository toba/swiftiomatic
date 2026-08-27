import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseTaskModifierNotOnAppearTests: RuleTesting {
  private static let message =
    "'.onAppear' that only starts a 'Task' leaks the task when the view goes away — use the '.task' modifier, which cancels with the view"

  @Test func onAppearStartingTaskFlagged() {
    assertLint(
      UseTaskModifierNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").1️⃣onAppear {
            Task { await load() }
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func performArgumentFlagged() {
    assertLint(
      UseTaskModifierNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").1️⃣onAppear(perform: { Task { await load() } })
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func synchronousOnAppearNotFlagged() {
    assertLint(
      UseTaskModifierNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").onAppear { logImpression() }
        }
      }
      """,
      findings: []
    )
  }

  @Test func onAppearWithMoreWorkNotFlagged() {
    assertLint(
      UseTaskModifierNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").onAppear {
            logImpression()
            Task { await load() }
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskModifierNotFlagged() {
    assertLint(
      UseTaskModifierNotOnAppear.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").task { await load() }
        }
      }
      """,
      findings: []
    )
  }
}
