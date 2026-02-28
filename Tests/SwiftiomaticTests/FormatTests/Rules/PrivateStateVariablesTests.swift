import Testing

@testable import Swiftiomatic

@Suite struct PrivateStateVariablesTests {
  @Test func privateState() {
    let input = """
      @State var counter: Int
      """
    let output = """
      @State private var counter: Int
      """
    testFormatting(for: input, output, rule: .privateStateVariables)
  }

  @Test func privateStateObject() {
    let input = """
      @StateObject var counter: Int
      """
    let output = """
      @StateObject private var counter: Int
      """
    testFormatting(for: input, output, rule: .privateStateVariables)
  }

  @Test func useExisting() {
    let input = """
      @State private var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }

  @Test func respectingPublicOverride() {
    let input = """
      @StateObject public var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }

  @Test func respectingPackageOverride() {
    let input = """
      @State package var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }

  @Test func respectingOverrideWithSetterModifier() {
    let input = """
      @State private(set) var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }

  @Test func respectingOverrideWithExistingAccessAndSetterModifier() {
    let input = """
      @StateObject public private(set) var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }

  @Test func stateVariableOnPreviousLine() {
    let input = """
      @State
      var counter: Int
      """
    let output = """
      @State
      private var counter: Int
      """
    testFormatting(for: input, output, rule: .privateStateVariables)
  }

  @Test func withPreviewableOnSameLine() {
    // Don't add `private` to @Previewable property wrappers:
    let input = """
      @Previewable @StateObject var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }

  @Test func withPreviewableOnPreviousLine() {
    // Don't add `private` to @Previewable property wrappers:
    let input = """
      @Previewable
      @State var counter: Int
      """
    testFormatting(for: input, rule: .privateStateVariables)
  }
}
