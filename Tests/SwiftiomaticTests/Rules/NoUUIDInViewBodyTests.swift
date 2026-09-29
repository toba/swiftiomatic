import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoUUIDInViewBodyTests: RuleTesting {
  private static let message =
    "'UUID()' makes a new identity on each 'body' evaluation, which resets state and animations. Store the identifier in the model"

  @Test func uuidInBodyFlagged() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").id(1️⃣UUID())
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func uuidInHelperFlagged() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      struct Row: View {
        var body: some View {
          content
        }
        private var content: some View {
          Text("row").id(1️⃣UUID())
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func uuidInForEachArgumentsFlagged() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      struct List: View {
        let names: [String]
        var body: some View {
          ForEach(names.map { Item(id: 1️⃣UUID(), name: $0) }) { item in
            Text(item.name)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func uuidInForEachOutsideBodyFlagged() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      extension View {
        func rows(_ names: [String]) -> some View {
          ForEach(names.map { Item(id: 1️⃣UUID(), name: $0) }, id: \\.id) { item in
            Text(item.name)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func deferredAndStoredNotFlagged() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      struct Item: Identifiable {
        let id = UUID()
      }
      struct Row: View {
        @State private var token = UUID()
        var body: some View {
          Button("Reset") { token = UUID() }
            .onAppear { token = UUID() }
            .id(token)
        }
      }
      """,
      findings: []
    )
  }

  @Test func uuidWithArgumentsNotFlagged() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      struct Row: View {
        var body: some View {
          Text("row").id(UUID(uuidString: fixed))
        }
      }
      """,
      findings: []
    )
  }

  @Test func forEachContentClosureNotCountedTwice() {
    assertLint(
      NoUUIDInViewBody.self,
      """
      struct List: View {
        var body: some View {
          ForEach(items, id: \\.id) { item in
            Text(item.name).id(1️⃣UUID())
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }
}
