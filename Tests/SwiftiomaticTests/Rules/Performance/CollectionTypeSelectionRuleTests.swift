import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered)
struct CollectionTypeSelectionRuleTests {
  @Test("Deque.removeFirst via Linter path does not trigger")
  func dequeRemoveFirstViaLinter() async {
    let code = """
      var queue = Deque<Int>()
      queue.append(1)
      queue.removeFirst()
      """
    let file = SwiftSource(contents: code, isTestFile: true)
    let linter = Linter(
      file: file,
      configuration: Configuration(
        rulesMode: .onlyConfiguration([CollectionTypeSelectionRule.identifier])
      ),
    )
    let storage = RuleStorage()
    let collected = await linter.collect(into: storage)
    let violations = collected.ruleViolations(using: storage)
    #expect(
      violations.isEmpty,
      "Deque receiver should not trigger: \(violations.map(\.reason))"
    )
  }
}
