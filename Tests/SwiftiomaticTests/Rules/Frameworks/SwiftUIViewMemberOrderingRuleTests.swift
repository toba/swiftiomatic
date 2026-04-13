import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered)
struct SwiftUIViewMemberOrderingRuleTests {
  @Test("Correct ordering via Linter produces no violations")
  func correctOrderViaLinter() async {
    let code = """
      struct MyView: View {
          @Environment(\\.dismiss) private var dismiss
          @FocusState private var isFocused: Bool
          let title: String
          @Binding var isPresented: Bool
          @State private var count = 0
          var formattedCount: String { "\\(count)" }
          init(title: String) { self.title = title }
          var body: some View { Text(title) }
          @ViewBuilder var header: some View { Text("Header") }
          private func increment() { count += 1 }
      }
      """
    let file = SwiftSource(contents: code, isTestFile: true)
    let linter = Linter(
      file: file,
      configuration: Configuration(
        rulesMode: .onlyConfiguration([SwiftUIViewMemberOrderingRule.identifier])
      ),
    )
    let storage = RuleStorage()
    let collected = await linter.collect(into: storage)
    let violations = collected.ruleViolations(using: storage)
    #expect(
      violations.isEmpty,
      "Correct order should not trigger: \(violations.map(\.reason))"
    )
  }

  @Test("Non-View struct is ignored")
  func nonViewIgnored() async {
    let code = """
      struct NotAView {
          func helper() {}
          let name: String
          @State var count = 0
      }
      """
    let file = SwiftSource(contents: code, isTestFile: true)
    let linter = Linter(
      file: file,
      configuration: Configuration(
        rulesMode: .onlyConfiguration([SwiftUIViewMemberOrderingRule.identifier])
      ),
    )
    let storage = RuleStorage()
    let collected = await linter.collect(into: storage)
    let violations = collected.ruleViolations(using: storage)
    #expect(violations.isEmpty, "Non-View struct should be ignored")
  }

  @Test("@State before @Environment triggers via Linter")
  func stateBeforeEnvironmentViaLinter() async {
    let code = """
      struct MyView: View {
          @State private var count = 0
          @Environment(\\.dismiss) private var dismiss
          var body: some View { Text("\\(count)") }
      }
      """
    let file = SwiftSource(contents: code, isTestFile: true)
    let linter = Linter(
      file: file,
      configuration: Configuration(
        rulesMode: .onlyConfiguration([SwiftUIViewMemberOrderingRule.identifier])
      ),
    )
    let storage = RuleStorage()
    let collected = await linter.collect(into: storage)
    let violations = collected.ruleViolations(using: storage)
    #expect(
      violations.count == 1,
      "Expected 1 violation, got \(violations.count): \(violations.map(\.reason))"
    )
  }
}
