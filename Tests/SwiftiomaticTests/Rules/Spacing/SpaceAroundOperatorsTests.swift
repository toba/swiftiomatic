import Testing

@testable import Swiftiomatic

@Suite struct SpaceAroundOperatorsTests {

  // MARK: - Parameterized cases

  static let cases: [FormatCase] = [
    // Colons
    FormatCase(
      "spaceAfterColon",
      input: """
        let foo:Bar = 5
        """,
      output: """
        let foo: Bar = 5
        """
    ),
    FormatCase(
      "spaceBetweenOptionalAndDefaultValue",
      input: """
        let foo: String?=nil
        """,
      output: """
        let foo: String? = nil
        """
    ),
    FormatCase(
      "spaceBetweenImplictlyUnwrappedOptionalAndDefaultValue",
      input: """
        let foo: String!=nil
        """,
      output: """
        let foo: String! = nil
        """
    ),
    FormatCase(
      "spacePreservedBetweenOptionalTryAndDot",
      input: """
        let foo: Int = try? .init()
        """
    ),
    FormatCase(
      "spacePreservedBetweenForceTryAndDot",
      input: """
        let foo: Int = try! .init()
        """
    ),
    FormatCase(
      "spaceBetweenOptionalAndDefaultValueInFunction",
      input: """
        func foo(bar _: String?=nil) {}
        """,
      output: """
        func foo(bar _: String? = nil) {}
        """
    ),
    FormatCase(
      "noSpaceAddedAfterColonInSelector",
      input: """
        @objc(foo:bar:)
        """
    ),
    FormatCase(
      "spaceAfterColonInSwitchCase",
      input: """
        switch x { case .y:break }
        """,
      output: """
        switch x { case .y: break }
        """
    ),
    FormatCase(
      "spaceAfterColonInSwitchDefault",
      input: """
        switch x { default:break }
        """,
      output: """
        switch x { default: break }
        """
    ),
    FormatCase(
      "noSpaceBeforeColon",
      input: """
        let foo : Bar = 5
        """,
      output: """
        let foo: Bar = 5
        """
    ),
    FormatCase(
      "spacePreservedBeforeColonInTernary",
      input: """
        foo ? bar : baz
        """
    ),
    FormatCase(
      "spacePreservedAroundEnumValuesInTernary",
      input: """
        foo ? .Bar : .Baz
        """
    ),
    FormatCase(
      "spaceBeforeColonInNestedTernary",
      input: """
        foo ? (hello + a ? b: c) : baz
        """,
      output: """
        foo ? (hello + a ? b : c) : baz
        """
    ),

    // Commas
    FormatCase(
      "spaceAfterComma",
      input: """
        let foo = [1,2,3]
        """,
      output: """
        let foo = [1, 2, 3]
        """
    ),
    FormatCase(
      "spaceBetweenColonAndEnumValue",
      input: """
        [.Foo:.Bar]
        """,
      output: """
        [.Foo: .Bar]
        """
    ),
    FormatCase(
      "spaceBetweenCommaAndEnumValue",
      input: """
        [.Foo,.Bar]
        """,
      output: """
        [.Foo, .Bar]
        """
    ),
    FormatCase(
      "spaceBetweenSemicolonAndEnumValue",
      input: """
        statement;.Bar
        """,
      output: """
        statement; .Bar
        """
    ),
    FormatCase(
      "noSpaceBeforeComma",
      input: """
        let foo = [1 , 2 , 3]
        """,
      output: """
        let foo = [1, 2, 3]
        """
    ),

    // Operators - infix / prefix
    FormatCase(
      "spacePreservedBetweenEqualsAndEnumValue",
      input: """
        foo = .Bar
        """
    ),
    FormatCase(
      "spaceAroundInfixMinus",
      input: """
        foo-bar
        """,
      output: """
        foo - bar
        """
    ),
    FormatCase(
      "noSpaceAroundPrefixMinus",
      input: """
        foo + -bar
        """
    ),
    FormatCase(
      "spaceAroundLessThan",
      input: """
        foo<bar
        """,
      output: """
        foo < bar
        """
    ),
    FormatCase(
      "spaceAroundReturnTypeArrow",
      input: """
        foo() ->Bool
        """,
      output: """
        foo() -> Bool
        """
    ),
    FormatCase(
      "addSpaceAroundRange",
      input: """
        let a = b...c
        """,
      output: """
        let a = b ... c
        """
    ),
    FormatCase(
      "spaceAroundCommentInPrefixExpression",
      input: """
        a + /* hello */ -bar
        """
    ),
    FormatCase(
      "prefixMinusBeforeMember",
      input: """
        -.foo
        """
    ),
    FormatCase(
      "postfixMinusBeforeMember",
      input: """
        foo-.bar
        """
    ),
    FormatCase(
      "removeSpaceBeforeNegativeIndex",
      input: """
        foo[ -bar]
        """,
      output: """
        foo[-bar]
        """
    ),
    FormatCase(
      "spaceAroundPlusBeforeHash",
      input: """
        \"foo.\"+#file
        """,
      output: """
        \"foo.\" + #file
        """
    ),
    FormatCase(
      "spaceNotAddedAroundStarInAvailableAnnotation",
      input: """
        @available(*, deprecated, message: \"foo\")
        """
    ),
    FormatCase(
      "addSpaceAfterOperatorEquals",
      input: """
        operator =={}
        """,
      output: """
        operator == {}
        """
    ),
    FormatCase(
      "noAddSpaceAfterOperatorEqualsWithAllmanBrace",
      input: """
        operator ==
        {}
        """
    ),

    // Dots
    FormatCase(
      "removeSpaceAroundDot",
      input: """
        foo . bar
        """,
      output: """
        foo.bar
        """
    ),
    FormatCase(
      "noSpaceAroundDotOnNewLine",
      input: """
        foo
            .bar
        """
    ),
    FormatCase(
      "spaceRemovedInNestedPropertyWrapper",
      input: """
        @Encoded .Foo var foo: String
        """,
      output: """
        @Encoded.Foo var foo: String
        """
    ),
    FormatCase(
      "spaceNotAddedInKeyPath",
      input: """
        let a = b.map(\\.?.something)
        """
    ),

    // Enum cases
    FormatCase(
      "spaceAroundEnumCase",
      input: """
        case .Foo,.Bar:
        """,
      output: """
        case .Foo, .Bar:
        """
    ),
    FormatCase(
      "switchWithEnumCases",
      input: """
        switch x {
        case.Foo:
            break
        default:
            break
        }
        """,
      output: """
        switch x {
        case .Foo:
            break
        default:
            break
        }
        """
    ),
    FormatCase(
      "spaceAroundEnumReturn",
      input: """
        return.Foo
        """,
      output: """
        return .Foo
        """
    ),
    FormatCase(
      "noSpaceAfterReturnAsIdentifier",
      input: """
        foo.return.Bar
        """
    ),
    FormatCase(
      "spaceAroundCaseLet",
      input: """
        case let.Foo(bar):
        """,
      output: """
        case let .Foo(bar):
        """
    ),
    FormatCase(
      "spaceAroundEnumArgument",
      input: """
        foo(with:.Bar)
        """,
      output: """
        foo(with: .Bar)
        """
    ),
    FormatCase(
      "spaceBeforeEnumCaseInsideClosure",
      input: """
        { .bar() }
        """
    ),

    // Optional chaining
    FormatCase(
      "noSpaceAroundMultipleOptionalChaining",
      input: """
        foo??!?!.bar
        """
    ),
    FormatCase(
      "noSpaceAroundForcedChaining",
      input: """
        foo!.bar
        """
    ),
    FormatCase(
      "noSpaceAddedInOptionalChaining",
      input: """
        foo?.bar
        """
    ),
    FormatCase(
      "spaceRemovedInOptionalChaining",
      input: """
        foo? .bar
        """,
      output: """
        foo?.bar
        """
    ),
    FormatCase(
      "spaceRemovedInForcedChaining",
      input: """
        foo! .bar
        """,
      output: """
        foo!.bar
        """
    ),
    FormatCase(
      "spaceRemovedInMultipleOptionalChaining",
      input: """
        foo??! .bar
        """,
      output: """
        foo??!.bar
        """
    ),
    FormatCase(
      "noSpaceAfterOptionalInsideTernary",
      input: """
        x ? foo? .bar() : bar?.baz()
        """,
      output: """
        x ? foo?.bar() : bar?.baz()
        """
    ),
    FormatCase(
      "splitLineOptionalChaining",
      input: """
        foo?
            .bar
        """
    ),
    FormatCase(
      "splitLineMultipleOptionalChaining",
      input: """
        foo??!
            .bar
        """
    ),
    FormatCase(
      "spaceBetweenNullCoalescingAndDot",
      input: """
        foo ?? .bar()
        """
    ),

    // Failable init
    FormatCase(
      "noSpaceAroundFailableInit",
      input: """
        init?()
        """
    ),
    FormatCase(
      "noSpaceAroundImplictlyUnwrappedFailableInit",
      input: """
        init!()
        """
    ),
    FormatCase(
      "noSpaceAroundFailableInitWithGenerics",
      input: """
        init?<T>()
        """
    ),
    FormatCase(
      "noSpaceAroundImplictlyUnwrappedFailableInitWithGenerics",
      input: """
        init!<T>()
        """
    ),
    FormatCase(
      "noSpaceAroundInitWithGenericAndSuppressedConstraint",
      input: """
        init<T: ~Copyable>()
        """
    ),

    // Generics
    FormatCase(
      "genericBracketAroundAttributeNotConfusedWithLessThan",
      input: """
        Example<(@MainActor () -> Void)?>(nil)
        """
    ),
    FormatCase(
      "noSpaceAroundGenerics",
      input: """
        Foo<String>
        """
    ),
    FormatCase(
      "noSpaceAroundGenericsWithSuppressedConstraint",
      input: """
        Foo<String: ~Copyable>
        """
    ),

    // as? / as!
    FormatCase(
      "spaceAfterOptionalAs",
      input: """
        foo as?[String]
        """,
      output: """
        foo as? [String]
        """
    ),
    FormatCase(
      "spaceAfterForcedAs",
      input: """
        foo as![String]
        """,
      output: """
        foo as! [String]
        """
    ),

    // Address / key path
    FormatCase(
      "noInsertSpaceBeforeUnlabelledAddressArgument",
      input: """
        foo(&bar)
        """
    ),
    FormatCase(
      "removeSpaceBeforeUnlabelledAddressArgument",
      input: """
        foo( &bar, baz: &baz)
        """,
      output: """
        foo(&bar, baz: &baz)
        """
    ),
    FormatCase(
      "removeSpaceBeforeKeyPath",
      input: """
        foo( \\.bar)
        """,
      output: """
        foo(\\.bar)
        """
    ),

    // Custom infix operators
    FormatCase(
      "addSpaceEvenAfterLHSClosure",
      input: """
        let foo = { $0 }..bar
        """,
      output: """
        let foo = { $0 } .. bar
        """
    ),
    FormatCase(
      "addSpaceEvenBeforeRHSClosure",
      input: """
        let foo = bar..{ $0 }
        """,
      output: """
        let foo = bar .. { $0 }
        """
    ),
    FormatCase(
      "addSpaceEvenAfterLHSArray",
      input: """
        let foo = [42]..bar
        """,
      output: """
        let foo = [42] .. bar
        """
    ),
    FormatCase(
      "addSpaceEvenBeforeRHSArray",
      input: """
        let foo = bar..[42]
        """,
      output: """
        let foo = bar .. [42]
        """
    ),
    FormatCase(
      "addSpaceEvenAfterLHSParens",
      input: """
        let foo = (42, 1337)..bar
        """,
      output: """
        let foo = (42, 1337) .. bar
        """
    ),
    FormatCase(
      "addSpaceEvenBeforeRHSParens",
      input: """
        let foo = bar..(42, 1337)
        """,
      output: """
        let foo = bar .. (42, 1337)
        """
    ),
  ]

  @Test(arguments: Self.cases)
  func spaceAroundOperators(_ c: FormatCase) {
    testFormatting(for: c.input, c.output, rule: .spaceAroundOperators)
  }

  // MARK: - Individual tests (exclude: or options:)

}
