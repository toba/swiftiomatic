import Testing
@testable import Swiftiomatic

extension IndentTests {
    // indent wrapped lines

    @Test func wrappedLineAfterOperator() {
        let input = """
        if x {
        let y = foo +
        bar
        }
        """
        let output = """
        if x {
            let y = foo +
                bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterComma() {
        let input = """
        let a = b,
        b = c
        """
        let output = """
        let a = b,
            b = c
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.singlePropertyPerLine])
    }

    @Test func wrappedBeforeComma() {
        let input = """
        let a = b
        , b = c
        """
        let output = """
        let a = b
            , b = c
        """
        testFormatting(
            for: input, output, rule: .indent, exclude: [
                .leadingDelimiters,
                .singlePropertyPerLine,
            ],
        )
    }

    @Test func wrappedLineAfterCommaInsideArray() {
        let input = """
        [
        foo,
        bar,
        ]
        """
        let output = """
        [
            foo,
            bar,
        ]
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeCommaInsideArray() {
        let input = """
        [
        foo
        , bar,
        ]
        """
        let output = """
        [
            foo
            , bar,
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.leadingDelimiters],
        )
    }

    @Test func wrappedLineAfterCommaInsideInlineArray() {
        let input = """
        [foo,
        bar]
        """
        let output = """
        [foo,
         bar]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func wrappedLineBeforeCommaInsideInlineArray() {
        let input = """
        [foo
        , bar]
        """
        let output = """
        [foo
         , bar]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.leadingDelimiters],
        )
    }

    @Test func wrappedLineAfterColonInFunction() {
        let input = """
        func foo(bar:
        baz)
        """
        let output = """
        func foo(bar:
            baz)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func noDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = """
        (foo as
        Bar)
        """
        let output = """
        (foo as
            Bar)
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func noDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = """
        (foo
        as Bar)
        """
        let output = """
        (foo
            as Bar)
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func doubleIndentWhenScopesSeparatedByWrap() {
        let input = """
        (foo
        as Bar {
        baz
        })
        """
        let output = """
        (foo
            as Bar {
                baz
            })
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func noDoubleIndentWhenScopesSeparatedByWrap() {
        let input = """
        (foo
        as Bar {
        baz
        }
        )
        """
        let output = """
        (foo
            as Bar {
                baz
            }
        )
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.wrapArguments, .redundantParens],
        )
    }

    @Test func noPermanentReductionInScopeAfterWrap() {
        let input = """
        { foo
        as Bar
        let baz = 5
        }
        """
        let output = """
        { foo
            as Bar
            let baz = 5
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeOperator() {
        let input = """
        if x {
        let y = foo
        + bar
        }
        """
        let output = """
        if x {
            let y = foo
                + bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeIsOperator() {
        let input = """
        if x {
        let y = foo
        is Bar
        }
        """
        let output = """
        if x {
            let y = foo
                is Bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterForKeyword() {
        let input = """
        for
        i in range {}
        """
        let output = """
        for
            i in range {}
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterInKeyword() {
        let input = """
        for i in
        range {}
        """
        let output = """
        for i in
            range {}
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterDot() {
        let input = """
        let foo = bar.
        baz
        """
        let output = """
        let foo = bar.
            baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeDot() {
        let input = """
        let foo = bar
        .baz
        """
        let output = """
        let foo = bar
            .baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeWhere() {
        let input = """
        let foo = bar
        where foo == baz
        """
        let output = """
        let foo = bar
            where foo == baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterWhere() {
        let input = """
        let foo = bar where
        foo == baz
        """
        let output = """
        let foo = bar where
            foo == baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeGuardElse() {
        let input = """
        guard let foo = bar
        else { return }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func wrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = """
        guard let foo = bar else
        { return }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.elseOnSameLine, .wrapConditionalBodies],
        )
    }

    @Test func wrappedLineAfterComment() {
        let input = """
        foo = bar && // comment
        baz
        """
        let output = """
        foo = bar && // comment
            baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineInClosure() {
        let input = """
        forEach { item in
        print(item)
        }
        """
        let output = """
        forEach { item in
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedGuardInClosure() {
        let input = """
        forEach { foo in
            guard let foo = foo,
                  let bar = bar else { break }
        }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapMultilineStatementBraces, .wrapConditionalBodies],
        )
    }

    @Test func consecutiveWraps() {
        let input = """
        let a = b +
        c +
        d
        """
        let output = """
        let a = b +
            c +
            d
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrapReset() {
        let input = """
        let a = b +
        c +
        d
        let a = b +
        c +
        d
        """
        let output = """
        let a = b +
            c +
            d
        let a = b +
            c +
            d
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentElseAfterComment() {
        let input = """
        if x {}
        // comment
        else {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func wrappedLinesWithComments() {
        let input = """
        let foo = bar ||
         // baz||
        quux
        """
        let output = """
        let foo = bar ||
            // baz||
            quux
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func noIndentAfterAssignOperatorToVariable() {
        let input = """
        let greaterThan = >
        let lessThan = <
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentAfterDefaultAsIdentifier() {
        let input = """
        let foo = FileManager.default
        /// Comment
        let bar = 0
        """
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
    }

    @Test func indentClosureStartingOnIndentedLine() {
        let input = """
        foo
        .bar {
        baz()
        }
        """
        let output = """
        foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInVar() {
        let input = """
        var foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        var foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInLet() {
        let input = """
        let foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        let foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInTypedVar() {
        let input = """
        var: Int foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        var: Int foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInTypedLet() {
        let input = """
        let: Int foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        let: Int foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func nestedWrappedIfIndents() {
        let input = """
        if foo {
        if bar &&
        (baz ||
        quux) {
        foo()
        }
        }
        """
        let output = """
        if foo {
            if bar &&
                (baz ||
                    quux) {
                foo()
            }
        }
        """
        testFormatting(
            for: input, output, rule: .indent, exclude: [
                .andOperator,
                .wrapMultilineStatementBraces,
            ],
        )
    }

    @Test func wrappedEnumThatLooksLikeIf() {
        let input = """
        foo &&
         bar.if {
        foo()
        }
        """
        let output = """
        foo &&
            bar.if {
                foo()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedClosureIndents() {
        let input = """
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedClosureIndentsAfterIfCondition() {
        let input = """
        if foo {
        bar()
        .baz()
        }

        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        if foo {
            bar()
                .baz()
        }

        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedClosureIndentsAfterIfCondition2() {
        let input = """
        if foo {
        bar()
        .baz()
        }

        foo
        .bar {
        baz()
        }.bar {
        baz()
        }
        """
        let output = """
        if foo {
            bar()
                .baz()
        }

        foo
            .bar {
                baz()
            }.bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineFunctionChains])
    }

}
