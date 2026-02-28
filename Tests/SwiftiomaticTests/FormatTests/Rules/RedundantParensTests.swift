import Testing
@testable import Swiftiomatic

@Suite struct RedundantParensTests {
    // around expressions

    @Test func redundantParensRemoved() {
        let input = """
        (x || y)
        """
        let output = """
        x || y
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemoved2() {
        let input = """
        (x) || y
        """
        let output = """
        x || y
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemoved3() {
        let input = """
        x + (5)
        """
        let output = """
        x + 5
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemoved4() {
        let input = """
        (.bar)
        """
        let output = """
        .bar
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemoved5() {
        let input = """
        (Foo.bar)
        """
        let output = """
        Foo.bar
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemoved6() {
        let input = """
        (foo())
        """
        let output = """
        foo()
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func requiredParensNotRemoved() {
        let input = """
        (x || y) * z
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemoved2() {
        let input = """
        (x + y) as Int
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemoved3() {
        let input = """
        x+(-5)
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators])
    }

    @Test func redundantParensAroundIsNotRemoved() {
        let input = """
        a = (x is Int)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedBeforeSubscript() {
        let input = """
        (foo + bar)[baz]
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedBeforeCollectionLiteral() {
        let input = """
        (foo + bar)
        [baz]
        """
        let output = """
        foo + bar
        [baz]
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedBeforeFunctionInvocation() {
        let input = """
        (foo + bar)(baz)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedBeforeTuple() {
        let input = """
        (foo + bar)
        (baz, quux).0
        """
        let output = """
        foo + bar
        (baz, quux).0
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedBeforePostfixOperator() {
        let input = """
        (foo + bar)!
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedBeforeInfixOperator() {
        let input = """
        (foo + bar) * baz
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensNotRemovedAroundSelectorStringLiteral() {
        let input = """
        Selector((\"foo\"))
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensRemovedOnLineAfterSelectorIdentifier() {
        let input = """
        Selector
        ((\"foo\"))
        """
        let output = """
        Selector
        (\"foo\")
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func meaningfulParensNotRemovedAroundFileLiteral() {
        let input = """
        func foo(_ file: String = (#file)) {}
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func meaningfulParensNotRemovedAroundOperator() {
        let input = """
        let foo: (Int, Int) -> Bool = (<)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensNotRemovedAroundOperatorWithSpaces() {
        let input = """
        let foo: (Int, Int) -> Bool = ( < )
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators, .spaceInsideParens])
    }

    @Test func meaningfulParensNotRemovedAroundPrefixOperator() {
        let input = """
        let foo: (Int) -> Int = ( -)
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators, .spaceInsideParens])
    }

    @Test func meaningfulParensAroundPrefixExpressionFollowedByDotNotRemoved() {
        let input = """
        let foo = (!bar).description
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensAroundPrefixExpressionWithSpacesFollowedByDotNotRemoved() {
        let input = """
        let foo = ( !bar ).description
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators, .spaceInsideParens])
    }

    @Test func meaningfulParensAroundPrefixExpressionFollowedByPostfixExpressionNotRemoved() {
        let input = """
        let foo = (!bar)!
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensAroundPrefixExpressionFollowedBySubscriptNotRemoved() {
        let input = """
        let foo = (!bar)[5]
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensAroundPostfixExpressionFollowedByPostfixOperatorRemoved() {
        let input = """
        let foo = (bar!)!
        """
        let output = """
        let foo = bar!!
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensAroundPostfixExpressionFollowedByPostfixOperatorRemoved2() {
        let input = """
        let foo = ( bar! )!
        """
        let output = """
        let foo = bar!!
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensAroundPostfixExpressionRemoved() {
        let input = """
        let foo = foo + (bar!)
        """
        let output = """
        let foo = foo + bar!
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensAroundPostfixExpressionFollowedBySubscriptRemoved() {
        let input = """
        let foo = (bar!)[5]
        """
        let output = """
        let foo = bar![5]
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensAroundPrefixExpressionRemoved() {
        let input = """
        let foo = foo + (!bar)
        """
        let output = """
        let foo = foo + !bar
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensAroundInfixExpressionNotRemoved() {
        let input = """
        let foo = (foo + bar)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensAroundInfixEqualsExpressionNotRemoved() {
        let input = """
        let foo = (bar == baz)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensAroundClosureTypeRemoved() {
        let input = """
        typealias Foo = ((Int) -> Bool)
        """
        let output = """
        typealias Foo = (Int) -> Bool
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func nonRedundantParensAroundClosureTypeNotRemoved() {
        let input = """
        describe("getAlbums") {
            typealias PhotoCollectionEnumerationHandler = (PhotoCollection) -> Void
            typealias PhotoEnumerationHandler = (PhotoFetchResultEnumeration) -> Void
        }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    // TODO: future enhancement
//    func testRedundantParensAroundClosureReturnTypeRemoved() {
//        let input = "typealias Foo = (Int) -> ((Int) -> Bool)"
//        let output = "typealias Foo = (Int) -> (Int) -> Bool"
//        testFormatting(for: input, output, rule: .redundantParens)
//    }

    @Test func redundantParensAroundNestedClosureTypesNotRemoved() {
        let input = """
        typealias Foo = (((Int) -> Bool) -> Int) -> ((String) -> Bool) -> Void
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensAroundClosureTypeNotRemoved() {
        let input = """
        let foo = ((Int) -> Bool)?
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensAroundTryExpressionNotRemoved() {
        let input = """
        let foo = (try? bar()) != nil
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func meaningfulParensAroundAwaitExpressionNotRemoved() {
        let input = """
        if !(await isSomething()) {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensInReturnRemoved() {
        let input = """
        return (true)
        """
        let output = """
        return true
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensInMultilineReturnRemovedCleanly() {
        let input = """
        return (
            foo
                .bar
        )
        """
        let output = """
        return
            foo
                .bar

        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    // around conditions

    @Test func redundantParensRemovedInIf() {
        let input = """
        if (x || y) {}
        """
        let output = """
        if x || y {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf2() {
        let input = """
        if (x) || y {}
        """
        let output = """
        if x || y {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf3() {
        let input = """
        if x + (5) == 6 {}
        """
        let output = """
        if x + 5 == 6 {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf4() {
        let input = """
        if (x || y), let foo = bar {}
        """
        let output = """
        if x || y, let foo = bar {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf5() {
        let input = """
        if (.bar) {}
        """
        let output = """
        if .bar {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf6() {
        let input = """
        if (Foo.bar) {}
        """
        let output = """
        if Foo.bar {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf7() {
        let input = """
        if (foo()) {}
        """
        let output = """
        if foo() {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIf8() {
        let input = """
        if x, (y == 2) {}
        """
        let output = """
        if x, y == 2 {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInIfWithNoSpace() {
        let input = """
        if(x) {}
        """
        let output = """
        if x {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInHashIfWithNoSpace() {
        let input = """
        #if(x)
        #endif
        """
        let output = """
        #if x
        #endif
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedInIf() {
        let input = """
        if (x || y) * z {}
        """
        testFormatting(for: input, rule: .redundantParens)
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

    @Test func outerParensRemovedInIf() {
        let input = """
        if (Foo.bar(baz)) {}
        """
        let output = """
        if Foo.bar(baz) {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
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
        testFormatting(for: input, output, rule: .redundantParens, exclude: [.hoistPatternLet])
    }

    @Test func caseLetOuterParensRemoved() {
        let input = """
        switch foo {
        case let (Foo.bar(baz)):
        }
        """
        let output = """
        switch foo {
        case let Foo.bar(baz):
        }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func caseVarOuterParensRemoved() {
        let input = """
        switch foo {
        case var (Foo.bar(baz)):
        }
        """
        let output = """
        switch foo {
        case var Foo.bar(baz):
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
        testFormatting(for: input, output, rule: .redundantParens,
                       exclude: [.wrapConditionalBodies])
    }

    @Test func forValueParensRemoved() {
        let input = """
        for (x) in (y) {}
        """
        let output = """
        for x in y {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensForLoopWhereClauseMethodNotRemoved() {
        let input = """
        for foo in foos where foo.method() { print(foo) }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.wrapLoopBodies])
    }

    @Test func spaceInsertedWhenRemovingParens() {
        let input = """
        if(x.y) {}
        """
        let output = """
        if x.y {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func spaceInsertedWhenRemovingParens2() {
        let input = """
        while(!foo) {}
        """
        let output = """
        while !foo {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func noDoubleSpaceWhenRemovingParens() {
        let input = """
        if ( x.y ) {}
        """
        let output = """
        if x.y {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func noDoubleSpaceWhenRemovingParens2() {
        let input = """
        if (x.y) {}
        """
        let output = """
        if x.y {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    // around function and closure arguments

    @Test func nestedClosureParensNotRemoved() {
        let input = """
        foo { _ in foo(y) {} }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func closureTypeNotUnwrapped() {
        let input = """
        foo = (Bar) -> Baz
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func optionalFunctionCallNotUnwrapped() {
        let input = """
        foo?(bar)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func optionalFunctionCallResultNotUnwrapped() {
        let input = """
        bar = (foo?()).flatMap(Bar.init)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func optionalSubscriptResultNotUnwrapped() {
        let input = """
        bar = (foo?[0]).flatMap(Bar.init)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func optionalMemberResultNotUnwrapped() {
        let input = """
        bar = (foo?.baz).flatMap(Bar.init)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func forceUnwrapFunctionCallNotUnwrapped() {
        let input = """
        foo!(bar)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func curriedFunctionCallNotUnwrapped() {
        let input = """
        foo(bar)(baz)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func curriedFunctionCallNotUnwrapped2() {
        let input = """
        foo(bar)(baz) + quux
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func subscriptFunctionCallNotUnwrapped() {
        let input = """
        foo[\"bar\"](baz)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedInsideClosure() {
        let input = """
        { (foo) + bar }
        """
        let output = """
        { foo + bar }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensRemovedAroundFunctionArgument() {
        let input = """
        foo(bar: (5))
        """
        let output = """
        foo(bar: 5)
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAroundOptionalClosureType() {
        let input = """
        let foo = (() -> ())?
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.void])
    }

    @Test func requiredParensNotRemovedAroundOptionalRange() {
        let input = """
        let foo = (2...)?
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundOptionalUnwrap() {
        let input = """
        let foo = (bar!)+5
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators])
    }

    @Test func redundantParensRemovedAroundOptionalOptional() {
        let input = """
        let foo: (Int?)?
        """
        let output = """
        let foo: Int??
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundOptionalOptional2() {
        let input = """
        let foo: (Int!)?
        """
        let output = """
        let foo: Int!?
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundOptionalOptional3() {
        let input = """
        let foo: (Int?)!
        """
        let output = """
        let foo: Int?!
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAroundOptionalAnyType() {
        let input = """
        let foo: (any Foo)?
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAroundAnyTypeSelf() {
        let input = """
        let foo = (any Foo).self
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAroundAnyTypeType() {
        let input = """
        let foo: (any Foo).Type
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAroundAnyComposedMetatype() {
        let input = """
        let foo: any (A & B).Type
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundAnyType() {
        let input = """
        let foo: (any Foo)
        """
        let output = """
        let foo: any Foo
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundAnyTypeInsideArray() {
        let input = """
        let foo: [(any Foo)]
        """
        let output = """
        let foo: [any Foo]
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensAroundParameterPackEachNotRemoved() {
        let input = """
        func f<each V>(_: repeat ((each V).Type, as: (each V) -> String)) {}
        """
        testFormatting(for: input, rule: .redundantParens)
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

    @Test func requiredParensNotRemovedAfterClosureArgument() {
        let input = """
        foo({ /* code */ }())
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAfterClosureArgument2() {
        let input = """
        foo(bar: { /* code */ }())
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAfterClosureArgument3() {
        let input = """
        foo(bar: 5, { /* code */ }())
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAfterClosureInsideArray() {
        let input = """
        [{ /* code */ }()]
        """
        testFormatting(for: input, rule: .redundantParens)
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

    // around closure arguments

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

    @Test func singleAnonymousClosureArgumentUnwrapped() {
        let input = """
        { (_) in }
        """
        let output = """
        { _ in }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func singleAnonymousClosureArgumentNotUnwrapped() {
        let input = """
        { (_ foo) in }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.unusedArguments])
    }

    @Test func typedClosureArgumentNotUnwrapped() {
        let input = """
        { (foo: Int) in print(foo) }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func singleClosureArgumentAfterCaptureListUnwrapped() {
        let input = """
        { [weak self] (foo) in self.bar(foo) }
        """
        let output = """
        { [weak self] foo in self.bar(foo) }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func multipleClosureArgumentUnwrapped() {
        let input = """
        { (foo, bar) in foo(bar) }
        """
        let output = """
        { foo, bar in foo(bar) }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func typedMultipleClosureArgumentNotUnwrapped() {
        let input = """
        { (foo: Int, bar: String) in foo(bar) }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func emptyClosureArgsNotUnwrapped() {
        let input = """
        { () in }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func closureArgsContainingSelfNotUnwrapped() {
        let input = """
        { (self) in self }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func closureArgsContainingSelfNotUnwrapped2() {
        let input = """
        { (foo, self) in foo(self) }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func closureArgsContainingSelfNotUnwrapped3() {
        let input = """
        { (self, foo) in foo(self) }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func noRemoveParensAroundArrayInitializer() {
        let input = """
        let foo = bar { [Int](foo) }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func noRemoveParensAroundForIndexInsideClosure() {
        let input = """
        let foo = {
            for (i, token) in bar {}
        }()
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func noRemoveRequiredParensInsideClosure() {
        let input = """
        let foo = { _ in (a + b).c }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    // before trailing closure

    @Test func parensRemovedBeforeTrailingClosure() {
        let input = """
        var foo = bar() { /* some code */ }
        """
        let output = """
        var foo = bar { /* some code */ }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensRemovedBeforeTrailingClosure2() {
        let input = """
        let foo = bar() { /* some code */ }
        """
        let output = """
        let foo = bar { /* some code */ }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensRemovedBeforeTrailingClosure3() {
        let input = """
        var foo = bar() { /* some code */ }
        """
        let output = """
        var foo = bar { /* some code */ }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensRemovedBeforeTrailingClosureInsideHashIf() {
        let input = """
        #if baz
            let foo = bar() { /* some code */ }
        #endif
        """
        let output = """
        #if baz
            let foo = bar { /* some code */ }
        #endif
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeVarBody() {
        let input = """
        var foo = bar() { didSet {} }
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.wrapPropertyBodies])
    }

    @Test func parensNotRemovedBeforeFunctionBody() {
        let input = """
        func bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeIfBody() {
        let input = """
        if let foo = bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
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

    @Test func parensNotRemovedBeforeIfBody4() {
        let input = """
        if let data = #imageLiteral(resourceName: \"abc.png\").pngData() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeIfBody5() {
        let input = """
        if currentProducts != newProducts.map { $0.id }.sorted() {
            self?.products.accept(newProducts)
        }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeIfBodyAfterTry() {
        let input = """
        if let foo = try bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeCompoundIfBody() {
        let input = """
        if let foo = bar(), let baz = quux() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeForBody() {
        let input = """
        for foo in bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeWhileBody() {
        let input = """
        while let foo = bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeCaseBody() {
        let input = """
        if case foo = bar() { /* some code */ }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedBeforeSwitchBody() {
        let input = """
        switch foo() {
        default: break
        }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAfterAnonymousClosureInsideIfStatementBody() {
        let input = """
        if let foo = bar(), { x == y }() {}
        """
        testFormatting(for: input, rule: .redundantParens, exclude: [.redundantClosure])
    }

    @Test func parensNotRemovedInGenericInit() {
        let input = """
        init<T>(_: T) {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedInGenericInit2() {
        let input = """
        init<T>() {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedInGenericFunction() {
        let input = """
        func foo<T>(_: T) {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedInGenericFunction2() {
        let input = """
        func foo<T>() {}
        """
        testFormatting(for: input, rule: .redundantParens)
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

    @Test func redundantParensRemovedAfterGenerics() {
        let input = """
        let foo: Foo<T>
        (a) + b
        """
        let output = """
        let foo: Foo<T>
        a + b
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAfterGenerics2() {
        let input = """
        let foo: Foo<T>
        (foo())
        """
        let output = """
        let foo: Foo<T>
        foo()
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    // closure expression

    @Test func parensAroundClosureRemoved() {
        let input = """
        let foo = ({ /* some code */ })
        """
        let output = """
        let foo = { /* some code */ }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensAroundClosureAssignmentBlockRemoved() {
        let input = """
        let foo = ({ /* some code */ })()
        """
        let output = """
        let foo = { /* some code */ }()
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensAroundClosureInCompoundExpressionRemoved() {
        let input = """
        if foo == ({ /* some code */ }), let bar = baz {}
        """
        let output = """
        if foo == { /* some code */ }, let bar = baz {}
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundClosure() {
        let input = """
        if (foo { $0 }) {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundClosure2() {
        let input = """
        if (foo.filter { $0 > 1 }.isEmpty) {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundClosure3() {
        let input = """
        if let foo = (bar.filter { $0 > 1 }).first {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

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

    @Test func switchTupleNotUnwrapped() {
        let input = """
        switch (x, y) {}
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensRemovedAroundTuple() {
        let input = """
        let foo = ((bar: Int, baz: String))
        """
        let output = """
        let foo = (bar: Int, baz: String)
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundTupleFunctionArgument() {
        let input = """
        let foo = bar((bar: Int, baz: String))
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundTupleFunctionArgumentAfterSubscript() {
        let input = """
        bar[5]((bar: Int, baz: String))
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func nestedParensRemovedAroundTupleFunctionArgument() {
        let input = """
        let foo = bar(((bar: Int, baz: String)))
        """
        let output = """
        let foo = bar((bar: Int, baz: String))
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func nestedParensRemovedAroundTupleFunctionArgument2() {
        let input = """
        let foo = bar(foo: ((bar: Int, baz: String)))
        """
        let output = """
        let foo = bar(foo: (bar: Int, baz: String))
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func nestedParensRemovedAroundTupleOperands() {
        let input = """
        ((1, 2)) == ((1, 2))
        """
        let output = """
        (1, 2) == (1, 2)
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundTupleFunctionTypeDeclaration() {
        let input = """
        let foo: ((bar: Int, baz: String)) -> Void
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundUnlabelledTupleFunctionTypeDeclaration() {
        let input = """
        let foo: ((Int, String)) -> Void
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundTupleFunctionTypeAssignment() {
        let input = """
        foo = ((bar: Int, baz: String)) -> Void { _ in }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundTupleFunctionTypeAssignment() {
        let input = """
        foo = ((((bar: Int, baz: String)))) -> Void { _ in }
        """
        let output = """
        foo = ((bar: Int, baz: String)) -> Void { _ in }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundUnlabelledTupleFunctionTypeAssignment() {
        let input = """
        foo = ((Int, String)) -> Void { _ in }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func redundantParensRemovedAroundUnlabelledTupleFunctionTypeAssignment() {
        let input = """
        foo = ((((Int, String)))) -> Void { _ in }
        """
        let output = """
        foo = ((Int, String)) -> Void { _ in }
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundTupleArgument() {
        let input = """
        foo((bar, baz))
        """
        testFormatting(for: input, rule: .redundantParens)
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

    // after indexed tuple

    @Test func parensNotRemovedAfterTupleIndex() {
        let input = """
        foo.1()
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAfterTupleIndex2() {
        let input = """
        foo.1(true)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAfterTupleIndex3() {
        let input = """
        foo.1((bar: Int, baz: String))
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func nestedParensRemovedAfterTupleIndex3() {
        let input = """
        foo.1(((bar: Int, baz: String)))
        """
        let output = """
        foo.1((bar: Int, baz: String))
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    // inside string interpolation

    @Test func parensInStringNotRemoved() {
        let input = """
        \"hello \\(world)\"
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    // around ranges

    @Test func parensAroundRangeNotRemoved() {
        let input = """
        (1 ..< 10).reduce(0, combine: +)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensRemovedAroundRangeArguments() {
        let input = """
        (a)...(b)
        """
        let output = """
        a...b
        """
        testFormatting(for: input, output, rule: .redundantParens,
                       exclude: [.spaceAroundOperators])
    }

    @Test func parensNotRemovedAroundRangeArgumentBeginningWithDot() {
        let input = """
        a...(.b)
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators])
    }

    @Test func parensNotRemovedAroundTrailingRangeFollowedByDot() {
        let input = """
        (a...).b
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func parensNotRemovedAroundRangeArgumentBeginningWithPrefixOperator() {
        let input = """
        a...(-b)
        """
        testFormatting(for: input, rule: .redundantParens,
                       exclude: [.spaceAroundOperators])
    }

    @Test func parensRemovedAroundRangeArgumentBeginningWithDot() {
        let input = """
        a ... (.b)
        """
        let output = """
        a ... .b
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    @Test func parensRemovedAroundRangeArgumentBeginningWithPrefixOperator() {
        let input = """
        a ... (-b)
        """
        let output = """
        a ... -b
        """
        testFormatting(for: input, output, rule: .redundantParens)
    }

    // around ternaries

    @Test func parensNotRemovedAroundTernaryCondition() {
        let input = """
        let a = (b == c) ? d : e
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedAroundTernaryAssignment() {
        let input = """
        a ? (b = c) : (b = d)
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    // around parameter repeat each

    @Test func requiredParensNotRemovedAroundRepeat() {
        let input = """
        (repeat (each foo, each bar))
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    // in async expression

    @Test func requiredParensNotRemovedInAsyncLet() {
        let input = """
        Task {
            async let dataTask1: Void = someTask(request)
            async let dataTask2: Void = someTask(request)
        }
        """
        testFormatting(for: input, rule: .redundantParens)
    }

    @Test func requiredParensNotRemovedInAsyncLet2() {
        let input = """
        Task {
            let processURL: (URL) async throws -> Void = { _ in }
        }
        """
        testFormatting(for: input, rule: .redundantParens)
    }
}
