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
        @State 1️⃣var counter: Int
        """,
      expected: """
        @State private var counter: Int
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
        @StateObject 1️⃣var counter: Int
        """,
      expected: """
        @StateObject private var counter: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'private' to this @State property"),
      ]
    )
  }

  @Test func stateVariableOnPreviousLine() {
    assertFormatting(
      MakeStateVarsPrivate.self,
      input: """
        @State
        1️⃣var counter: Int
        """,
      expected: """
        @State
        private var counter: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "add 'private' to this @State property"),
      ]
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
