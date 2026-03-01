import Testing
@testable import Swiftiomatic

@Suite struct ConsecutiveBlankLinesTests {
    @Test func consecutiveBlankLines() {
        let input = "foo\n\n\nbar"
        let output = "foo\n\nbar"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n\n"
        let output = "foo\n"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesInsideStringLiteral() {
        let input = "\"\"\"\nhello\n\n\nworld\n\"\"\""
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAtStartOfStringLiteral() {
        let input = "\"\"\"\n\n\nhello world\n\"\"\""
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAfterStringLiteral() {
        let input = "\"\"\"\nhello world\n\"\"\"\n\n\nfoo()"
        let output = "\"\"\"\nhello world\n\"\"\"\n\nfoo()"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func fragmentWithTrailingLinebreaks() {
        let input = "func foo() {}\n\n\n"
        let output = "func foo() {}\n\n"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .consecutiveBlankLines, options: options)
    }

    @Test func consecutiveBlankLinesNoInterpolation() {
        let input = "\"\"\"\nAAA\nZZZ\n\n\"\"\""
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAfterInterpolation() {
        let input = "\"\"\"\nAAA\n\\(interpolated)\n\n\"\"\""
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func lintingConsecutiveBlankLinesReportsCorrectLine() throws {
        let input = "foo\n\n\nbar"
        #expect(
            try lint(input, rules: [.consecutiveBlankLines]) == [
                .init(line: 3, rule: .consecutiveBlankLines, filePath: nil, isMove: false),
            ],
        )
    }
}
