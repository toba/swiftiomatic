@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantMainActorOnViewTests: RuleTesting {
  @Test func mainActorOnViewStruct() {
    assertFormatting(
      RedundantMainActorOnView.self,
      input: """
        1️⃣@MainActor
        struct ContentView: View {
          var body: some View { Text("hi") }
        }
        """,
      expected: """
        struct ContentView: View {
          var body: some View { Text("hi") }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@MainActor'; SwiftUI 'View', 'App', and 'Scene' are already main-actor-isolated"),
      ]
    )
  }

  @Test func mainActorOnAppStruct() {
    assertFormatting(
      RedundantMainActorOnView.self,
      input: """
        1️⃣@MainActor
        struct MyApp: App {
          var body: some Scene { WindowGroup { ContentView() } }
        }
        """,
      expected: """
        struct MyApp: App {
          var body: some Scene { WindowGroup { ContentView() } }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@MainActor'; SwiftUI 'View', 'App', and 'Scene' are already main-actor-isolated"),
      ]
    )
  }

  @Test func mainActorOnSceneStruct() {
    assertFormatting(
      RedundantMainActorOnView.self,
      input: """
        1️⃣@MainActor
        struct MyScene: Scene {
          var body: some Scene { WindowGroup { Text("hi") } }
        }
        """,
      expected: """
        struct MyScene: Scene {
          var body: some Scene { WindowGroup { Text("hi") } }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@MainActor'; SwiftUI 'View', 'App', and 'Scene' are already main-actor-isolated"),
      ]
    )
  }

  @Test func mainActorOnNonViewStructUntouched() {
    assertFormatting(
      RedundantMainActorOnView.self,
      input: """
        @MainActor
        struct ViewModel {
          var count = 0
        }
        """,
      expected: """
        @MainActor
        struct ViewModel {
          var count = 0
        }
        """,
      findings: []
    )
  }

  @Test func viewWithoutMainActorUntouched() {
    assertFormatting(
      RedundantMainActorOnView.self,
      input: """
        struct ContentView: View {
          var body: some View { Text("hi") }
        }
        """,
      expected: """
        struct ContentView: View {
          var body: some View { Text("hi") }
        }
        """,
      findings: []
    )
  }

  @Test func mainActorPreservedAlongsideOtherAttributes() {
    assertFormatting(
      RedundantMainActorOnView.self,
      input: """
        @available(macOS 26, *)
        1️⃣@MainActor
        struct ContentView: View {
          var body: some View { Text("hi") }
        }
        """,
      expected: """
        @available(macOS 26, *)
        struct ContentView: View {
          var body: some View { Text("hi") }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '@MainActor'; SwiftUI 'View', 'App', and 'Scene' are already main-actor-isolated"),
      ]
    )
  }
}
