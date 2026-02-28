import Testing
@testable import Swiftiomatic

@Suite struct SpaceAroundOperatorsTests {
    @Test func spaceAfterColon() {
        let input = """
        let foo:Bar = 5
        """
        let output = """
        let foo: Bar = 5
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceBetweenOptionalAndDefaultValue() {
        let input = """
        let foo: String?=nil
        """
        let output = """
        let foo: String? = nil
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = """
        let foo: String!=nil
        """
        let output = """
        let foo: String! = nil
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spacePreservedBetweenOptionalTryAndDot() {
        let input = """
        let foo: Int = try? .init()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spacePreservedBetweenForceTryAndDot() {
        let input = """
        let foo: Int = try! .init()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceBetweenOptionalAndDefaultValueInFunction() {
        let input = """
        func foo(bar _: String?=nil) {}
        """
        let output = """
        func foo(bar _: String? = nil) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAddedAfterColonInSelector() {
        let input = """
        @objc(foo:bar:)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceAfterColonInSwitchCase() {
        let input = """
        switch x { case .y:break }
        """
        let output = """
        switch x { case .y: break }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceAfterColonInSwitchDefault() {
        let input = """
        switch x { default:break }
        """
        let output = """
        switch x { default: break }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceAfterComma() {
        let input = """
        let foo = [1,2,3]
        """
        let output = """
        let foo = [1, 2, 3]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceBetweenColonAndEnumValue() {
        let input = """
        [.Foo:.Bar]
        """
        let output = """
        [.Foo: .Bar]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceBetweenCommaAndEnumValue() {
        let input = """
        [.Foo,.Bar]
        """
        let output = """
        [.Foo, .Bar]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noRemoveSpaceAroundEnumInBrackets() {
        let input = """
        [ .red ]
        """
        testFormatting(for: input, rule: .spaceAroundOperators,
                       exclude: [.spaceInsideBrackets])
    }

    @Test func spaceBetweenSemicolonAndEnumValue() {
        let input = """
        statement;.Bar
        """
        let output = """
        statement; .Bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spacePreservedBetweenEqualsAndEnumValue() {
        let input = """
        foo = .Bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceBeforeColon() {
        let input = """
        let foo : Bar = 5
        """
        let output = """
        let foo: Bar = 5
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spacePreservedBeforeColonInTernary() {
        let input = """
        foo ? bar : baz
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spacePreservedAroundEnumValuesInTernary() {
        let input = """
        foo ? .Bar : .Baz
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceBeforeColonInNestedTernary() {
        let input = """
        foo ? (hello + a ? b: c) : baz
        """
        let output = """
        foo ? (hello + a ? b : c) : baz
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceBeforeComma() {
        let input = """
        let foo = [1 , 2 , 3]
        """
        let output = """
        let foo = [1, 2, 3]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
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
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.leadingDelimiters])
    }

    @Test func spaceAroundInfixMinus() {
        let input = """
        foo-bar
        """
        let output = """
        foo - bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundPrefixMinus() {
        let input = """
        foo + -bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundLessThan() {
        let input = """
        foo<bar
        """
        let output = """
        foo < bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func removeSpaceAroundDot() {
        let input = """
        foo . bar
        """
        let output = """
        foo.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundDotOnNewLine() {
        let input = """
        foo
            .bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundEnumCase() {
        let input = """
        case .Foo,.Bar:
        """
        let output = """
        case .Foo, .Bar:
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func switchWithEnumCases() {
        let input = """
        switch x {
        case.Foo:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case .Foo:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundEnumReturn() {
        let input = """
        return.Foo
        """
        let output = """
        return .Foo
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAfterReturnAsIdentifier() {
        let input = """
        foo.return.Bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundCaseLet() {
        let input = """
        case let.Foo(bar):
        """
        let output = """
        case let .Foo(bar):
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundEnumArgument() {
        let input = """
        foo(with:.Bar)
        """
        let output = """
        foo(with: .Bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceBeforeEnumCaseInsideClosure() {
        let input = """
        { .bar() }
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundMultipleOptionalChaining() {
        let input = """
        foo??!?!.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundForcedChaining() {
        let input = """
        foo!.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAddedInOptionalChaining() {
        let input = """
        foo?.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceRemovedInOptionalChaining() {
        let input = """
        foo? .bar
        """
        let output = """
        foo?.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceRemovedInForcedChaining() {
        let input = """
        foo! .bar
        """
        let output = """
        foo!.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceRemovedInMultipleOptionalChaining() {
        let input = """
        foo??! .bar
        """
        let output = """
        foo??!.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAfterOptionalInsideTernary() {
        let input = """
        x ? foo? .bar() : bar?.baz()
        """
        let output = """
        x ? foo?.bar() : bar?.baz()
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func splitLineOptionalChaining() {
        let input = """
        foo?
            .bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func splitLineMultipleOptionalChaining() {
        let input = """
        foo??!
            .bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceBetweenNullCoalescingAndDot() {
        let input = """
        foo ?? .bar()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundFailableInit() {
        let input = """
        init?()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = """
        init!()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundFailableInitWithGenerics() {
        let input = """
        init?<T>()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = """
        init!<T>()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundInitWithGenericAndSuppressedConstraint() {
        let input = """
        init<T: ~Copyable>()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func genericBracketAroundAttributeNotConfusedWithLessThan() {
        let input = """
        Example<(@MainActor () -> Void)?>(nil)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceAfterOptionalAs() {
        let input = """
        foo as?[String]
        """
        let output = """
        foo as? [String]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceAfterForcedAs() {
        let input = """
        foo as![String]
        """
        let output = """
        foo as! [String]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundGenerics() {
        let input = """
        Foo<String>
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noSpaceAroundGenericsWithSuppressedConstraint() {
        let input = """
        Foo<String: ~Copyable>
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundReturnTypeArrow() {
        let input = """
        foo() ->Bool
        """
        let output = """
        foo() -> Bool
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceAroundCommentInInfixExpression() {
        let input = """
        foo/* hello */-bar
        """
        let output = """
        foo/* hello */ -bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.spaceAroundComments])
    }

    @Test func spaceAroundCommentsInInfixExpression() {
        let input = """
        a/* */+/* */b
        """
        let output = """
        a/* */ + /* */b
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.spaceAroundComments])
    }

    @Test func spaceAroundCommentInPrefixExpression() {
        let input = """
        a + /* hello */ -bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func prefixMinusBeforeMember() {
        let input = """
        -.foo
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func postfixMinusBeforeMember() {
        let input = """
        foo-.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func removeSpaceBeforeNegativeIndex() {
        let input = """
        foo[ -bar]
        """
        let output = """
        foo[-bar]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noInsertSpaceBeforeUnlabelledAddressArgument() {
        let input = """
        foo(&bar)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func removeSpaceBeforeUnlabelledAddressArgument() {
        let input = """
        foo( &bar, baz: &baz)
        """
        let output = """
        foo(&bar, baz: &baz)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func removeSpaceBeforeKeyPath() {
        let input = """
        foo( \\.bar)
        """
        let output = """
        foo(\\.bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func addSpaceAfterFuncEquals() {
        let input = """
        func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let output = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators, exclude: [.wrapFunctionBodies])
    }

    @Test func removeSpaceAfterFuncEquals() {
        let input = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let output = """
        func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .remove)
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options, exclude: [.wrapFunctionBodies])
    }

    @Test func preserveSpaceAfterFuncEquals() {
        let input = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        func !=(lhs: Int, rhs: Int) -> Bool { return lhs !== rhs }
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .preserve)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options, exclude: [.wrapFunctionBodies])
    }

    @Test func addSpaceAfterOperatorEquals() {
        let input = """
        operator =={}
        """
        let output = """
        operator == {}
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func noRemoveSpaceAfterOperatorEqualsWhenSpaceAroundOperatorDeclarationsFalse() {
        let input = """
        operator == {}
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    @Test func noAddSpaceAfterOperatorEqualsWithAllmanBrace() {
        let input = """
        operator ==
        {}
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func noAddSpaceAroundOperatorInsideParens() {
        let input = """
        (!=)
        """
        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.redundantParens])
    }

    @Test func spaceAroundPlusBeforeHash() {
        let input = """
        \"foo.\"+#file
        """
        let output = """
        \"foo.\" + #file
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceNotAddedAroundStarInAvailableAnnotation() {
        let input = """
        @available(*, deprecated, message: \"foo\")
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    @Test func addSpaceAroundRange() {
        let input = """
        let a = b...c
        """
        let output = """
        let a = b ... c
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceRemovedInNestedPropertyWrapper() {
        let input = """
        @Encoded .Foo var foo: String
        """
        let output = """
        @Encoded.Foo var foo: String
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func spaceNotAddedInKeyPath() {
        let input = """
        let a = b.map(\\.?.something)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    // noSpaceOperators

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
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    @Test func spaceOnOneSideOfPlusMatchedByLinebreakNotRemoved2() {
        let input = """
        let range = 0
        + 4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    @Test func spaceAroundPlusWithLinebreakOnOneSideNotRemoved() {
        let input = """
        let range = 0 + 
        4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent, .trailingSpace])
    }

    @Test func spaceAroundPlusWithLinebreakOnOneSideNotRemoved2() {
        let input = """
        let range = 0
         + 4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    @Test func addSpaceEvenAfterLHSClosure() {
        let input = """
        let foo = { $0 }..bar
        """
        let output = """
        let foo = { $0 } .. bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func addSpaceEvenBeforeRHSClosure() {
        let input = """
        let foo = bar..{ $0 }
        """
        let output = """
        let foo = bar .. { $0 }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func addSpaceEvenAfterLHSArray() {
        let input = """
        let foo = [42]..bar
        """
        let output = """
        let foo = [42] .. bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func addSpaceEvenBeforeRHSArray() {
        let input = """
        let foo = bar..[42]
        """
        let output = """
        let foo = bar .. [42]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func addSpaceEvenAfterLHSParens() {
        let input = """
        let foo = (42, 1337)..bar
        """
        let output = """
        let foo = (42, 1337) .. bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    @Test func addSpaceEvenBeforeRHSParens() {
        let input = """
        let foo = bar..(42, 1337)
        """
        let output = """
        let foo = bar .. (42, 1337)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
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

    @Test func spaceNotInsertedInParameterPackGenericArgument() {
        let input = """
        func zip<Other, each Another>(
            with _: Optional<Other>,
            _: repeat Optional<each Another>
        ) -> Optional<(Wrapped, Other, repeat each Another)> {}
        """

        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.typeSugar])
    }

    // spaceAroundRangeOperators: .remove

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
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    @Test func spaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = """
        let range = 0/* foo */... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    @Test func spaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = """
        let range = 0 ... /* foo */4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    @Test func spaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = """
        let range = 0/* foo */ ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    @Test func spaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = """
        let range = 0 ...
        4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    @Test func spaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = """
        let range = 0
        ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    @Test func spaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = """
        let range = 0 ... 
        4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent, .trailingSpace])
    }

    @Test func spaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = """
        let range = 0
         ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
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

    // spaceAroundRangeOperators: .preserve

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
            options: options
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
            options: options
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
            options: options
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
            options: options
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
            options: options
        )
    }
}
