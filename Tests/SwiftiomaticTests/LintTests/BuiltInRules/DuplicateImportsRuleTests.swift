import Testing

@testable import Swiftiomatic

@Suite struct DuplicateImportsRuleTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  @Test func disableCommand() {
    let content = """
      import InspireAPI
      // swiftlint:disable:next duplicate_imports
      import class InspireAPI.Response
      """
    let file = SwiftLintFile(contents: content)

    _ = DuplicateImportsRule().correct(file: file)

    #expect(file.contents == content)
  }
}
