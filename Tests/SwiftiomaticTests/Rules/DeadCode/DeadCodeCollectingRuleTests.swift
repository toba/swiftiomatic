import Testing

@testable import SwiftiomaticKit

/// Create test files persisted to disk (so they have paths) but without compiler arguments.
/// Collecting rules need file paths but don't need compiler arguments.
private func testFiles(_ sources: [String]) -> [SwiftSource] {
  sources.map { SwiftSource.testFile(withContents: $0, persistToDisk: true) }
}

// MARK: - DeadSymbolsRule

@Suite(.rulesRegistered) struct DeadSymbolsRuleTests {
  private static let config = Configuration(
    rulesMode: .onlyConfiguration([DeadSymbolsRule.identifier]),
    ruleList: RuleList(rules: DeadSymbolsRule.self)
  )

  // MARK: - Non-triggering

  @Test func referencedPrivateFunctionDoesNotTrigger() async {
    let violations = await testFiles([
      "private func helper() { }",
      "func main() { helper() }",
    ]).violations(config: Self.config)

    #expect(violations.isEmpty)
  }

  @Test func nonPrivateFunctionDoesNotTrigger() async {
    let violations = await testFiles([
      "func publicHelper() { }",
      "func main() { }",
    ]).violations(config: Self.config)

    #expect(violations.isEmpty)
  }

  @Test func referencedPrivateVarDoesNotTrigger() async {
    let violations = await testFiles([
      "private var count = 0",
      "func main() { print(count) }",
    ]).violations(config: Self.config)

    #expect(violations.isEmpty)
  }

  // MARK: - Triggering

  @Test func unreferencedPrivateFunctionTriggers() async {
    let violations = await testFiles([
      "private func unused() { }\nfunc main() { }"
    ]).violations(config: Self.config)

    #expect(!violations.isEmpty)
    #expect(violations.first?.reason.text.contains("unused") == true)
  }

  @Test func unreferencedPrivateVarTriggers() async {
    let violations = await testFiles([
      "private var dead = 0\nfunc main() { }"
    ]).violations(config: Self.config)

    #expect(!violations.isEmpty)
    #expect(violations.first?.reason.text.contains("dead") == true)
  }

  @Test func unreferencedPrivateClassTriggers() async {
    let violations = await testFiles([
      "private class Orphan { }\nfunc main() { }"
    ]).violations(config: Self.config)

    #expect(!violations.isEmpty)
    #expect(violations.first?.reason.text.contains("Orphan") == true)
  }

  @Test func unreferencedFileprivateFunctionTriggers() async {
    let violations = await testFiles([
      "fileprivate func forgotten() { }\nfunc main() { }"
    ]).violations(config: Self.config)

    #expect(!violations.isEmpty)
    #expect(violations.first?.reason.text.contains("forgotten") == true)
  }

  // MARK: - Cross-file reference

  @Test func crossFileReferenceDoesNotTrigger() async {
    let violations = await testFiles([
      "private func shared() { }",
      "func caller() { shared() }",
    ]).violations(config: Self.config)

    #expect(violations.isEmpty)
  }
}

// MARK: - StructuralDuplicationRule

@Suite(.rulesRegistered) struct StructuralDuplicationRuleTests {
  private static let config = Configuration(
    rulesMode: .onlyConfiguration([StructuralDuplicationRule.identifier]),
    ruleList: RuleList(rules: StructuralDuplicationRule.self)
  )

  // MARK: - Non-triggering

  @Test func distinctFunctionsDoNotTrigger() async {
    let violations = await testFiles([
      """
      func greet() {
          let name = "World"
          print("Hello, \\(name)")
          print("Goodbye")
          return
      }
      func compute() {
          let x = 42
          let y = x * 2
          return
      }
      """
    ]).violations(config: Self.config)

    #expect(violations.isEmpty)
  }

  @Test func tinyFunctionsDoNotTrigger() async {
    // Functions with fewer than 5 structural nodes are ignored
    let violations = await testFiles([
      "func a() { 1 }\nfunc b() { 2 }"
    ]).violations(config: Self.config)

    #expect(violations.isEmpty)
  }

  // MARK: - Triggering

  @Test func identicalFunctionsTrigger() async {
    let violations = await testFiles([
      """
      func process1() {
          let items = [1, 2, 3]
          for item in items {
              print(item)
              print("done")
          }
      }
      func process2() {
          let items = [4, 5, 6]
          for item in items {
              print(item)
              print("done")
          }
      }
      """
    ]).violations(config: Self.config)

    #expect(violations.count == 2)
  }

  @Test func crossFileDuplicationTriggers() async {
    let body = """
      let items = [1, 2, 3]
      for item in items {
          print(item)
          print("done")
      }
      """
    let violations = await testFiles([
      "func fileA() {\n\(body)\n}",
      "func fileB() {\n\(body)\n}",
    ]).violations(config: Self.config)

    #expect(violations.count == 2)
  }
}
