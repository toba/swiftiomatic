import Testing
@testable import Swiftiomatic

extension SpaceAroundOperatorsTests {
    @Test func noRemoveSpaceAroundEnumInBrackets() {
        let input = """
        [ .red ]
        """
        testFormatting(
            for: input, rule: .spaceAroundOperators,
            exclude: [.spaceInsideBrackets],
        )
    }

    @Test func spaceAtStartOfLine() {
        let input = """
        print(foo
              ,bar)
        """
        let output = """
        print(foo
              , bar)
        """
        testFormatting(
            for: input, output, rule: .spaceAroundOperators,
            exclude: [.leadingDelimiters],
        )
    }

    @Test func spaceAroundCommentInInfixExpression() {
        let input = """
        foo/* hello */-bar
        """
        let output = """
        foo/* hello */ -bar
        """
        testFormatting(
            for: input, output, rule: .spaceAroundOperators,
            exclude: [.spaceAroundComments],
        )
    }

    @Test func spaceAroundCommentsInInfixExpression() {
        let input = """
        a/* */+/* */b
        """
        let output = """
        a/* */ + /* */b
        """
        testFormatting(
            for: input, output, rule: .spaceAroundOperators,
            exclude: [.spaceAroundComments],
        )
    }

    @Test func addSpaceAfterFuncEquals() {
        let input = """
        func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let output = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func removeSpaceAfterFuncEquals() {
        let input = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let output = """
        func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .remove)
        testFormatting(
            for: input, output, rule: .spaceAroundOperators, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func preserveSpaceAfterFuncEquals() {
        let input = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        func !=(lhs: Int, rhs: Int) -> Bool { return lhs !== rhs }
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .preserve)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noRemoveSpaceAfterOperatorEqualsWhenSpaceAroundOperatorDeclarationsFalse() {
        let input = """
        operator == {}
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func noAddSpaceAroundOperatorInsideParens() {
        let input = """
        (!=)
        """
        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.redundantParens])
    }

    @Test func spaceNotInsertedInParameterPackGenericArgument() {
        let input = """
        func zip<Other, each Another>(
            with _: Optional<Other>,
            _: repeat Optional<each Another>
        ) -> Optional<(Wrapped, Other, repeat each Another)> {}
        """

        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.typeSugar])
    }

    // MARK: - noSpaceOperators

    @Test func noAddSpaceAroundNoSpaceStar() {
        let input = """
        let a = b*c+d
        """
        let output = """
        let a = b*c + d
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceAroundNoSpaceStar() {
        let input = """
        let a = b * c + d
        """
        let output = """
        let a = b*c + d
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func noRemoveSpaceAroundNoSpaceStarBeforePrefixOperator() {
        let input = """
        let a = b * -c
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func noRemoveSpaceAroundNoSpaceStarAfterPostfixOperator() {
        let input = """
        let a = b% * c
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceAroundNoSpaceStarAfterUnwrapOperator() {
        let input = """
        let a = b! * c
        """
        let output = """
        let a = b!*c
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func noAddSpaceAroundNoSpaceSlash() {
        let input = """
        let a = b/c+d
        """
        let output = """
        let a = b/c + d
        """
        let options = FormatOptions(noSpaceOperators: ["/"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func noAddSpaceAroundNoSpaceRange() {
        let input = """
        let a = b...c
        """
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func noAddSpaceAroundNoSpaceHalfOpenRange() {
        let input = """
        let a = b..<c
        """
        let options = FormatOptions(noSpaceOperators: ["..<"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceAroundNoSpaceRange() {
        let input = """
        let a = b ... c
        """
        let output = """
        let a = b...c
        """
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func noRemoveSpaceAroundNoSpaceRangeBeforePrefixOperator() {
        let input = """
        let a = b ... -c
        """
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func noRemoveSpaceAroundTernaryColon() {
        let input = """
        let a = b ? c : d
        """
        let output = """
        let a = b ? c:d
        """
        let options = FormatOptions(noSpaceOperators: [":"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func noRemoveSpaceAroundTernaryQuestionMark() {
        let input = """
        let a = b ? c : d
        """
        let options = FormatOptions(noSpaceOperators: ["?"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func spaceOnOneSideOfPlusMatchedByLinebreakNotRemoved() {
        let input = """
        let range = 0 +
        4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent],
        )
    }

    @Test func spaceOnOneSideOfPlusMatchedByLinebreakNotRemoved2() {
        let input = """
        let range = 0
        + 4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent],
        )
    }

    @Test func spaceAroundPlusWithLinebreakOnOneSideNotRemoved() {
        let input = """
        let range = 0 +
        4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent, .trailingSpace],
        )
    }

    @Test func spaceAroundPlusWithLinebreakOnOneSideNotRemoved2() {
        let input = """
        let range = 0
         + 4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent],
        )
    }

    @Test func removeSpaceEvenAfterLHSClosure() {
        let input = """
        let foo = { $0 } .. bar
        """
        let output = """
        let foo = { $0 }..bar
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceEvenBeforeRHSClosure() {
        let input = """
        let foo = bar .. { $0 }
        """
        let output = """
        let foo = bar..{ $0 }
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceEvenAfterLHSArray() {
        let input = """
        let foo = [42] .. bar
        """
        let output = """
        let foo = [42]..bar
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceEvenBeforeRHSArray() {
        let input = """
        let foo = bar .. [42]
        """
        let output = """
        let foo = bar..[42]
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceEvenAfterLHSParens() {
        let input = """
        let foo = (42, 1337) .. bar
        """
        let output = """
        let foo = (42, 1337)..bar
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func removeSpaceEvenBeforeRHSParens() {
        let input = """
        let foo = bar .. (42, 1337)
        """
        let output = """
        let foo = bar..(42, 1337)
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    // MARK: - spaceAroundRangeOperators: .remove

    @Test func noSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = """
        foo ..< bar
        """
        let output = """
        foo..<bar
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    @Test func spaceNotRemovedBeforeLeadingRangeOperatorWithSpaceAroundRangeOperatorsFalse() {
        let input = """
        let range = ..<foo.endIndex
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func spaceOnOneSideOfRangeMatchedByCommentNotRemoved() {
        let input = """
        let range = 0 .../* foo */4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.spaceAroundComments],
        )
    }

    @Test func spaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = """
        let range = 0/* foo */... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.spaceAroundComments],
        )
    }

    @Test func spaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = """
        let range = 0 ... /* foo */4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.spaceAroundComments],
        )
    }

    @Test func spaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = """
        let range = 0/* foo */ ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.spaceAroundComments],
        )
    }

    @Test func spaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = """
        let range = 0 ...
        4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent],
        )
    }

    @Test func spaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = """
        let range = 0
        ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent],
        )
    }

    @Test func spaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = """
        let range = 0 ...
        4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent, .trailingSpace],
        )
    }

    @Test func spaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = """
        let range = 0
         ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(
            for: input, rule: .spaceAroundOperators, options: options,
            exclude: [.indent],
        )
    }

    @Test func spaceNotRemovedAroundRangeFollowedByPrefixOperator() {
        let input = """
        let range = 0 ... -4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func spaceNotRemovedAroundRangePreceededByPostfixOperator() {
        let input = """
        let range = 0>> ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    // MARK: - spaceAroundRangeOperators: .preserve

    @Test func preserveSpaceAroundRangeOperators() {
        let input = """
        let a = foo ..< bar
        let b = foo..<bar
        let c = foo ... bar
        let d = foo...bar
        """
        let options = FormatOptions(spaceAroundRangeOperators: .preserve)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    // MARK: - typeDelimiterSpacing

    @Test func spaceAroundDataTypeDelimiterLeadingAdded() {
        let input = """
        class Implementation: ImplementationProtocol {}
        """
        let output = """
        class Implementation : ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options,
        )
    }

    @Test func spaceAroundDataTypeDelimiterLeadingTrailingAdded() {
        let input = """
        class Implementation:ImplementationProtocol {}
        """
        let output = """
        class Implementation : ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options,
        )
    }

    @Test func spaceAroundDataTypeDelimiterLeadingTrailingNotModified() {
        let input = """
        class Implementation : ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            rule: .spaceAroundOperators,
            options: options,
        )
    }

    @Test func spaceAroundDataTypeDelimiterTrailingAdded() {
        let input = """
        class Implementation:ImplementationProtocol {}
        """
        let output = """
        class Implementation: ImplementationProtocol {}
        """

        let options = FormatOptions(typeDelimiterSpacing: .spaceAfter)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options,
        )
    }

    @Test func spaceAroundDataTypeDelimiterLeadingNotAdded() {
        let input = """
        class Implementation: ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaceAfter)
        testFormatting(
            for: input,
            rule: .spaceAroundOperators,
            options: options,
        )
    }
}
