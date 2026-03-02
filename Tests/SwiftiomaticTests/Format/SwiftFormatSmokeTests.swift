import Testing
import Foundation
import SwiftFormat

@Suite("swift-format integration smoke tests")
struct SwiftFormatSmokeTests {
    @Test("SwiftFormatter formats simple Swift source")
    func formatterProducesOutput() throws {
        let config = SwiftFormat.Configuration()
        let formatter = SwiftFormatter(configuration: config)

        let input = "func   foo(  ) {  }"
        var output = ""
        try formatter.format(source: input, assumingFileURL: nil, selection: .infinite, to: &output)

        #expect(!output.isEmpty, "Formatted output should not be empty")
        #expect(output != input, "Formatter should have modified the input")
    }

    @Test("SwiftLinter reports findings on unformatted source")
    func linterReportsFindings() throws {
        let config = SwiftFormat.Configuration()
        var findings: [Finding] = []
        let linter = SwiftLinter(configuration: config) { finding in
            findings.append(finding)
        }

        let source = "func   foo(  ){\nlet x=1\n}\n"
        let url = URL(filePath: "/tmp/test.swift")
        try linter.lint(source: source, assumingFileURL: url)

        #expect(!findings.isEmpty, "Linter should report findings on unformatted source")
    }

    @Test("Configuration supports custom line length")
    func configurationCustomLineLength() throws {
        var config = SwiftFormat.Configuration()
        config.lineLength = 80

        let formatter = SwiftFormatter(configuration: config)
        let input = "let x = 1\n"
        var output = ""
        try formatter.format(source: input, assumingFileURL: nil, selection: .infinite, to: &output)

        #expect(!output.isEmpty)
    }
}
