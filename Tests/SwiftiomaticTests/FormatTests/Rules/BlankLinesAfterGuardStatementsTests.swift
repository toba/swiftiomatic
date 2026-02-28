import Testing
@testable import Swiftiomatic

@Suite struct BlankLinesAfterGuardStatementsTests {
    @Test func spacesBetweenMultiLineGuards() {
        let input = """
        guard let one = test.one else {
            return
        }
        guard let two = test.two else {
            return
        }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else {
            return
        }

        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            return
        }
        guard let two = test.two else {
            return
        }
        guard let three = test.three else {
            return
        }
        guard let four = test.four else {
            return
        }
        guard let five = test.five else {
            return
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements, exclude: [.blankLinesBetweenScopes])
    }

    @Test func spacesBetweenSingleLineGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else { return }

        guard let four = test.four else { return }

        guard let five = test.five else { return }
        """
        let output = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }
        guard let three = test.three else { return }
        guard let four = test.four else { return }
        guard let five = test.five else { return }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    @Test func spacesBetweenSingleLineAndMultiLineGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else { return }

        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }
        guard let three = test.three else {
            return
        }
        guard let four = test.four else { return }
        guard let five = test.five else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    @Test func spacesBetweenMultiLineGuardsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            return
        }
        guard let two = test.two else {
            return
        }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else {
            return
        }

        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            return
        }

        guard let two = test.two else {
            return
        }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else {
            return
        }

        guard let five = test.five else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes]
        )
    }

    @Test func spacesBetweenSingleLineGuardsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else { return }

        guard let four = test.four else { return }

        guard let five = test.five else { return }
        """
        let output = """
        guard let one = test.one else { return }

        guard let two = test.two else { return }

        guard let three = test.three else { return }

        guard let four = test.four else { return }

        guard let five = test.five else { return }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    @Test func spacesBetweenSingleLineAndMultiLineGuardsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else { return }

        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else { return }

        guard let two = test.two else { return }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else { return }

        guard let five = test.five else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    @Test func linebreakAfterMultiLineGuard() {
        let input = """
        guard let one = test.one else {
            return
        }
        let x = test()
        """
        let output = """
        guard let one = test.one else {
            return
        }

        let x = test()
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements)
    }

    @Test func linebreakAfterSingleLineGuard() {
        let input = """
        guard let one = test.one else { return }
        let x = test()
        """
        let output = """
        guard let one = test.one else { return }

        let x = test()
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.wrapConditionalBodies]
        )
    }

    @Test func linebreakAfterMultiLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            return
        }
        let x = test()
        """
        let output = """
        guard let one = test.one else {
            return
        }

        let x = test()
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true)
        )
    }

    @Test func linebreakAfterSingleLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else { return }
        let x = test()
        """
        let output = """
        guard let one = test.one else { return }

        let x = test()
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }

    @Test func includedMultiLineGuard() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }

            return
        }
        guard let three = test.three() else {
            return
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements, exclude: [.blankLinesBetweenScopes])
    }

    @Test func includedSingleLineGuard() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else { return }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else { return }

            return
        }
        guard let three = test.three() else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    @Test func includedMultiLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }

            return
        }

        guard let three = test.three() else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes]
        )
    }

    @Test func includedSingleLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else { return }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else { return }

            return
        }

        guard let three = test.three() else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    @Test func endBracketAndIf() {
        let input = """
        guard let something = test.something else {
            return
        }
        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """
        let output = """
        guard let something = test.something else {
            return
        }

        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements)
    }

    @Test func singleLineGuardAndIf() {
        let input = """
        guard let something = test.something else { return }
        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """
        let output = """
        guard let something = test.something else { return }

        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.wrapConditionalBodies]
        )
    }

    @Test func endBracketAndIfWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let something = test.something else {
            return
        }
        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """
        let output = """
        guard let something = test.something else {
            return
        }

        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true)
        )
    }

    @Test func singleLineGuardAndIfWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let something = test.something else { return }
        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """
        let output = """
        guard let something = test.something else { return }

        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }

    @Test func multiLineGuardAndComments() {
        let input = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }
        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }

        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }

        // commentTwo
        let something = xxx
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements, exclude: [.docComments])
    }

    @Test func singleLineGuardAndComments() {
        let input = """
        guard let somethingTwo = test.somethingTwo else { return }
        // commentOne
        guard let somethingOne = test.somethingOne else { return }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else { return }

        // commentOne
        guard let somethingOne = test.somethingOne else { return }

        // commentTwo
        let something = xxx
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.docComments, .wrapConditionalBodies]
        )
    }

    @Test func multiLineGuardAndCommentsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }
        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }

        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }

        // commentTwo
        let something = xxx
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.docComments]
        )
    }

    @Test func singleLineGuardAndCommentsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let somethingTwo = test.somethingTwo else { return }
        // commentOne
        guard let somethingOne = test.somethingOne else { return }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else { return }

        // commentOne
        guard let somethingOne = test.somethingOne else { return }

        // commentTwo
        let something = xxx
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.docComments, .wrapConditionalBodies]
        )
    }

    @Test func notInsertLineBreakWhenInlineFunction() {
        let input = """
        let array = [1, 2, 3]
        guard array.map { String($0) }.isEmpty else {
            return
        }
        """
        testFormatting(for: input, rule: .blankLinesAfterGuardStatements, exclude: [.wrapConditionalBodies])
    }

    @Test func notInsertLineBreakWhenInlineFunctionAndBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        let array = [1, 2, 3]
        guard array.map { String($0) }.isEmpty else {
            return
        }
        """
        testFormatting(
            for: input,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }

    @Test func notInsertLineBreakInChain() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
              .filter { $0 == 4 }
              .isEmpty,
              yetAnotherBool
        else { return }
        """

        testFormatting(for: input, rule: .blankLinesAfterGuardStatements, exclude: [.wrapConditionalBodies])
    }

    @Test func notInsertLineBreakInChainWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
              .filter { $0 == 4 }
              .isEmpty,
              yetAnotherBool
        else { return }
        """

        testFormatting(
            for: input,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }
}
