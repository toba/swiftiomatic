import Testing
@testable import Swiftiomatic

@Suite struct ConsecutiveBlankLinesTests {
    @Test func consecutiveBlankLines() {
        let input = """
        foo

        bar
        """
        let output = """
        foo

        bar
        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAtEndOfFile() {
        let input = """
        foo

        """
        let output = """
        foo

        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAtStartOfFile() {
        let input = """

        foo
        """
        let output = """

        foo
        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesInsideStringLiteral() {
        let input = """
        \"\"\"
        hello

        world
        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAtStartOfStringLiteral() {
        let input = """
        \"\"\"

        hello world
        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAfterStringLiteral() {
        let input = """
        \"\"\"
        hello world
        \"\"\"

        foo()
        """
        let output = """
        \"\"\"
        hello world
        \"\"\"

        foo()
        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    @Test func fragmentWithTrailingLinebreaks() {
        let input = """
        func foo() {}

        """
        let output = """
        func foo() {}

        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .consecutiveBlankLines, options: options)
    }

    @Test func consecutiveBlankLinesNoInterpolation() {
        let input = """
        \"\"\"
        AAA
        ZZZ

        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func consecutiveBlankLinesAfterInterpolation() {
        let input = """
        \"\"\"
        AAA
        \\(interpolated)

        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    @Test func lintingConsecutiveBlankLinesReportsCorrectLine() {
        let input = """
        foo

        bar
        """
        #expect(try lint(input, rules: [.consecutiveBlankLines]) == [
            .init(line: 3, rule: .consecutiveBlankLines, filePath: nil, isMove: false),
        ])
    }
}
