import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ParserDiagnosticsTests {
  @Test func fileWithParserErrorDiagnostics() {
    $parserDiagnosticsDisabledForTests.withValue(false) {
      #expect(!SwiftSource(contents: "importz Foundation").parserDiagnostics.isEmpty)
    }
  }

  @Test func fileWithParserErrorDiagnosticsDoesNotAutocorrect() async throws {
    let contents = """
      print(CGPointZero))
      """
    #expect(
      SwiftSource(contents: contents).parserDiagnostics == [
        "unexpected code \')\' in source file"
      ],
    )

    let ruleDescription = TestExamples(from: LegacyConstantRule.self)
      .with(corrections: [Example(contents): Example(contents)])

    let config = try #require(
      makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true),
    )
    await verifyCorrections(
      ruleDescription, config: config, disableCommands: [],
      shouldTestMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false,
    )
  }

  @Test func fileWithParserWarningDiagnostics() async throws {
    // extraneous duplicate parameter name; 'bar' already has an argument label
    let original = """
      func foo(bar bar: String) ->   Int { 0 }
      """

    let corrected = """
      func foo(bar bar: String) -> Int { 0 }
      """

    $parserDiagnosticsDisabledForTests.withValue(false) {
      #expect(SwiftSource(contents: original).parserDiagnostics == [])
    }

    let ruleDescription = TestExamples(from: ReturnArrowWhitespaceRule.self)
      .with(corrections: [Example(original): Example(corrected)])

    let config = try #require(
      makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true),
    )
    await verifyCorrections(
      ruleDescription, config: config, disableCommands: [],
      shouldTestMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false,
    )
  }

  @Test func fileWithoutParserDiagnostics() {
    $parserDiagnosticsDisabledForTests.withValue(false) {
      #expect(SwiftSource(contents: "import Foundation").parserDiagnostics == [])
    }
  }
}
