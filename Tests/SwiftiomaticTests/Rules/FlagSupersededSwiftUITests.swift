@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagSupersededSwiftUITests: RuleTesting {
  private static let stateObject =
    "'@StateObject' is superseded — use '@State' with an '@Observable' type"
  private static let observedObject =
    "'@ObservedObject' is superseded — pass '@Observable' values directly (or '@Bindable' for two-way bindings)"
  private static let environmentObject =
    "'@EnvironmentObject' is superseded — use '@Environment(MyType.self)' with an '@Observable' type"
  private static let published =
    "'@Published' is unnecessary on '@Observable' types — remove it"
  private static let observableObject =
    "'ObservableObject' conformance is superseded — use the '@Observable' macro"
  private static let navigationView =
    "'NavigationView' is deprecated — use 'NavigationStack' or 'NavigationSplitView'"

  @Test func stateObjectFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        1️⃣@StateObject var model = Model()
        var body: some View { Text("") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.stateObject)]
    )
  }

  @Test func observedObjectFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        1️⃣@ObservedObject var model: Model
        var body: some View { Text("") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.observedObject)]
    )
  }

  @Test func environmentObjectFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        1️⃣@EnvironmentObject var model: Model
        var body: some View { Text("") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.environmentObject)]
    )
  }

  @Test func publishedFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      final class Model: 2️⃣ObservableObject {
        1️⃣@Published var count = 0
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.published),
        FindingSpec("2️⃣", message: Self.observableObject),
      ]
    )
  }

  @Test func observableObjectConformanceFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      final class Model: 1️⃣ObservableObject {
        var count = 0
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.observableObject)]
    )
  }

  @Test func observableObjectInExtensionFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      extension Model: 1️⃣ObservableObject {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.observableObject)]
    )
  }

  @Test func observableObjectAmongOthersFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      final class Model: Sendable, 1️⃣ObservableObject, Identifiable {
        let id = UUID()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.observableObject)]
    )
  }

  @Test func navigationViewFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        var body: some View {
          1️⃣NavigationView {
            Text("")
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.navigationView)]
    )
  }

  @Test func observableMacroNotFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      @Observable
      final class Model {
        var count = 0
      }
      """,
      findings: []
    )
  }

  @Test func atStateNotFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        @State private var model = Model()
        var body: some View { Text("") }
      }
      """,
      findings: []
    )
  }

  @Test func navigationStackNotFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        var body: some View {
          NavigationStack {
            Text("")
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func navigationSplitViewNotFlagged() {
    assertLint(
      FlagSupersededSwiftUI.self,
      """
      struct V: View {
        var body: some View {
          NavigationSplitView {
            Text("")
          } detail: {
            Text("")
          }
        }
      }
      """,
      findings: []
    )
  }
}
