@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantMainActorOnViewTests: RuleTesting {
  @Test func mainActorOnViewStruct() {
    assertFormatting(
      DropRedundantMainActorOnView.self,
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
      DropRedundantMainActorOnView.self,
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
      DropRedundantMainActorOnView.self,
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
      DropRedundantMainActorOnView.self,
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
      DropRedundantMainActorOnView.self,
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
      DropRedundantMainActorOnView.self,
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
