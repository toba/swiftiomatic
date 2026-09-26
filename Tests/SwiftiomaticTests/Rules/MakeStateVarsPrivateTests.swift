@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct MakeStateVarsPrivateTests: RuleTesting {

  // MARK: - Basic transformations

  @Test func privateState() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        struct Counter: View {
          @State 1️⃣var counter: Int
        }
        """,
      expected: """
        struct Counter: View {
          @State private var counter: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'private' to this @State property"),
      ]
    )
  }

  @Test func privateStateObject() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        struct Counter: View {
          @StateObject 1️⃣var counter: Int
        }
        """,
      expected: """
        struct Counter: View {
          @StateObject private var counter: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'private' to this @StateObject property"),
      ]
    )
  }

  @Test func stateVariableOnPreviousLine() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        struct Counter: View {
          @State
          1️⃣var counter: Int
        }
        """,
      expected: """
        struct Counter: View {
          @State
          private var counter: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'private' to this @State property"),
      ]
    )
  }

  @Test func guidanceIsMust() {
    #expect(MakeStateVarsPrivate.guidance == .must)
  }

  /// The Thesis `ContentView` and `ProjectTree` shape: `@AppStorage` with no access control.
  @Test func privateAppStorageAndFriends() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        struct ContentView: View {
          @AppStorage("inspector") 1️⃣var selectedTab: InspectorTab = .settings
          @AppStorage(.expandedProjectNodes) 2️⃣var expandedNodes: ExpandedIDs
          @SceneStorage("tab") 3️⃣var tab = 0
          @FocusState 4️⃣var focus: FocusArea?
          @GestureState 5️⃣var offset: CGSize = .zero
          @Binding var filter: ReferenceFilter
          @Environment(\\.editorTheme) var theme
        }
        """,
      expected: """
        struct ContentView: View {
          @AppStorage("inspector") private var selectedTab: InspectorTab = .settings
          @AppStorage(.expandedProjectNodes) private var expandedNodes: ExpandedIDs
          @SceneStorage("tab") private var tab = 0
          @FocusState private var focus: FocusArea?
          @GestureState private var offset: CGSize = .zero
          @Binding var filter: ReferenceFilter
          @Environment(\\.editorTheme) var theme
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'private' to this @AppStorage property"),
        FindingSpec("2️⃣", message: "add 'private' to this @AppStorage property"),
        FindingSpec("3️⃣", message: "add 'private' to this @SceneStorage property"),
        FindingSpec("4️⃣", message: "add 'private' to this @FocusState property"),
        FindingSpec("5️⃣", message: "add 'private' to this @GestureState property"),
      ]
    )
  }

  @Test func privateAppStorageUnchanged() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @AppStorage("showReferenceFilter") private var formPresented: Bool = false
        """,
      expected: """
        @AppStorage("showReferenceFilter") private var formPresented: Bool = false
        """,
      findings: []
    )
  }

  // MARK: - No-change cases

  @Test func useExisting() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @State private var counter: Int
        """,
      expected: """
        @State private var counter: Int
        """,
      findings: []
    )
  }

  @Test func respectingPublicOverride() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @StateObject public var counter: Int
        """,
      expected: """
        @StateObject public var counter: Int
        """,
      findings: []
    )
  }

  @Test func respectingPackageOverride() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @State package var counter: Int
        """,
      expected: """
        @State package var counter: Int
        """,
      findings: []
    )
  }

  @Test func respectingOverrideWithSetterModifier() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @State private(set) var counter: Int
        """,
      expected: """
        @State private(set) var counter: Int
        """,
      findings: []
    )
  }

  @Test func respectingOverrideWithExistingAccessAndSetterModifier() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @StateObject public private(set) var counter: Int
        """,
      expected: """
        @StateObject public private(set) var counter: Int
        """,
      findings: []
    )
  }

  @Test func withPreviewableOnSameLine() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @Previewable @StateObject var counter: Int
        """,
      expected: """
        @Previewable @StateObject var counter: Int
        """,
      findings: []
    )
  }

  @Test func withPreviewableOnPreviousLine() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @Previewable
        @State var counter: Int
        """,
      expected: """
        @Previewable
        @State var counter: Int
        """,
      findings: []
    )
  }

  @Test func propertyOutsideViewTypeUnchanged() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @Observable final class Settings {
          @ObservationIgnored @AppStorage("k") var theme: String = "light"
        }

        struct Model {
          @State var counter: Int
        }

        @State var topLevel: Int
        """,
      expected: """
        @Observable final class Settings {
          @ObservationIgnored @AppStorage("k") var theme: String = "light"
        }

        struct Model {
          @State var counter: Int
        }

        @State var topLevel: Int
        """,
      findings: []
    )
  }

  @Test func nonStateVariableUnchanged() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        var counter: Int
        """,
      expected: """
        var counter: Int
        """,
      findings: []
    )
  }
}
