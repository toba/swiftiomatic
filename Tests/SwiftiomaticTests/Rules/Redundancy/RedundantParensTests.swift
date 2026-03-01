import Testing

@testable import Swiftiomatic

@Suite struct RedundantParensTests {
  // MARK: - Parameterized cases

  static let cases: [FormatCase] = [
    // around expressions

    FormatCase(
      "redundantParensRemoved",
      input: """
        (x || y)
        """,
      output: """
        x || y
        """
    ),
    FormatCase(
      "redundantParensRemoved2",
      input: """
        (x) || y
        """,
      output: """
        x || y
        """
    ),
    FormatCase(
      "redundantParensRemoved3",
      input: """
        x + (5)
        """,
      output: """
        x + 5
        """
    ),
    FormatCase(
      "redundantParensRemoved4",
      input: """
        (.bar)
        """,
      output: """
        .bar
        """
    ),
    FormatCase(
      "redundantParensRemoved5",
      input: """
        (Foo.bar)
        """,
      output: """
        Foo.bar
        """
    ),
    FormatCase(
      "redundantParensRemoved6",
      input: """
        (foo())
        """,
      output: """
        foo()
        """
    ),
    FormatCase(
      "requiredParensNotRemoved",
      input: """
        (x || y) * z
        """
    ),
    FormatCase(
      "requiredParensNotRemoved2",
      input: """
        (x + y) as Int
        """
    ),
    FormatCase(
      "redundantParensAroundIsNotRemoved",
      input: """
        a = (x is Int)
        """
    ),
    FormatCase(
      "requiredParensNotRemovedBeforeSubscript",
      input: """
        (foo + bar)[baz]
        """
    ),
    FormatCase(
      "redundantParensRemovedBeforeCollectionLiteral",
      input: """
        (foo + bar)
        [baz]
        """,
      output: """
        foo + bar
        [baz]
        """
    ),
    FormatCase(
      "requiredParensNotRemovedBeforeFunctionInvocation",
      input: """
        (foo + bar)(baz)
        """
    ),
    FormatCase(
      "redundantParensRemovedBeforeTuple",
      input: """
        (foo + bar)
        (baz, quux).0
        """,
      output: """
        foo + bar
        (baz, quux).0
        """
    ),
    FormatCase(
      "requiredParensNotRemovedBeforePostfixOperator",
      input: """
        (foo + bar)!
        """
    ),
    FormatCase(
      "requiredParensNotRemovedBeforeInfixOperator",
      input: """
        (foo + bar) * baz
        """
    ),
    FormatCase(
      "meaningfulParensNotRemovedAroundSelectorStringLiteral",
      input: """
        Selector((\"foo\"))
        """
    ),
    FormatCase(
      "parensRemovedOnLineAfterSelectorIdentifier",
      input: """
        Selector
        ((\"foo\"))
        """,
      output: """
        Selector
        (\"foo\")
        """
    ),
    FormatCase(
      "meaningfulParensNotRemovedAroundOperator",
      input: """
        let foo: (Int, Int) -> Bool = (<)
        """
    ),
    FormatCase(
      "meaningfulParensAroundPrefixExpressionFollowedByDotNotRemoved",
      input: """
        let foo = (!bar).description
        """
    ),
    FormatCase(
      "meaningfulParensAroundPrefixExpressionFollowedByPostfixExpressionNotRemoved",
      input: """
        let foo = (!bar)!
        """
    ),
    FormatCase(
      "meaningfulParensAroundPrefixExpressionFollowedBySubscriptNotRemoved",
      input: """
        let foo = (!bar)[5]
        """
    ),
    FormatCase(
      "redundantParensAroundPostfixExpressionFollowedByPostfixOperatorRemoved",
      input: """
        let foo = (bar!)!
        """,
      output: """
        let foo = bar!!
        """
    ),
    FormatCase(
      "redundantParensAroundPostfixExpressionFollowedByPostfixOperatorRemoved2",
      input: """
        let foo = ( bar! )!
        """,
      output: """
        let foo = bar!!
        """
    ),
    FormatCase(
      "redundantParensAroundPostfixExpressionRemoved",
      input: """
        let foo = foo + (bar!)
        """,
      output: """
        let foo = foo + bar!
        """
    ),
    FormatCase(
      "redundantParensAroundPostfixExpressionFollowedBySubscriptRemoved",
      input: """
        let foo = (bar!)[5]
        """,
      output: """
        let foo = bar![5]
        """
    ),
    FormatCase(
      "redundantParensAroundPrefixExpressionRemoved",
      input: """
        let foo = foo + (!bar)
        """,
      output: """
        let foo = foo + !bar
        """
    ),
    FormatCase(
      "redundantParensAroundInfixExpressionNotRemoved",
      input: """
        let foo = (foo + bar)
        """
    ),
    FormatCase(
      "redundantParensAroundInfixEqualsExpressionNotRemoved",
      input: """
        let foo = (bar == baz)
        """
    ),
    FormatCase(
      "redundantParensAroundClosureTypeRemoved",
      input: """
        typealias Foo = ((Int) -> Bool)
        """,
      output: """
        typealias Foo = (Int) -> Bool
        """
    ),
    FormatCase(
      "nonRedundantParensAroundClosureTypeNotRemoved",
      input: """
        describe("getAlbums") {
            typealias PhotoCollectionEnumerationHandler = (PhotoCollection) -> Void
            typealias PhotoEnumerationHandler = (PhotoFetchResultEnumeration) -> Void
        }
        """
    ),
    FormatCase(
      "redundantParensAroundNestedClosureTypesNotRemoved",
      input: """
        typealias Foo = (((Int) -> Bool) -> Int) -> ((String) -> Bool) -> Void
        """
    ),
    FormatCase(
      "meaningfulParensAroundClosureTypeNotRemoved",
      input: """
        let foo = ((Int) -> Bool)?
        """
    ),
    FormatCase(
      "meaningfulParensAroundTryExpressionNotRemoved",
      input: """
        let foo = (try? bar()) != nil
        """
    ),
    FormatCase(
      "meaningfulParensAroundAwaitExpressionNotRemoved",
      input: """
        if !(await isSomething()) {}
        """
    ),
    FormatCase(
      "redundantParensInReturnRemoved",
      input: """
        return (true)
        """,
      output: """
        return true
        """
    ),
    FormatCase(
      "redundantParensInMultilineReturnRemovedCleanly",
      input: """
        return (
            foo
                .bar
        )
        """,
      output: """
        return
            foo
                .bar

        """
    ),

    // around conditions

    FormatCase(
      "redundantParensRemovedInIf",
      input: """
        if (x || y) {}
        """,
      output: """
        if x || y {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf2",
      input: """
        if (x) || y {}
        """,
      output: """
        if x || y {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf3",
      input: """
        if x + (5) == 6 {}
        """,
      output: """
        if x + 5 == 6 {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf4",
      input: """
        if (x || y), let foo = bar {}
        """,
      output: """
        if x || y, let foo = bar {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf5",
      input: """
        if (.bar) {}
        """,
      output: """
        if .bar {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf6",
      input: """
        if (Foo.bar) {}
        """,
      output: """
        if Foo.bar {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf7",
      input: """
        if (foo()) {}
        """,
      output: """
        if foo() {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIf8",
      input: """
        if x, (y == 2) {}
        """,
      output: """
        if x, y == 2 {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInIfWithNoSpace",
      input: """
        if(x) {}
        """,
      output: """
        if x {}
        """
    ),
    FormatCase(
      "redundantParensRemovedInHashIfWithNoSpace",
      input: """
        #if(x)
        #endif
        """,
      output: """
        #if x
        #endif
        """
    ),
    FormatCase(
      "requiredParensNotRemovedInIf",
      input: """
        if (x || y) * z {}
        """
    ),
    FormatCase(
      "outerParensRemovedInIf",
      input: """
        if (Foo.bar(baz)) {}
        """,
      output: """
        if Foo.bar(baz) {}
        """
    ),
    FormatCase(
      "caseLetOuterParensRemoved",
      input: """
        switch foo {
        case let (Foo.bar(baz)):
        }
        """,
      output: """
        switch foo {
        case let Foo.bar(baz):
        }
        """
    ),
    FormatCase(
      "caseVarOuterParensRemoved",
      input: """
        switch foo {
        case var (Foo.bar(baz)):
        }
        """,
      output: """
        switch foo {
        case var Foo.bar(baz):
        }
        """
    ),
    FormatCase(
      "forValueParensRemoved",
      input: """
        for (x) in (y) {}
        """,
      output: """
        for x in y {}
        """
    ),
    FormatCase(
      "spaceInsertedWhenRemovingParens",
      input: """
        if(x.y) {}
        """,
      output: """
        if x.y {}
        """
    ),
    FormatCase(
      "spaceInsertedWhenRemovingParens2",
      input: """
        while(!foo) {}
        """,
      output: """
        while !foo {}
        """
    ),
    FormatCase(
      "noDoubleSpaceWhenRemovingParens",
      input: """
        if ( x.y ) {}
        """,
      output: """
        if x.y {}
        """
    ),
    FormatCase(
      "noDoubleSpaceWhenRemovingParens2",
      input: """
        if (x.y) {}
        """,
      output: """
        if x.y {}
        """
    ),

    // around function and closure arguments

    FormatCase(
      "nestedClosureParensNotRemoved",
      input: """
        foo { _ in foo(y) {} }
        """
    ),
    FormatCase(
      "closureTypeNotUnwrapped",
      input: """
        foo = (Bar) -> Baz
        """
    ),
    FormatCase(
      "optionalFunctionCallNotUnwrapped",
      input: """
        foo?(bar)
        """
    ),
    FormatCase(
      "optionalFunctionCallResultNotUnwrapped",
      input: """
        bar = (foo?()).flatMap(Bar.init)
        """
    ),
    FormatCase(
      "optionalSubscriptResultNotUnwrapped",
      input: """
        bar = (foo?[0]).flatMap(Bar.init)
        """
    ),
    FormatCase(
      "optionalMemberResultNotUnwrapped",
      input: """
        bar = (foo?.baz).flatMap(Bar.init)
        """
    ),
    FormatCase(
      "forceUnwrapFunctionCallNotUnwrapped",
      input: """
        foo!(bar)
        """
    ),
    FormatCase(
      "curriedFunctionCallNotUnwrapped",
      input: """
        foo(bar)(baz)
        """
    ),
    FormatCase(
      "curriedFunctionCallNotUnwrapped2",
      input: """
        foo(bar)(baz) + quux
        """
    ),
    FormatCase(
      "subscriptFunctionCallNotUnwrapped",
      input: """
        foo[\"bar\"](baz)
        """
    ),
    FormatCase(
      "redundantParensRemovedInsideClosure",
      input: """
        { (foo) + bar }
        """,
      output: """
        { foo + bar }
        """
    ),
    FormatCase(
      "parensRemovedAroundFunctionArgument",
      input: """
        foo(bar: (5))
        """,
      output: """
        foo(bar: 5)
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAroundOptionalRange",
      input: """
        let foo = (2...)?
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundOptionalOptional",
      input: """
        let foo: (Int?)?
        """,
      output: """
        let foo: Int??
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundOptionalOptional2",
      input: """
        let foo: (Int!)?
        """,
      output: """
        let foo: Int!?
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundOptionalOptional3",
      input: """
        let foo: (Int?)!
        """,
      output: """
        let foo: Int?!
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAroundOptionalAnyType",
      input: """
        let foo: (any Foo)?
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAroundAnyTypeSelf",
      input: """
        let foo = (any Foo).self
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAroundAnyTypeType",
      input: """
        let foo: (any Foo).Type
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAroundAnyComposedMetatype",
      input: """
        let foo: any (A & B).Type
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundAnyType",
      input: """
        let foo: (any Foo)
        """,
      output: """
        let foo: any Foo
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundAnyTypeInsideArray",
      input: """
        let foo: [(any Foo)]
        """,
      output: """
        let foo: [any Foo]
        """
    ),
    FormatCase(
      "parensAroundParameterPackEachNotRemoved",
      input: """
        func f<each V>(_: repeat ((each V).Type, as: (each V) -> String)) {}
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAfterClosureArgument",
      input: """
        foo({ /* code */ }())
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAfterClosureArgument2",
      input: """
        foo(bar: { /* code */ }())
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAfterClosureArgument3",
      input: """
        foo(bar: 5, { /* code */ }())
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAfterClosureInsideArray",
      input: """
        [{ /* code */ }()]
        """
    ),

    // around closure arguments

    FormatCase(
      "singleAnonymousClosureArgumentUnwrapped",
      input: """
        { (_) in }
        """,
      output: """
        { _ in }
        """
    ),
    FormatCase(
      "typedClosureArgumentNotUnwrapped",
      input: """
        { (foo: Int) in print(foo) }
        """
    ),
    FormatCase(
      "singleClosureArgumentAfterCaptureListUnwrapped",
      input: """
        { [weak self] (foo) in self.bar(foo) }
        """,
      output: """
        { [weak self] foo in self.bar(foo) }
        """
    ),
    FormatCase(
      "multipleClosureArgumentUnwrapped",
      input: """
        { (foo, bar) in foo(bar) }
        """,
      output: """
        { foo, bar in foo(bar) }
        """
    ),
    FormatCase(
      "typedMultipleClosureArgumentNotUnwrapped",
      input: """
        { (foo: Int, bar: String) in foo(bar) }
        """
    ),
    FormatCase(
      "emptyClosureArgsNotUnwrapped",
      input: """
        { () in }
        """
    ),
    FormatCase(
      "closureArgsContainingSelfNotUnwrapped",
      input: """
        { (self) in self }
        """
    ),
    FormatCase(
      "closureArgsContainingSelfNotUnwrapped2",
      input: """
        { (foo, self) in foo(self) }
        """
    ),
    FormatCase(
      "closureArgsContainingSelfNotUnwrapped3",
      input: """
        { (self, foo) in foo(self) }
        """
    ),
    FormatCase(
      "noRemoveParensAroundArrayInitializer",
      input: """
        let foo = bar { [Int](foo) }
        """
    ),
    FormatCase(
      "noRemoveParensAroundForIndexInsideClosure",
      input: """
        let foo = {
            for (i, token) in bar {}
        }()
        """
    ),
    FormatCase(
      "noRemoveRequiredParensInsideClosure",
      input: """
        let foo = { _ in (a + b).c }
        """
    ),

    // before trailing closure

    FormatCase(
      "parensRemovedBeforeTrailingClosure",
      input: """
        var foo = bar() { /* some code */ }
        """,
      output: """
        var foo = bar { /* some code */ }
        """
    ),
    FormatCase(
      "parensRemovedBeforeTrailingClosure2",
      input: """
        let foo = bar() { /* some code */ }
        """,
      output: """
        let foo = bar { /* some code */ }
        """
    ),
    FormatCase(
      "parensRemovedBeforeTrailingClosure3",
      input: """
        var foo = bar() { /* some code */ }
        """,
      output: """
        var foo = bar { /* some code */ }
        """
    ),
    FormatCase(
      "parensRemovedBeforeTrailingClosureInsideHashIf",
      input: """
        #if baz
            let foo = bar() { /* some code */ }
        #endif
        """,
      output: """
        #if baz
            let foo = bar { /* some code */ }
        #endif
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeFunctionBody",
      input: """
        func bar() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeIfBody",
      input: """
        if let foo = bar() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeIfBody4",
      input: """
        if let data = #imageLiteral(resourceName: \"abc.png\").pngData() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeIfBody5",
      input: """
        if currentProducts != newProducts.map { $0.id }.sorted() {
            self?.products.accept(newProducts)
        }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeIfBodyAfterTry",
      input: """
        if let foo = try bar() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeCompoundIfBody",
      input: """
        if let foo = bar(), let baz = quux() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeForBody",
      input: """
        for foo in bar() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeWhileBody",
      input: """
        while let foo = bar() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeCaseBody",
      input: """
        if case foo = bar() { /* some code */ }
        """
    ),
    FormatCase(
      "parensNotRemovedBeforeSwitchBody",
      input: """
        switch foo() {
        default: break
        }
        """
    ),
    FormatCase(
      "parensNotRemovedInGenericInit",
      input: """
        init<T>(_: T) {}
        """
    ),
    FormatCase(
      "parensNotRemovedInGenericInit2",
      input: """
        init<T>() {}
        """
    ),
    FormatCase(
      "parensNotRemovedInGenericFunction",
      input: """
        func foo<T>(_: T) {}
        """
    ),
    FormatCase(
      "parensNotRemovedInGenericFunction2",
      input: """
        func foo<T>() {}
        """
    ),
    FormatCase(
      "redundantParensRemovedAfterGenerics",
      input: """
        let foo: Foo<T>
        (a) + b
        """,
      output: """
        let foo: Foo<T>
        a + b
        """
    ),
    FormatCase(
      "redundantParensRemovedAfterGenerics2",
      input: """
        let foo: Foo<T>
        (foo())
        """,
      output: """
        let foo: Foo<T>
        foo()
        """
    ),

    // closure expression

    FormatCase(
      "parensAroundClosureRemoved",
      input: """
        let foo = ({ /* some code */ })
        """,
      output: """
        let foo = { /* some code */ }
        """
    ),
    FormatCase(
      "parensAroundClosureAssignmentBlockRemoved",
      input: """
        let foo = ({ /* some code */ })()
        """,
      output: """
        let foo = { /* some code */ }()
        """
    ),
    FormatCase(
      "parensAroundClosureInCompoundExpressionRemoved",
      input: """
        if foo == ({ /* some code */ }), let bar = baz {}
        """,
      output: """
        if foo == { /* some code */ }, let bar = baz {}
        """
    ),
    FormatCase(
      "parensNotRemovedAroundClosure",
      input: """
        if (foo { $0 }) {}
        """
    ),
    FormatCase(
      "parensNotRemovedAroundClosure2",
      input: """
        if (foo.filter { $0 > 1 }.isEmpty) {}
        """
    ),
    FormatCase(
      "parensNotRemovedAroundClosure3",
      input: """
        if let foo = (bar.filter { $0 > 1 }).first {}
        """
    ),

    // around tuples

    FormatCase(
      "switchTupleNotUnwrapped",
      input: """
        switch (x, y) {}
        """
    ),
    FormatCase(
      "parensRemovedAroundTuple",
      input: """
        let foo = ((bar: Int, baz: String))
        """,
      output: """
        let foo = (bar: Int, baz: String)
        """
    ),
    FormatCase(
      "parensNotRemovedAroundTupleFunctionArgument",
      input: """
        let foo = bar((bar: Int, baz: String))
        """
    ),
    FormatCase(
      "parensNotRemovedAroundTupleFunctionArgumentAfterSubscript",
      input: """
        bar[5]((bar: Int, baz: String))
        """
    ),
    FormatCase(
      "nestedParensRemovedAroundTupleFunctionArgument",
      input: """
        let foo = bar(((bar: Int, baz: String)))
        """,
      output: """
        let foo = bar((bar: Int, baz: String))
        """
    ),
    FormatCase(
      "nestedParensRemovedAroundTupleFunctionArgument2",
      input: """
        let foo = bar(foo: ((bar: Int, baz: String)))
        """,
      output: """
        let foo = bar(foo: (bar: Int, baz: String))
        """
    ),
    FormatCase(
      "nestedParensRemovedAroundTupleOperands",
      input: """
        ((1, 2)) == ((1, 2))
        """,
      output: """
        (1, 2) == (1, 2)
        """
    ),
    FormatCase(
      "parensNotRemovedAroundTupleFunctionTypeDeclaration",
      input: """
        let foo: ((bar: Int, baz: String)) -> Void
        """
    ),
    FormatCase(
      "parensNotRemovedAroundUnlabelledTupleFunctionTypeDeclaration",
      input: """
        let foo: ((Int, String)) -> Void
        """
    ),
    FormatCase(
      "parensNotRemovedAroundTupleFunctionTypeAssignment",
      input: """
        foo = ((bar: Int, baz: String)) -> Void { _ in }
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundTupleFunctionTypeAssignment",
      input: """
        foo = ((((bar: Int, baz: String)))) -> Void { _ in }
        """,
      output: """
        foo = ((bar: Int, baz: String)) -> Void { _ in }
        """
    ),
    FormatCase(
      "parensNotRemovedAroundUnlabelledTupleFunctionTypeAssignment",
      input: """
        foo = ((Int, String)) -> Void { _ in }
        """
    ),
    FormatCase(
      "redundantParensRemovedAroundUnlabelledTupleFunctionTypeAssignment",
      input: """
        foo = ((((Int, String)))) -> Void { _ in }
        """,
      output: """
        foo = ((Int, String)) -> Void { _ in }
        """
    ),
    FormatCase(
      "parensNotRemovedAroundTupleArgument",
      input: """
        foo((bar, baz))
        """
    ),

    // after indexed tuple

    FormatCase(
      "parensNotRemovedAfterTupleIndex",
      input: """
        foo.1()
        """
    ),
    FormatCase(
      "parensNotRemovedAfterTupleIndex2",
      input: """
        foo.1(true)
        """
    ),
    FormatCase(
      "parensNotRemovedAfterTupleIndex3",
      input: """
        foo.1((bar: Int, baz: String))
        """
    ),
    FormatCase(
      "nestedParensRemovedAfterTupleIndex3",
      input: """
        foo.1(((bar: Int, baz: String)))
        """,
      output: """
        foo.1((bar: Int, baz: String))
        """
    ),

    // inside string interpolation

    FormatCase(
      "parensInStringNotRemoved",
      input: """
        \"hello \\(world)\"
        """
    ),

    // around ranges

    FormatCase(
      "parensAroundRangeNotRemoved",
      input: """
        (1 ..< 10).reduce(0, combine: +)
        """
    ),
    FormatCase(
      "parensNotRemovedAroundTrailingRangeFollowedByDot",
      input: """
        (a...).b
        """
    ),
    FormatCase(
      "parensRemovedAroundRangeArgumentBeginningWithDot",
      input: """
        a ... (.b)
        """,
      output: """
        a ... .b
        """
    ),
    FormatCase(
      "parensRemovedAroundRangeArgumentBeginningWithPrefixOperator",
      input: """
        a ... (-b)
        """,
      output: """
        a ... -b
        """
    ),

    // around ternaries

    FormatCase(
      "parensNotRemovedAroundTernaryCondition",
      input: """
        let a = (b == c) ? d : e
        """
    ),
    FormatCase(
      "requiredParensNotRemovedAroundTernaryAssignment",
      input: """
        a ? (b = c) : (b = d)
        """
    ),

    // around parameter repeat each

    FormatCase(
      "requiredParensNotRemovedAroundRepeat",
      input: """
        (repeat (each foo, each bar))
        """
    ),

    // in async expression

    FormatCase(
      "requiredParensNotRemovedInAsyncLet",
      input: """
        Task {
            async let dataTask1: Void = someTask(request)
            async let dataTask2: Void = someTask(request)
        }
        """
    ),
    FormatCase(
      "requiredParensNotRemovedInAsyncLet2",
      input: """
        Task {
            let processURL: (URL) async throws -> Void = { _ in }
        }
        """
    ),
  ]

  @Test(arguments: Self.cases)
  func redundantParens(_ c: FormatCase) {
    testFormatting(for: c.input, c.output, rule: .redundantParens)
  }

  // MARK: - Individual tests

}
