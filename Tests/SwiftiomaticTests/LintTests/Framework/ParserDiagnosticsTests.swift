import Testing
@testable import Swiftiomatic

@Suite struct ParserDiagnosticsTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func fileWithParserErrorDiagnostics() {
        $parserDiagnosticsDisabledForTests.withValue(false) {
            #expect(SwiftLintFile(contents: "importz Foundation").parserDiagnostics != nil)
        }
    }

    @Test func fileWithParserErrorDiagnosticsDoesntAutocorrect() throws {
        let contents = """
        print(CGPointZero))
        """
        #expect(SwiftLintFile(contents: contents).parserDiagnostics == ["unexpected code \')\' in source file"])

        let ruleDescription = LegacyConstantRule.description
            .with(corrections: [Example(contents): Example(contents)])

        let config = try #require(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        verifyCorrections(ruleDescription, config: config, disableCommands: [],
                          testMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false)
    }

    @Test func fileWithParserWarningDiagnostics() throws {
        // extraneous duplicate parameter name; 'bar' already has an argument label
        let original = """
        func foo(bar bar: String) ->   Int { 0 }
        """

        let corrected = """
        func foo(bar bar: String) -> Int { 0 }
        """

        $parserDiagnosticsDisabledForTests.withValue(false) {
            #expect(SwiftLintFile(contents: original).parserDiagnostics == [])
        }

        let ruleDescription = ReturnArrowWhitespaceRule.description
            .with(corrections: [Example(original): Example(corrected)])

        let config = try #require(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        verifyCorrections(ruleDescription, config: config, disableCommands: [],
                          testMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false)
    }

    @Test func fileWithoutParserDiagnostics() {
        $parserDiagnosticsDisabledForTests.withValue(false) {
            #expect(SwiftLintFile(contents: "import Foundation").parserDiagnostics == [])
        }
    }
}
