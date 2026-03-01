import Testing
@testable import Swiftiomatic

@Suite struct WrapArgumentsTests {
    @Test func indentFirstElementWhenApplyingWrap() {
        let input = """
        let foo = Set([
        Thing(),
        Thing(),
        ])
        """
        let output = """
        let foo = Set([
            Thing(),
            Thing(),
        ])
        """
        testFormatting(for: input, output, rule: .wrapArguments, exclude: [.propertyTypes])
    }

    @Test func wrapArgumentsDoesNotIndentTrailingComment() {
        let input = """
        foo( // foo
        bar: Int,
        baaz: Int
        )
        """
        let output = """
        foo( // foo
            bar: Int,
            baaz: Int
        )
        """
        testFormatting(for: input, output, rule: .wrapArguments)
    }

    @Test func wrapArgumentsDoesNotIndentClosingBracket() {
        let input = """
        [
            "foo": [
            ],
        ]
        """
        testFormatting(for: input, rule: .wrapArguments)
    }

    @Test func wrapParametersDoesNotAffectFunctionDeclaration() {
        let input = """
        foo(
            bar _: Int,
            baz _: String
        )
        """
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersClosureAfterParameterListDoesNotWrapClosureArguments() {
        let input = """
        func foo() {}
        bar = (baz: 5, quux: 7,
               quuz: 10)
        """
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .beforeFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersNotSetWrapArgumentsAfterFirstDefaultsToAfterFirst() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let output = """
        func foo(bar _: Int,
                 baz _: String) {}
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersNotSetWrapArgumentsBeforeFirstDefaultsToBeforeFirst() {
        let input = """
        func foo(bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersNotSetWrapArgumentsPreserveDefaultsToPreserve() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionDeclarationClosingParenOnSameLine() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionDeclarationClosingParenOnNextLine() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .balanced)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionDeclarationClosingParenOnSameLineAndForce() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst, closingParenPosition: .sameLine,
            callSiteClosingParenPosition: .sameLine,
        )
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionDeclarationClosingParenOnNextLineAndForce() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst, closingParenPosition: .balanced,
            callSiteClosingParenPosition: .sameLine,
        )
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionDeclarationClosingParenOnNextLineSingleArgument() {
        let input = """
        func foo(
            bar _: Int) {}
        """
        let output = """
        func foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst, closingParenPosition: .balanced, maxWidth: 100,
        )
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionCallClosingParenOnNextLineAndForce() {
        let input = """
        foo(
            bar: 42,
            baz: "foo"
        )
        """
        let output = """
        foo(
            bar: 42,
            baz: "foo")
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst, closingParenPosition: .balanced,
            callSiteClosingParenPosition: .sameLine,
        )
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionCallClosingParenBalancedAndForce() {
        let input = """
        foo(
            bar: 42,
            baz: "foo")
        """
        let output = """
        foo(
            bar: 42,
            baz: "foo"
        )
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst, closingParenPosition: .sameLine,
            callSiteClosingParenPosition: .balanced,
        )
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersFunctionCallClosingParenBalancedSingleArgument() {
        let input = """
        foo(
            bar: 42)
        """
        let output = """
        foo(
            bar: 42
        )
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst, closingParenPosition: .sameLine,
            callSiteClosingParenPosition: .balanced, maxWidth: 100,
        )
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func indentMultilineStringWhenWrappingArguments() {
        let input = """
        foobar(foo: \"\""
                   baz
               \"\"",
               bar: \"\""
                   baz
               \"\"")
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    @Test func handleXcodeTokenApplyingWrap() {
        let input = """
        test(image: \u{003c}#T##UIImage#>, name: "Name")
        """

        let output = """
        test(
            image: \u{003c}#T##UIImage#>,
            name: "Name"
        )
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func issue1530() {
        let input = """
        extension DRAutoWeatherReadRequestResponse {
            static let mock = DRAutoWeatherReadRequestResponse(
                offlineFirstWeather: DRAutoWeatherReadRequestResponse.DROfflineFirstWeather(
                    daily: .mockWeatherID, hourly: []
                )
            )
        }
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(
            for: input,
            rule: .wrapArguments,
            options: options,
            exclude: [.propertyTypes],
        )
    }

    // MARK: wrapParameters

    // MARK: preserve

    @Test func afterFirstPreserved() {
        let input = """
        func foo(bar _: Int,
                 baz _: String) {}
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    @Test func afterFirstPreservedIndentFixed() {
        let input = """
        func foo(bar _: Int,
         baz _: String) {}
        """
        let output = """
        func foo(bar _: Int,
                 baz _: String) {}
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func afterFirstPreservedNewlineRemoved() {
        let input = """
        func foo(bar _: Int,
                 baz _: String
        ) {}
        """
        let output = """
        func foo(bar _: Int,
                 baz _: String) {}
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func beforeFirstPreserved() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    @Test func beforeFirstPreservedIndentFixed() {
        let input = """
        func foo(
            bar _: Int,
         baz _: String
        ) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func beforeFirstPreservedNewlineAdded() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func wrapParametersAfterMultilineComment() {
        let input = """
        /**
         Some function comment.
         */
        func barFunc(
            _ firstParam: FirstParamType,
            secondParam: SecondParamType
        )
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    // MARK: afterFirst

    @Test func beforeFirstConvertedToAfterFirst() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let output = """
        func foo(bar _: Int,
                 baz _: String) {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    @Test func noWrapInnerArguments() {
        let input = """
        func foo(
            bar _: Int,
            baz _: foo(bar, baz)
        ) {}
        """
        let output = """
        func foo(bar _: Int,
                 baz _: foo(bar, baz)) {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    // MARK: afterFirst, maxWidth

    @Test func wrapAfterFirstIfMaxLengthExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo(bar: Int,
                 baz: String) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
        testFormatting(
            for: input, output, rule: .wrapArguments, options: options,
            exclude: [.unusedArguments, .wrap],
        )
    }

    @Test func wrapAfterFirstIfMaxLengthExceeded2() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int,
                 baz: String,
                 quux: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
        testFormatting(
            for: input, output, rule: .wrapArguments, options: options,
            exclude: [.unusedArguments, .wrap],
        )
    }

    @Test func wrapAfterFirstIfMaxLengthExceeded3() {
        let input = """
        func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
        testFormatting(
            for: input, output, rule: .wrapArguments, options: options,
            exclude: [.unusedArguments, .wrap],
        )
    }

    @Test func wrapAfterFirstIfMaxLengthExceeded3WithWrap() {
        let input = """
        func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
                 -> Bool {}
        """
        let output2 = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
            -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
        testFormatting(
            for: input, [output, output2],
            rules: [.wrapArguments, .wrap],
            options: options, exclude: [.unusedArguments],
        )
    }

    @Test func wrapAfterFirstIfMaxLengthExceeded4WithWrap() {
        let input = """
        func foo(bar: String, baz: String, quux: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: String,
                 baz: String,
                 quux: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
        testFormatting(
            for: input, [output],
            rules: [.wrapArguments, .wrap],
            options: options, exclude: [.unusedArguments],
        )
    }

    @Test func wrapAfterFirstIfMaxLengthExceededInClassScopeWithWrap() {
        let input = """
        class TestClass {
            func foo(bar: String, baz: String, quux: Bool) -> Bool {}
        }
        """
        let output = """
        class TestClass {
            func foo(bar: String,
                     baz: String,
                     quux: Bool)
                     -> Bool {}
        }
        """
        let output2 = """
        class TestClass {
            func foo(bar: String,
                     baz: String,
                     quux: Bool)
                -> Bool {}
        }
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
        testFormatting(
            for: input, [output, output2],
            rules: [.wrapArguments, .wrap],
            options: options, exclude: [.unusedArguments],
        )
    }

    @Test func wrapParametersListInClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (Int,
                           Int,
                           String) -> Int = { _, _, _ in
            0
        }
        """
        let output2 = """
        var mathFunction: (Int,
                           Int,
                           String)
            -> Int = { _, _, _ in
                0
            }
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 30)
        testFormatting(
            for: input, [output, output2],
            rules: [.wrapArguments],
            options: options,
        )
    }

    @Test func wrapParametersAfterFirstIfMaxLengthExceededInReturnType() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
        """
        let output2 = """
        func foo(bar: Int, baz: String,
                 quux: Bool) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 50)
        testFormatting(
            for: input, [input, output2], rules: [.wrapArguments],
            options: options, exclude: [.unusedArguments],
        )
    }

    @Test func wrapParametersAfterFirstWithSeparatedArgumentLabels() {
        let input = """
        func foo(with
            bar: Int, and
            baz: String, and
            quux: Bool
        ) -> LongReturnType {}
        """
        let output = """
        func foo(with bar: Int,
                 and baz: String,
                 and quux: Bool) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: options, exclude: [.unusedArguments],
        )
    }

    // MARK: beforeFirst
}
