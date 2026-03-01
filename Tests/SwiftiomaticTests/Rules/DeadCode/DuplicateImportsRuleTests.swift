import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct DuplicateImportsRuleTests {
  @Test func disableCommand() {
    let content = """
      import InspireAPI
      // sm:disable:next duplicate_imports
      import class InspireAPI.Response
      """
    let file = SwiftSource(contents: content)

    _ = DuplicateImportsRule().correct(file: file)

    #expect(file.contents == content)
  }
}
