import Testing
@testable import Swiftiomatic

@Suite struct BlankLinesAroundMarkTests {
    @Test func insertBlankLinesAroundMark() {
        let input = """
        let foo = "foo"
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMark)
    }

    @Test func noInsertExtraBlankLinesAroundMark() {
        let input = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, rule: .blankLinesAroundMark)
    }

    @Test func insertBlankLineAfterMarkAtStartOfFile() {
        let input = """
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMark)
    }

    @Test func insertBlankLineBeforeMarkAtEndOfFile() {
        let input = """
        let foo = "foo"
        // MARK: bar
        """
        let output = """
        let foo = "foo"

        // MARK: bar
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMark)
    }

    @Test func noInsertBlankLineBeforeMarkAtStartOfScope() {
        let input = """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMark)
    }

    @Test func noInsertBlankLineBeforeMarkAtStartOfScopeWithTrailingComment() {
        let input = """
        struct Foo { // some comment here
            // MARK: bar

            let string: String
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMark)
    }

    @Test func noInsertBlankLineAfterMarkAtEndOfScope() {
        let input = """
        do {
            let foo = "foo"

            // MARK: foo
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMark)
    }

    @Test func insertBlankLinesJustBeforeMarkNotAfter() {
        let input = """
        let foo = "foo"
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        let foo = "foo"

        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, output, rule: .blankLinesAroundMark, options: options)
    }

    @Test func noInsertExtraBlankLinesAroundMarkWithNoBlankLineAfterMark() {
        let input = """
        let foo = "foo"

        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, rule: .blankLinesAroundMark, options: options)
    }

    @Test func noInsertBlankLineAfterMarkAtStartOfFile() {
        let input = """
        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, rule: .blankLinesAroundMark, options: options)
    }
}
