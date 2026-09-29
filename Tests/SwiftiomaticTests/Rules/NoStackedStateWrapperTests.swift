import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoStackedStateWrapperTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'@\(name)' stacks a second property wrapper on '@State'. SwiftUI does not support a second wrapper on '@State'"
  }

  @Test func wrapperAfterStateFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      struct Settings: View {
        @State 1️⃣@Clamped(0...10) private var level = 5
        var body: some View { Text("") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("Clamped"))]
    )
  }

  @Test func wrapperBeforeStateFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      struct Settings: View {
        1️⃣@Trimmed @State private var name = ""
        var body: some View { Text(name) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("Trimmed"))]
    )
  }

  @Test func qualifiedNamesFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      struct Settings: View {
        @SwiftUI.State 1️⃣@Lib.Logged var count = 0
        var body: some View { Text("") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("Logged"))]
    )
  }

  @Test func eachExtraWrapperFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      struct Settings: View {
        @State 1️⃣@Clamped(0...10) 2️⃣@Logged var level = 5
        var body: some View { Text("") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("Clamped")),
        FindingSpec("2️⃣", message: Self.message("Logged")),
      ]
    )
  }

  @Test func previewableNotFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      #Preview {
        @Previewable @State var isOn = false
        Toggle("On", isOn: $isOn)
      }
      """,
      findings: []
    )
  }

  @Test func builtInAttributesNotFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      struct Settings: View {
        @MainActor @State private var a = 0
        @available(iOS 17, *) @State private var b = 0
        @preconcurrency @State private var c = 0
        @objc @State var d = 0
        @nonobjc @State var e = 0
        var body: some View { Text("") }
      }
      """,
      findings: []
    )
  }

  @Test func otherWrappersNotFlagged() {
    assertLint(
      NoStackedStateWrapper.self,
      """
      struct Settings: View {
        @State private var level = 5
        @Clamped(0...10) var other = 5
        @Environment(\\.dismiss) private var dismiss
        var body: some View { Text("") }
      }
      """,
      findings: []
    )
  }
}
