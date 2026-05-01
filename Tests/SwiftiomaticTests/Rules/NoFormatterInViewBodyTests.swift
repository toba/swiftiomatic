@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoFormatterInViewBodyTests: RuleTesting {
  @Test func numberFormatterInBody() {
    assertLint(
      NoFormatterInViewBody.self,
      """
      struct ContentView: View {
        var body: some View {
          let formatter = 1️⃣NumberFormatter()
          return Text(formatter.string(from: 1) ?? "")
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'NumberFormatter' is built inside SwiftUI 'body' — re-allocated on every render. Hoist to a static let."),
      ]
    )
  }

  @Test func dateFormatterInBody() {
    assertLint(
      NoFormatterInViewBody.self,
      """
      struct ContentView: View {
        var body: some View {
          Text(1️⃣DateFormatter().string(from: Date()))
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'DateFormatter' is built inside SwiftUI 'body' — re-allocated on every render. Hoist to a static let."),
      ]
    )
  }

  @Test func formatterInSceneBody() {
    assertLint(
      NoFormatterInViewBody.self,
      """
      struct MyApp: App {
        var body: some Scene {
          let formatter = 1️⃣MeasurementFormatter()
          return WindowGroup { Text(formatter.string(from: m)) }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'MeasurementFormatter' is built inside SwiftUI 'body' — re-allocated on every render. Hoist to a static let."),
      ]
    )
  }

  @Test func formatterAsStoredPropertyNotFlagged() {
    assertLint(
      NoFormatterInViewBody.self,
      """
      struct ContentView: View {
        let formatter = NumberFormatter()
        var body: some View {
          Text(formatter.string(from: 1) ?? "")
        }
      }
      """,
      findings: []
    )
  }

  @Test func formatterInRegularFunctionNotFlagged() {
    assertLint(
      NoFormatterInViewBody.self,
      """
      func makeText() -> String {
        let formatter = NumberFormatter()
        return formatter.string(from: 1) ?? ""
      }
      """,
      findings: []
    )
  }

  @Test func formatterInBodyOfNonViewTypeAnnotationNotFlagged() {
    assertLint(
      NoFormatterInViewBody.self,
      """
      struct Helper {
        var body: String {
          let formatter = NumberFormatter()
          return formatter.string(from: 1) ?? ""
        }
      }
      """,
      findings: []
    )
  }
}
