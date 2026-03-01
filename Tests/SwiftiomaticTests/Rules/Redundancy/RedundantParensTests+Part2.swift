import Testing
@testable import Swiftiomatic

extension RedundantParensTests {
    @Test func requiredParensNotRemoved3() {
        let input = """
        x+(-5)
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators],
        )
    }

    @Test func meaningfulParensNotRemovedAroundFileLiteral() {
        let input = """
        func foo(_ file: String = (#file)) {}
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func meaningfulParensNotRemovedAroundOperatorWithSpaces() {
        let input = """
        let foo: (Int, Int) -> Bool = ( < )
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators, .spaceInsideParens],
        )
    }

    @Test func meaningfulParensNotRemovedAroundPrefixOperator() {
        let input = """
        let foo: (Int) -> Int = ( -)
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators, .spaceInsideParens],
        )
    }

    @Test func meaningfulParensAroundPrefixExpressionWithSpacesFollowedByDotNotRemoved() {
        let input = """
        let foo = ( !bar ).description
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators, .spaceInsideParens],
        )
    }

    @Test func outerParensRemovedInWhile() {
        let input = """
        while ((x || y) && z) {}
        """
        let output = """
        while (x || y) && z {}
        """
        testFormatting(for: input, output, rule: .redundantParens, exclude: [.andOperator])
    }

    @Test func caseOuterParensRemoved() {
        let input = """
        switch foo {
        case (Foo.bar(let baz)):
        }
        """
        let output = """
        switch foo {
        case Foo.bar(let baz):
        }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func guardParensRemoved() {
        let input = """
        guard (x == y) else { return }
        """
        let output = """
        guard x == y else { return }
        """
        testFormatting(
            for: input, output, rule: .redundantParens,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func parensForLoopWhereClauseMethodNotRemoved() {
        let input = """
        for foo in foos where foo.method() { print(foo) }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.wrapLoopBodies])
    }

    @Test func requiredParensNotRemovedAroundOptionalClosureType() {
        let input = """
        let foo = (() -> ())?
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.void])
    }

    @Test func redundantParensRemovedAroundOptionalUnwrap() {
        let input = """
        let foo = (bar!)+5
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators],
        )
    }

    @Test func redundantParensRemovedAroundOptionalClosureType() {
        let input = """
        let foo = ((() -> ()))?
        """
        let output = """
        let foo = (() -> ())?
        """
        testFormatting(for: input, output, rule: .redundantParens, exclude: [.void])
    }

    @Test func requiredParensNotRemovedAfterClosureInsideArrayWithTrailingComma() {
        let input = """
        [{ /* code */ }(),]
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.trailingCommas])
    }

    @Test func requiredParensNotRemovedAfterClosureInWhereClause() {
        let input = """
        case foo where { x == y }():
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.redundantClosure])
    }

    @Test func singleClosureArgumentUnwrapped() {
        let input = """
        { (foo) in }
        """
        let output = """
        { foo in }
        """
        testFormatting(for: input, output, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func singleMainActorClosureArgumentUnwrapped() {
        let input = """
        { @MainActor (foo) in }
        """
        let output = """
        { @MainActor foo in }
        """
        testFormatting(for: input, output, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func singleClosureArgumentWithReturnValueUnwrapped() {
        let input = """
        { (foo) -> Int in 5 }
        """
        let output = """
        { foo -> Int in 5 }
        """
        testFormatting(for: input, output, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func singleAnonymousClosureArgumentNotUnwrapped() {
        let input = """
        { (_ foo) in }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func parensNotRemovedBeforeVarBody() {
        let input = """
        var foo = bar() { didSet {} }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.wrapPropertyBodies])
    }

    @Test func parensNotRemovedBeforeIfBody2() {
        let input = """
        if try foo as Bar && baz() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.andOperator])
    }

    @Test func parensNotRemovedBeforeIfBody3() {
        let input = """
        if #selector(foo(_:)) && bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.andOperator])
    }

    @Test func parensNotRemovedAfterAnonymousClosureInsideIfStatementBody() {
        let input = """
        if let foo = bar(), { x == y }() {}
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.redundantClosure])
    }

    @Test func parensNotRemovedInGenericInstantiation() {
        let input = """
        let foo = Foo<T>()
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.propertyTypes])
    }

    @Test func parensNotRemovedInGenericInstantiation2() {
        let input = """
        let foo = Foo<T>(bar)
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.propertyTypes])
    }

    @Test func parensNotRemovedAroundVoidGenerics() {
        let input = """
        let foo = Foo<Bar, (), ()>
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.void])
    }

    @Test func parensNotRemovedAroundTupleGenerics() {
        let input = """
        let foo = Foo<Bar, (Int, String), ()>
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.void])
    }

    @Test func parensNotRemovedAroundLabeledTupleGenerics() {
        let input = """
        let foo = Foo<Bar, (a: Int, b: String), ()>
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.void])
    }

    @Test func parensRemovedAroundRangeArguments() {
        let input = """
        (a)...(b)
        """
        let output = """
        a...b
        """
        testFormatting(
            for: input, output, rule: .redundantParens,
            exclude: [.spaceAroundOperators],
        )
    }

    @Test func parensNotRemovedAroundRangeArgumentBeginningWithDot() {
        let input = """
        a...(.b)
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators],
        )
    }

    @Test func parensNotRemovedAroundRangeArgumentBeginningWithPrefixOperator() {
        let input = """
        a...(-b)
        """
        testFormatting(
            for: input, rule: .redundantParens,
            exclude: [.spaceAroundOperators],
        )
    }

    // MARK: - Non-@Test functions

    // around tuples

    func testsTupleNotUnwrapped() {
        let input = """
        tuple = (1, 2)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    func testsTupleOfClosuresNotUnwrapped() {
        let input = """
        tuple = ({}, {})
        """
        testFormatting(for: input, rule: .redundantParens)
    }
}
