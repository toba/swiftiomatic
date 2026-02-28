import Testing
@testable import Swiftiomatic

@Suite struct ElseOnSameLineTests {
    @Test func elseOnSameLine() {
        let input = """
        if true {
            1
        }
        else { 2 }
        """
        let output = """
        if true {
            1
        } else { 2 }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func elseOnSameLineOnlyAppliedToDanglingBrace() {
        let input = """
        if true { 1 }
        else { 2 }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func guardNotAffectedByElseOnSameLine() {
        let input = """
        guard true
        else { return }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func elseOnSameLineDoesntEatPreviousStatement() {
        let input = """
        if true {}
        guard true else { return }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func elseNotOnSameLineForAllman() {
        let input = """
        if true
        {
            1
        } else { 2 }
        """
        let output = """
        if true
        {
            1
        }
        else { 2 }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    @Test func elseOnNextLineOption() {
        let input = """
        if true {
            1
        } else { 2 }
        """
        let output = """
        if true {
            1
        }
        else { 2 }
        """
        let options = FormatOptions(elsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    @Test func guardNotAffectedByElseOnSameLineForAllman() {
        let input = """
        guard true else { return }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    @Test func repeatWhileNotOnSameLineForAllman() {
        let input = """
        repeat
        {
            foo
        } while x
        """
        let output = """
        repeat
        {
            foo
        }
        while x
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .elseOnSameLine, options: options)
    }

    @Test func whileNotAffectedByElseOnSameLineIfNotRepeatWhile() {
        let input = """
        func foo(x) {}

        while true {}
        """
        testFormatting(for: input, rule: .elseOnSameLine)
    }

    @Test func commentsNotDiscardedByElseOnSameLineRule() {
        let input = """
        if true {
            1
        }

        // comment
        else {}
        """
        testFormatting(for: input, rule: .elseOnSameLine)
    }

    @Test func elseOnSameLineInferenceEdgeCase() {
        let input = """
        func foo() {
            if let foo == bar {
                // ...
            } else {
                // ...
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }
        }
        """
        let options = FormatOptions(elsePosition: .sameLine)
        testFormatting(for: input, rule: .elseOnSameLine, options: options,
                       exclude: [.braces])
    }

    // guardelse = auto

    @Test func singleLineGuardElseNotWrappedByDefault() {
        let input = """
        guard foo = bar else {}
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func singleLineGuardElseNotUnwrappedByDefault() {
        let input = """
        guard foo = bar
        else {}
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func singleLineGuardElseWrappedByDefaultIfBracesOnNextLine() {
        let input = """
        guard foo = bar else
        {}
        """
        let output = """
        guard foo = bar
        else {}
        """
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func multilineGuardElseNotWrappedByDefault() {
        let input = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapMultilineStatementBraces])
    }

    @Test func multilineGuardElseWrappedByDefaultIfBracesOnNextLine() {
        let input = """
        guard let foo = bar,
              bar > 5 else
        {
            return
        }
        """
        let output = """
        guard let foo = bar,
              bar > 5
        else {
            return
        }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine)
    }

    @Test func wrappedMultilineGuardElseCorrectlyIndented() {
        let input = """
        func foo() {
            guard let foo = bar,
                  bar > 5 else
            {
                return
            }
        }
        """
        let output = """
        func foo() {
            guard let foo = bar,
                  bar > 5
            else {
                return
            }
        }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine)
    }

    @Test func multilineGuardElseEndingInParen() {
        let input = """
        guard let foo = bar,
              let baz = quux() else
        {
            return
        }
        """
        let output = """
        guard let foo = bar,
              let baz = quux()
        else {
            return
        }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine)
    }

    // guardelse = nextLine

    @Test func singleLineGuardElseNotWrapped() {
        let input = """
        guard foo = bar else {}
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    @Test func singleLineGuardElseNotUnwrapped() {
        let input = """
        guard foo = bar
        else {}
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    @Test func singleLineGuardElseWrappedIfBracesOnNextLine() {
        let input = """
        guard foo = bar else
        {}
        """
        let output = """
        guard foo = bar
        else {}
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    @Test func multilineGuardElseWrapped() {
        let input = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        let output = """
        guard let foo = bar,
              bar > 5
        else {
            return
        }
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapMultilineStatementBraces])
    }

    // guardelse = sameLine

    @Test func multilineGuardElseUnwrapped() {
        let input = """
        guard let foo = bar,
              bar > 5
        else {
            return
        }
        """
        let output = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        let options = FormatOptions(guardElsePosition: .sameLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapMultilineStatementBraces])
    }

    @Test func guardElseUnwrappedIfBracesOnNextLine() {
        let input = """
        guard foo = bar
        else {}
        """
        let output = """
        guard foo = bar else {}
        """
        let options = FormatOptions(guardElsePosition: .sameLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options)
    }

    @Test func preserveBlankLineBeforeElse() {
        let input = """
        if foo {
            print("foo")
        }

        else if bar {
            print("bar")
        }

        else {
            print("baaz")
        }
        """

        testFormatting(for: input, rule: .elseOnSameLine)
    }

    @Test func preserveBlankLineBeforeElseOnSameLine() {
        let input = """
        if foo {
            print("foo")
        }

        else if bar {
            print("bar")
        }

        else {
            print("baaz")
        }
        """

        let options = FormatOptions(elsePosition: .sameLine)
        testFormatting(for: input, rule: .elseOnSameLine, options: options)
    }

    @Test func preserveBlankLineBeforeElseWithComments() {
        let input = """
        if foo {
            print("foo")
        }
        // Comment before else if
        else if bar {
            print("bar")
        }

        // Comment before else
        else {
            print("baaz")
        }
        """

        testFormatting(for: input, rule: .elseOnSameLine)
    }

    @Test func preserveBlankLineBeforeElseDoesntAffectOtherCases() {
        let input = """
        if foo {
            print("foo")
        }
        else {
            print("bar")
        }

        guard foo else {
            return
        }

        guard
            let foo,
            let bar,
            lat baaz else
        {
            return
        }
        """

        let output = """
        if foo {
            print("foo")
        } else {
            print("bar")
        }

        guard foo else {
            return
        }

        guard
            let foo,
            let bar,
            lat baaz
        else {
            return
        }
        """

        let options = FormatOptions(elsePosition: .sameLine, guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine, options: options, exclude: [.blankLinesAfterGuardStatements])
    }
}
