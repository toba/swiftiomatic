import Testing
@testable import Swiftiomatic

@Suite struct BlankLinesBetweenChainedFunctionsTests {
    @Test func blankLinesBetweenChainedFunctions() {
        let input = """
        [0, 1, 2]
        .map { $0 * 2 }

        .map { $0 * 3 }
        """
        let output1 = """
        [0, 1, 2]
        .map { $0 * 2 }
        .map { $0 * 3 }
        """
        let output2 = """
        [0, 1, 2]
            .map { $0 * 2 }
            .map { $0 * 3 }
        """
        testFormatting(for: input, [output1, output2], rules: [.blankLinesBetweenChainedFunctions])
    }

    @Test func blankLinesWithCommentsBetweenChainedFunctions() {
        let input = """
        [0, 1, 2]
            .map { $0 * 2 }

            // Multiplies by 3

            .map { $0 * 3 }
        """
        let output = """
        [0, 1, 2]
            .map { $0 * 2 }
            // Multiplies by 3
            .map { $0 * 3 }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenChainedFunctions)
    }

    @Test func blankLinesWithMarkCommentBetweenChainedFunctions() {
        let input = """
        [0, 1, 2]
            .map { $0 * 2 }

            // MARK: hello

            .map { $0 * 3 }
        """
        testFormatting(
            for: input,
            rules: [.blankLinesBetweenChainedFunctions, .blankLinesAroundMark],
        )
    }
}
