import Testing
@testable import Swiftiomatic

@Suite struct ParsingHelpersTests {
    // MARK: isStartOfClosure

    // types

    @Test func structBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("struct Foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func structWithProtocolBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("struct Foo: Bar {}"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
    }

    @Test func structWithMultipleProtocolsBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("struct Foo: Bar, Baz {}"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
    }

    @Test func classBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("class Foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func protocolBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("protocol Foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func enumBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("enum Foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func extensionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("extension Foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func typeWhereBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("class Foo<T> where T: Equatable {}"))
        #expect(!(formatter.isStartOfClosure(at: 14)))
    }

    @Test func initWhereBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init() where T: Equatable {}"))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    // conditional statements

    @Test func ifBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func ifLetBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if let foo = foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
    }

    @Test func ifCommaBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if foo, bar {}"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
    }

    @Test func ifElseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if foo {} else {}"))
        #expect(!(formatter.isStartOfClosure(at: 9)))
    }

    @Test func ifConditionClosureTreatedAsClosure() {
        let formatter = Formatter(tokenize("""
        if let foo = { () -> Int? in 5 }() {}
        """))
        #expect(formatter.isStartOfClosure(at: 8))
        #expect(!(formatter.isStartOfClosure(at: 26)))
    }

    @Test func ifConditionClosureTreatedAsClosure2() {
        let formatter = Formatter(tokenize("if !foo { bar } {}"))
        #expect(formatter.isStartOfClosure(at: 5))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func ifConditionWithoutSpaceNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if let foo = bar(){}"))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func ifTryAndCallBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if try true && explode() {}"))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    @Test func guardElseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("guard foo else {}"))
        #expect(!(formatter.isStartOfClosure(at: 6)))
    }

    @Test func whileBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("while foo {}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func forInBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("for foo in bar {}"))
        #expect(!(formatter.isStartOfClosure(at: 8)))
    }

    @Test func repeatBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("repeat {} while foo"))
        #expect(!(formatter.isStartOfClosure(at: 2)))
    }

    @Test func doCatchBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("do {} catch Foo.error {}"))
        #expect(!(formatter.isStartOfClosure(at: 2)))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func closureRecognizedInsideGuardCondition() {
        let formatter = Formatter(tokenize("""
        guard let bar = { nil }() else {
            return nil
        }
        """))
        #expect(formatter.isStartOfClosure(at: 8))
        #expect(!(formatter.isStartOfClosure(at: 18)))
    }

    @Test func closureInIfCondition() {
        let formatter = Formatter(tokenize("""
        if let btn = btns.first { !$0.isHidden } {}
        """))
        #expect(formatter.isStartOfClosure(at: 12))
        #expect(!(formatter.isStartOfClosure(at: 21)))
    }

    @Test func closureInIfCondition2() {
        let formatter = Formatter(tokenize("""
        if let foo, let btn = btns.first { !$0.isHidden } {}
        """))
        #expect(formatter.isStartOfClosure(at: 17))
        #expect(!(formatter.isStartOfClosure(at: 26)))
    }

    // functions

    @Test func functionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() { bar = 5 }"))
        #expect(!(formatter.isStartOfClosure(at: 6)))
    }

    @Test func genericFunctionNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<T: Equatable>(_: T) {}"))
        #expect(!(formatter.isStartOfClosure(at: 16)))
    }

    @Test func nonVoidFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> Int {}"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
    }

    @Test func optionalReturningFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> Int? {}"))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func tupleReturningFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> (Int, Bool) {}"))
        #expect(!(formatter.isStartOfClosure(at: 15)))
    }

    @Test func arrayReturningFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> [Int] {}"))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    @Test func nonVoidFunctionAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> Int\n{\n    return 5\n}"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
    }

    @Test func throwingFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() throws { bar = 5 }"))
        #expect(!(formatter.isStartOfClosure(at: 8)))
    }

    @Test func throwingFunctionWithReturnTypeNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() throws -> Bar {}"))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    @Test func functionWithOpaqueReturnTypeNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> any Bar {}"))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    @Test func throwingFunctionWithGenericReturnTypeNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<Baz>() throws -> Bar<Baz> {}"))
        #expect(!(formatter.isStartOfClosure(at: 18)))
    }

    @Test func functionAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo()\n{\n    bar = 5\n}"))
        #expect(!(formatter.isStartOfClosure(at: 6)))
    }

    @Test func functionWithWhereClauseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<U, V>() where T == Result<U, V> {}"))
        #expect(!(formatter.isStartOfClosure(at: 26)))
    }

    @Test func throwingFunctionWithWhereClauseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<U, V>() throws where T == Result<U, V> {}"))
        #expect(!(formatter.isStartOfClosure(at: 28)))
    }

    @Test func closureInForInWhereClauseNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("for foo in foos where foo.method() { print(foo) }"))
        #expect(!(formatter.isStartOfClosure(at: 16)))
    }

    @Test func closureInCaseWhereClause() {
        let formatter = Formatter(tokenize("""
        switch foo {
            case .bar
            where testValues.map(String.init).compactMap { $0 }
            .contains(baz):
                continue
        }
        """))
        #expect(formatter.isStartOfClosure(at: 26))
    }

    @Test func initBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init() { foo = 5 }"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func genericInitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init<T>() { foo = 5 }"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
    }

    @Test func genericOptionalInitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init?<T>() { foo = 5 }"))
        #expect(!(formatter.isStartOfClosure(at: 8)))
    }

    @Test func initAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init()\n{\n    foo = 5\n}"))
        #expect(!(formatter.isStartOfClosure(at: 4)))
    }

    @Test func optionalInitNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init?() { return nil }"))
        #expect(!(formatter.isStartOfClosure(at: 5)))
    }

    @Test func optionalInitAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init?()\n{\n    return nil\n}"))
        #expect(!(formatter.isStartOfClosure(at: 5)))
    }

    @Test func deinitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("deinit { foo = nil }"))
        #expect(!(formatter.isStartOfClosure(at: 2)))
    }

    @Test func deinitAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("deinit\n{\n    foo = nil\n}"))
        #expect(!(formatter.isStartOfClosure(at: 2)))
    }

    @Test func subscriptBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("subscript(i: Int) -> Int { foo[i] }"))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    @Test func subscriptAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("subscript(i: Int) -> Int\n{\n    foo[i]\n}"))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    // accessors

    @Test func computedVarBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int { return 5 }"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
    }

    @Test func computedVarAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int\n{\n    return 5\n}"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
    }

    @Test func varFollowedByBracesOnNextLineTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int\nfoo { return 5 }"))
        #expect(formatter.isStartOfClosure(at: 9))
    }

    @Test func varAssignmentBracesTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo = { return 5 }"))
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func varAssignmentBracesTreatedAsClosure2() {
        let formatter = Formatter(tokenize("var foo = bar { return 5 }"))
        #expect(formatter.isStartOfClosure(at: 8))
    }

    @Test func typedVarAssignmentBracesTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int = { return 5 }"))
        #expect(formatter.isStartOfClosure(at: 9))
    }

    @Test func varDidSetBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int { didSet {} }"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func varDidSetBracesNotTreatedAsClosure2() {
        let formatter = Formatter(tokenize("var foo = bar { didSet {} }"))
        #expect(!(formatter.isStartOfClosure(at: 8)))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    @Test func varDidSetBracesNotTreatedAsClosure3() {
        let formatter = Formatter(tokenize("var foo = bar() { didSet {} }"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
        #expect(!(formatter.isStartOfClosure(at: 14)))
    }

    @Test func varDidSetWithExplicitParamBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int { didSet(old) {} }"))
        #expect(!(formatter.isStartOfClosure(at: 7)))
        #expect(!(formatter.isStartOfClosure(at: 14)))
    }

    @Test func varDidSetWithExplicitParamBracesNotTreatedAsClosure2() {
        let formatter = Formatter(tokenize("var foo: Array<Int> { didSet(old) {} }"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
        #expect(!(formatter.isStartOfClosure(at: 17)))
    }

    @Test func varDidSetWithExplicitParamBracesNotTreatedAsClosure3() {
        let formatter = Formatter(tokenize("var foo = bar { didSet(old) {} }"))
        #expect(!(formatter.isStartOfClosure(at: 8)))
        #expect(!(formatter.isStartOfClosure(at: 15)))
    }

    @Test func varDidSetWithExplicitParamBracesNotTreatedAsClosure4() {
        let formatter = Formatter(tokenize("var foo = bar() { didSet(old) {} }"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
        #expect(!(formatter.isStartOfClosure(at: 17)))
    }

    @Test func varDidSetWithExplicitParamBracesNotTreatedAsClosure5() {
        let formatter = Formatter(tokenize("var foo = [5] { didSet(old) {} }"))
        #expect(!(formatter.isStartOfClosure(at: 10)))
        #expect(!(formatter.isStartOfClosure(at: 17)))
    }

    // chained closures

    @Test func chainedTrailingClosureInVarChain() {
        let formatter = Formatter(tokenize("var foo = bar.baz { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 10))
        #expect(formatter.isStartOfClosure(at: 18))
    }

    @Test func chainedTrailingClosureInVarChain2() {
        let formatter = Formatter(tokenize("var foo = bar().baz { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 12))
        #expect(formatter.isStartOfClosure(at: 20))
    }

    @Test func chainedTrailingClosureInVarChain3() {
        let formatter = Formatter(tokenize("var foo = bar.baz() { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 12))
        #expect(formatter.isStartOfClosure(at: 20))
    }

    @Test func chainedTrailingClosureInLetChain() {
        let formatter = Formatter(tokenize("let foo = bar.baz { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 10))
        #expect(formatter.isStartOfClosure(at: 18))
    }

    @Test func chainedTrailingClosureInTypedVarChain() {
        let formatter = Formatter(tokenize("var foo: Int = bar.baz { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 13))
        #expect(formatter.isStartOfClosure(at: 21))
    }

    @Test func chainedTrailingClosureInTypedVarChain2() {
        let formatter = Formatter(tokenize("var foo: Int = bar().baz { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 15))
        #expect(formatter.isStartOfClosure(at: 23))
    }

    @Test func chainedTrailingClosureInTypedVarChain3() {
        let formatter = Formatter(tokenize("var foo: Int = bar.baz() { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 15))
        #expect(formatter.isStartOfClosure(at: 23))
    }

    @Test func chainedTrailingClosureInTypedLetChain() {
        let formatter = Formatter(tokenize("let foo: Int = bar.baz { 5 }.quux { 6 }"))
        #expect(formatter.isStartOfClosure(at: 13))
        #expect(formatter.isStartOfClosure(at: 21))
    }

    // async / await

    @Test func asyncClosure() {
        let formatter = Formatter(tokenize("{ (foo) async in foo }"))
        #expect(formatter.isStartOfClosure(at: 0))
    }

    @Test func asyncClosure2() {
        let formatter = Formatter(tokenize("{ foo async in foo }"))
        #expect(formatter.isStartOfClosure(at: 0))
    }

    @Test func functionNamedAsync() {
        let formatter = Formatter(tokenize("foo = async { bar }"))
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func awaitClosure() {
        let formatter = Formatter(tokenize("foo = await { bar }"))
        #expect(formatter.isStartOfClosure(at: 6))
    }

    // edge cases

    @Test func multipleNestedTrailingClosures() {
        let repeatCount = 2
        let formatter = Formatter(tokenize("""
        override func foo() {
        bar {
        var baz = 5
        \(String(repeating: """
        fizz {
        buzz {
        fizzbuzz()
        }
        }

        """, count: repeatCount))}
        }
        """))
        #expect(!(formatter.isStartOfClosure(at: 8)))
        #expect(formatter.isStartOfClosure(at: 12))
        for i in stride(from: 0, to: repeatCount * 16, by: 16) {
            #expect(formatter.isStartOfClosure(at: 24 + i))
            #expect(formatter.isStartOfClosure(at: 28 + i))
        }
    }

    @Test func wrappedClosureAfterAnIfStatement() {
        let formatter = Formatter(tokenize("""
        if foo {}
        bar
            .baz {}
        """))
        #expect(formatter.isStartOfClosure(at: 13))
    }

    @Test func wrappedClosureAfterSwitch() {
        let formatter = Formatter(tokenize("""
        switch foo {
        default:
            break
        }
        bar
            .map {
                // baz
            }
        """))
        #expect(formatter.isStartOfClosure(at: 20))
    }

    @Test func closureInsideIfCondition() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), { x == y }() {}
        """))
        #expect(formatter.isStartOfClosure(at: 13))
        #expect(!(formatter.isStartOfClosure(at: 25)))
    }

    @Test func closureInsideIfCondition2() {
        let formatter = Formatter(tokenize("""
        if foo == bar.map { $0.baz }.sorted() {}
        """))
        #expect(formatter.isStartOfClosure(at: 10))
        #expect(!(formatter.isStartOfClosure(at: 22)))
    }

    @Test func closureInsideIfCondition3() {
        let formatter = Formatter(tokenize("""
        if baz, let foo = bar(), { x == y }() {}
        """))
        #expect(formatter.isStartOfClosure(at: 16))
        #expect(!(formatter.isStartOfClosure(at: 28)))
    }

    @Test func closureAfterGenericType() {
        let formatter = Formatter(tokenize("let foo = Foo<String> {}"))
        #expect(formatter.isStartOfClosure(at: 11))
    }

    @Test func allmanClosureAfterFunction() {
        let formatter = Formatter(tokenize("""
        func foo() {}
        Foo
            .baz
            {
                baz()
            }
        """))
        #expect(formatter.isStartOfClosure(at: 16))
    }

    @Test func genericInitializerTrailingClosure() {
        let formatter = Formatter(tokenize("""
        Foo<Bar>(0) { [weak self]() -> Void in }
        """))
        #expect(formatter.isStartOfClosure(at: 8))
    }

    @Test func parameterBodyAfterStringIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: String = "bar" {
            didSet { print("didSet") }
        }
        """))
        #expect(!(formatter.isStartOfClosure(at: 13)))
    }

    @Test func parameterBodyAfterMultilineStringIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: String = \"\""
        bar
        \"\"" {
            didSet { print("didSet") }
        }
        """))
        #expect(!(formatter.isStartOfClosure(at: 15)))
    }

    @Test func parameterBodyAfterNumberIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: Int = 10 {
            didSet { print("didSet") }
        }
        """))
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func parameterBodyAfterClosureIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: () -> String = { "bar" } {
            didSet { print("didSet") }
        }
        """))
        #expect(!(formatter.isStartOfClosure(at: 22)))
    }

    @Test func parameterBodyAfterExecutedClosureIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: String = { "bar" }() {
            didSet { print("didSet") }
        }
        """))
        #expect(!(formatter.isStartOfClosure(at: 19)))
    }

    @Test func mainActorClosure() {
        let formatter = Formatter(tokenize("""
        let foo = { @MainActor in () }
        """))
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func throwingClosure() {
        let formatter = Formatter(tokenize("""
        let foo = { bar throws in bar }
        """))
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func typedThrowingClosure() {
        let formatter = Formatter(tokenize("""
        let foo = { bar throws(Foo) in bar }
        """))
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func nestedTypedThrowingClosures() {
        let formatter = Formatter(tokenize("""
        try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in
            try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in }
        }
        """))
        #expect(formatter.isStartOfClosure(at: 15))
        #expect(formatter.isStartOfClosure(at: 42))
    }

    @Test func trailingClosureOnOptionalMethod() {
        let formatter = Formatter(tokenize("""
        foo.bar? { print("") }
        """))
        #expect(formatter.isStartOfClosure(at: 5))
    }

    @Test func braceAfterTypedThrows() {
        let formatter = Formatter(tokenize("""
        do throws(Foo) {} catch {}
        """))
        #expect(!(formatter.isStartOfClosure(at: 7)))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

    // MARK: isConditionalStatement

    @Test func ifConditionContainingClosure() {
        let formatter = Formatter(tokenize("""
        if let btn = btns.first { !$0.isHidden } {}
        """))
        #expect(formatter.isConditionalStatement(at: 12))
        #expect(formatter.isConditionalStatement(at: 21))
    }

    @Test func ifConditionContainingClosure2() {
        let formatter = Formatter(tokenize("""
        if let foo, let btn = btns.first { !$0.isHidden } {}
        """))
        #expect(formatter.isConditionalStatement(at: 17))
        #expect(formatter.isConditionalStatement(at: 26))
    }

    // MARK: isAccessorKeyword

    @Test func didSet() {
        let formatter = Formatter(tokenize("var foo: Int { didSet {} }"))
        #expect(formatter.isAccessorKeyword(at: 9))
    }

    @Test func didSetWillSet() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            didSet {}
            willSet {}
        }
        """))
        #expect(formatter.isAccessorKeyword(at: 10))
        #expect(formatter.isAccessorKeyword(at: 16))
    }

    @Test func getSet() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            get { return _foo }
            set { _foo = newValue }
        }
        """))
        #expect(formatter.isAccessorKeyword(at: 10))
        #expect(formatter.isAccessorKeyword(at: 21))
    }

    @Test func setGet() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            set { _foo = newValue }
            get { return _foo }
        }
        """))
        #expect(formatter.isAccessorKeyword(at: 10))
        #expect(formatter.isAccessorKeyword(at: 23))
    }

    @Test func genericSubscriptSetGet() {
        let formatter = Formatter(tokenize("""
        subscript<T>(index: Int) -> T {
            set { _foo[index] = newValue }
            get { return _foo[index] }
        }
        """))
        #expect(formatter.isAccessorKeyword(at: 18))
        #expect(formatter.isAccessorKeyword(at: 34))
    }

    @Test func init() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            init {}
            get {}
            set {}
        }
        """))
        #expect(formatter.isAccessorKeyword(at: 10))
        #expect(formatter.isAccessorKeyword(at: 16))
    }

    @Test func notGetter() {
        let formatter = Formatter(tokenize("""
        func foo() {
            set { print("") }
        }
        """))
        #expect(!(formatter.isAccessorKeyword(at: 9)))
    }

    @Test func functionInGetterPosition() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            `get`()
            return 5
        }
        """))
        #expect(formatter.isAccessorKeyword(at: 10, checkKeyword: false))
    }

    @Test func notSetterInit() {
        let formatter = Formatter(tokenize("""
        class Foo {
            init() { print("") }
        }
        """))
        #expect(!(formatter.isAccessorKeyword(at: 7)))
    }

    // MARK: isEnumCase

    @Test func isEnumCase() {
        let formatter = Formatter(tokenize("""
        enum Foo {
            case foo, bar
            case baz
        }
        """))
        #expect(formatter.isEnumCase(at: 7))
        #expect(formatter.isEnumCase(at: 15))
    }

    @Test func isEnumCaseWithValue() {
        let formatter = Formatter(tokenize("""
        enum Foo {
            case foo, bar(Int)
            case baz
        }
        """))
        #expect(formatter.isEnumCase(at: 7))
        #expect(formatter.isEnumCase(at: 18))
    }

    @Test func isNotEnumCase() {
        let formatter = Formatter(tokenize("""
        if case let .foo(bar) = baz {}
        """))
        #expect(!(formatter.isEnumCase(at: 2)))
    }

    @Test func typoIsNotEnumCase() {
        let formatter = Formatter(tokenize("""
        if let case .foo(bar) = baz {}
        """))
        #expect(!(formatter.isEnumCase(at: 4)))
    }

    @Test func mixedCaseTypes() {
        let formatter = Formatter(tokenize("""
        enum Foo {
            case foo
            case bar(value: [Int])
        }

        func baz() {
            if case .foo = foo,
               case .bar(let value) = bar,
               value.isEmpty {}
        }
        """))
        #expect(formatter.isEnumCase(at: 7))
        #expect(formatter.isEnumCase(at: 12))
        #expect(!(formatter.isEnumCase(at: 38)))
        #expect(!(formatter.isEnumCase(at: 49)))
    }

    // MARK: modifierOrder

    @Test func modifierOrder() {
        let options = FormatOptions(modifierOrder: ["convenience", "override"])
        let formatter = Formatter([], options: options)
        #expect(formatter.preferredModifierOrder == [
            "private", "fileprivate", "internal", "package", "public", "open",
            "private(set)", "fileprivate(set)", "internal(set)", "package(set)", "public(set)", "open(set)",
            "final",
            "dynamic",
            "optional", "required",
            "convenience",
            "override",
            "indirect",
            "isolated", "nonisolated", "nonisolated(unsafe)",
            "lazy",
            "weak", "unowned", "unowned(safe)", "unowned(unsafe)",
            "static", "class",
            "borrowing", "consuming", "mutating", "nonmutating",
            "prefix", "infix", "postfix",
            "async",
        ])
    }

    @Test func modifierOrder2() {
        let options = FormatOptions(modifierOrder: [
            "override", "acl", "setterACL", "dynamic", "mutators",
            "lazy", "final", "required", "convenience", "typeMethods", "owned",
        ])
        let formatter = Formatter([], options: options)
        #expect(formatter.preferredModifierOrder == [
            "override",
            "private", "fileprivate", "internal", "package", "public", "open",
            "private(set)", "fileprivate(set)", "internal(set)", "package(set)", "public(set)", "open(set)",
            "dynamic",
            "indirect",
            "isolated", "nonisolated", "nonisolated(unsafe)",
            "static", "class",
            "borrowing", "consuming", "mutating", "nonmutating",
            "lazy",
            "final",
            "optional", "required",
            "convenience",
            "weak", "unowned", "unowned(safe)", "unowned(unsafe)",
            "prefix", "infix", "postfix",
            "async",
        ])
    }

    // MARK: startOfModifiers

    @Test func startOfModifiers() {
        let formatter = Formatter(tokenize("""
        class Foo { @objc public required init() {} }
        """))
        #expect(formatter.startOfModifiers(at: 12, includingAttributes: false) == 8)
    }

    @Test func startOfModifiersIncludingNonisolated() {
        let formatter = Formatter(tokenize("""
        actor Foo { nonisolated public func foo() {} }
        """))
        #expect(formatter.startOfModifiers(at: 10, includingAttributes: true) == 6)
    }

    @Test func startOfModifiersIncludingAttributes() {
        let formatter = Formatter(tokenize("""
        class Foo { @objc public required init() {} }
        """))
        #expect(formatter.startOfModifiers(at: 12, includingAttributes: true) == 6)
    }

    @Test func startOfPropertyModifiers() {
        let formatter = Formatter(tokenize("""
        @objc public class override var foo: Int?
        """))
        #expect(formatter.startOfModifiers(at: 6, includingAttributes: true) == 0)
    }

    @Test func startOfPropertyModifiers2() {
        let formatter = Formatter(tokenize("""
        @objc(SFFoo) public var foo: Int?
        """))
        #expect(formatter.startOfModifiers(at: 7, includingAttributes: false) == 5)
    }

    @Test func startOfPropertyModifiers3() {
        let formatter = Formatter(tokenize("""
        @OuterType.Wrapper var foo: Int?
        """))
        #expect(formatter.startOfModifiers(at: 4, includingAttributes: true) == 0)
    }

    // MARK: processDeclaredVariables

    @Test func processCommaDelimitedDeclaredVariables() {
        let formatter = Formatter(tokenize("""
        let foo = bar(), x = y, baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "x", "baz"])
        #expect(index == 22)
    }

    @Test func processDeclaredVariablesInIfCondition() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), x == y, let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "baz"])
        #expect(index == 26)
    }

    @Test func processDeclaredVariablesInIfWithParenthetical() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), (x == y), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "baz"])
        #expect(index == 28)
    }

    @Test func processDeclaredVariablesInIfWithClosure() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), { x == y }(), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "baz"])
        #expect(index == 32)
    }

    @Test func processDeclaredVariablesInIfWithNamedClosureArgument() {
        let formatter = Formatter(tokenize("""
        if let foo = bar, foo.bar(baz: { $0 }), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "baz"])
        #expect(index == 32)
    }

    @Test func processDeclaredVariablesInIfAfterCase() {
        let formatter = Formatter(tokenize("""
        if case let .foo(bar, .baz(quux: 5)) = foo, let baz2 = quux2 {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar", "baz2"])
        #expect(index == 33)
    }

    @Test func processDeclaredVariablesInIfWithArrayLiteral() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), [x] == y, let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "baz"])
        #expect(index == 28)
    }

    @Test func processDeclaredVariablesInIfLetAs() {
        let formatter = Formatter(tokenize("""
        if let foo = foo as? String, let bar = baz {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "bar"])
        #expect(index == 22)
    }

    @Test func processDeclaredVariablesInIfLetWithPostfixOperator() {
        let formatter = Formatter(tokenize("""
        if let foo = baz?.foo, let bar = baz?.bar {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "bar"])
        #expect(index == 23)
    }

    @Test func processCaseDeclaredVariablesInIfLetCommaCase() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), case .bar(var baz) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo", "baz"])
        #expect(index == 25)
    }

    @Test func processCaseDeclaredVariablesInIfCaseLet() {
        let formatter = Formatter(tokenize("""
        if case let .foo(a: bar, b: baz) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar", "baz"])
        #expect(index == 23)
    }

    @Test func processTupleDeclaredVariablesInIfLetSyntax() {
        let formatter = Formatter(tokenize("""
        if let (bar, a: baz) = quux, let x = y {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["x", "bar", "baz"])
        #expect(index == 25)
    }

    @Test func processTupleDeclaredVariablesInIfLetSyntax2() {
        let formatter = Formatter(tokenize("""
        if let ((a: bar, baz), (x, y)) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar", "baz", "x", "y"])
        #expect(index == 26)
    }

    @Test func processAwaitVariableInForLoop() {
        let formatter = Formatter(tokenize("""
        for await foo in DoubleGenerator() {
            print(foo)
        }
        """))
        var index = 0
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo"])
        #expect(index == 4)
    }

    @Test func processParametersInInit() {
        let formatter = Formatter(tokenize("""
        init(actor: Int, bar: String) {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["actor", "bar"])
        #expect(index == 11)
    }

    @Test func processGuardCaseLetVariables() {
        let formatter = Formatter(tokenize("""
        guard case let Foo.bar(foo) = baz
        else { return }
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo"])
        #expect(index == 15)
    }

    @Test func processLetDictionaryLiteralVariables() {
        let formatter = Formatter(tokenize("""
        let foo = [bar: 1, baz: 2]
        print(foo)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["foo"])
        #expect(index == 17)
    }

    @Test func processLetStringLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar = "bar"
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar"])
        #expect(index == 8)
    }

    @Test func processLetNumericLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar = 5
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar"])
        #expect(index == 6)
    }

    @Test func processLetBooleanLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar = true
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar"])
        #expect(index == 6)
    }

    @Test func processLetNilLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar: Bar? = nil
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        #expect(names == ["bar"])
        #expect(index == 10)
    }

    // MARK: parseDeclarations

    @Test func parseDeclarations() {
        let input = """
        import CoreGraphics
        import Foundation

        let global = 10

        @objc
        @available(iOS 13.0, *)
        @propertyWrapper("parameter")
        weak var multilineGlobal = ["string"]
            .map(\\.count)
        let anotherGlobal = "hello"

        /// Doc comment
        /// (multiple lines)
        func globalFunction() {
            print("hi")
        }

        protocol SomeProtocol {
            var getter: String { get async throws }
            func protocolMethod() -> Bool
        }

        class SomeClass {

            enum NestedEnum {
                /// Doc comment
                case bar
                func test() {}
            }

            /*
             * Block comment
             */

            private(set)
            var instanceVar = "test" // trailing comment

            @_silgen_name("__MARKER_functionWithNoBody")
            func functionWithNoBody(_ x: String) -> Int?

            @objc
            private var computed: String {
                get {
                    "computed string"
                }
            }

        }

        struct EmptyType {}

        struct Test{let foo: String}

        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].tokens.string == """
            import CoreGraphics

            """)

        #expect(declarations[1].tokens.string == """
            import Foundation


            """)

        #expect(declarations[2].tokens.string == """
            let global = 10


            """)

        #expect(declarations[3].tokens.string == """
            @objc
            @available(iOS 13.0, *)
            @propertyWrapper("parameter")
            weak var multilineGlobal = ["string"]
                .map(\\.count)

            """)

        #expect(declarations[4].tokens.string == """
            let anotherGlobal = "hello"


            """)

        #expect(declarations[5].tokens.string == """
            /// Doc comment
            /// (multiple lines)
            func globalFunction() {
                print("hi")
            }


            """)

        #expect(declarations[6].tokens.string == """
            protocol SomeProtocol {
                var getter: String { get async throws }
                func protocolMethod() -> Bool
            }


            """)

        #expect(declarations[6].body?[0].tokens.string == """
                var getter: String { get async throws }

            """)

        #expect(declarations[6].body?[1].tokens.string == """
                func protocolMethod() -> Bool

            """)

        #expect(declarations[7].tokens.string == """
            class SomeClass {

                enum NestedEnum {
                    /// Doc comment
                    case bar
                    func test() {}
                }

                /*
                 * Block comment
                 */

                private(set)
                var instanceVar = "test" // trailing comment

                @_silgen_name("__MARKER_functionWithNoBody")
                func functionWithNoBody(_ x: String) -> Int?

                @objc
                private var computed: String {
                    get {
                        "computed string"
                    }
                }

            }


            """)

        #expect(declarations[7].body?[0].tokens.string == """
                enum NestedEnum {
                    /// Doc comment
                    case bar
                    func test() {}
                }


            """)

        #expect(declarations[7].body?[0].body?[0].tokens.string == """
                    /// Doc comment
                    case bar

            """)

        #expect(declarations[7].body?[0].body?[1].tokens.string == """
                    func test() {}

            """)

        #expect(declarations[7].body?[1].tokens.string == """
                /*
                 * Block comment
                 */

                private(set)
                var instanceVar = "test" // trailing comment


            """)

        #expect(declarations[7].body?[2].tokens.string == """
                @_silgen_name(\"__MARKER_functionWithNoBody\")
                func functionWithNoBody(_ x: String) -> Int?


            """)

        #expect(declarations[7].body?[3].tokens.string == """
                @objc
                private var computed: String {
                    get {
                        "computed string"
                    }
                }


            """)

        #expect(declarations[8].tokens.string == """
            struct EmptyType {}


            """)

        #expect(declarations[9].tokens.string == """
            struct Test{let foo: String}

            """)

        #expect(declarations[9].body?[0].tokens.string == """
            let foo: String
            """)
    }

    @Test func parseClassFuncDeclarationCorrectly() {
        // `class func` is one of the few cases (possibly only!)
        // where a declaration will have more than one declaration token
        let input = """
        class Foo() {}

        class func foo() {}
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].keyword == "class")
        #expect(declarations[1].keyword == "func")
    }

    @Test func parseMarkCommentsCorrectly() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init(json: JSONObject) throws {
                bar = try json.value(for: "bar")
                baz = try json.value(for: "baz")
            }

            // MARK: Internal

            let bar: String
            var baz: Int?

        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].keyword == "class")
        #expect(declarations[0].body?[0].keyword == "init")
        #expect(declarations[0].body?[1].keyword == "let")
        #expect(declarations[0].body?[2].keyword == "var")
    }

    @Test func parseTrailingCommentsCorrectly() {
        let input = """
        struct Foo {
            var bar = "bar"
            /// Leading comment
            public var baz = "baz" // Trailing comment
            var quux = "quux"
        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].body?[0].tokens.string == """
                var bar = "bar"

            """)

        #expect(declarations[0].body?[0].tokens.string == """
                var bar = "bar"

            """)

        #expect(declarations[0].body?[1].tokens.string == """
                /// Leading comment
                public var baz = "baz" // Trailing comment

            """)

        #expect(declarations[0].body?[2].tokens.string == """
                var quux = "quux"

            """)
    }

    @Test func parseDeclarationsWithSituationalKeywords() {
        let input = """
        let `static` = NavigationBarType.static(nil, .none)
        let foo = bar
        let `static` = NavigationBarType.static
        let bar = foo
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].tokens.string == """
            let `static` = NavigationBarType.static(nil, .none)

            """)

        #expect(declarations[1].tokens.string == """
            let foo = bar

            """)

        #expect(declarations[2].tokens.string == """
            let `static` = NavigationBarType.static

            """)

        #expect(declarations[3].tokens.string == """
            let bar = foo
            """)
    }

    @Test func parseSimpleCompilationBlockCorrectly() {
        let input = """
        #if DEBUG
        struct DebugFoo {
            let bar = "debug"
        }
        #endif
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].keyword, "#if" != nil)
        #expect(declarations[0].body?[0].keyword == "struct")
        #expect(declarations[0].body?[0].body?[0].keyword == "let")
    }

    @Test func parseSimpleNestedCompilationBlockCorrectly() {
        let input = """
        #if canImport(UIKit)
        #if DEBUG
        struct DebugFoo {
            let bar = "debug"
        }
        #endif
        #endif
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].keyword, "#if" != nil)
        #expect(declarations[0].body?[0].keyword == "#if")
        #expect(declarations[0].body?[0].body?[0].keyword == "struct")
        #expect(declarations[0].body?[0].body?[0].body?[0].keyword == "let")
    }

    @Test func parseComplexConditionalCompilationBlockCorrectly() {
        let input = """
        let beforeBlock = "baz"

        #if DEBUG
        struct DebugFoo {
            let bar = "debug"
        }
        #elseif BETA
        struct BetaFoo {
            let bar = "beta"
        }
        #else
        struct ProductionFoo {
            let bar = "production"
        }
        #endif

        #if EMPTY_BLOCK
        #endif

        let afterBlock = "quux"
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].keyword == "let")
        #expect(declarations[1].keyword == "#if")
        #expect(declarations[1].body?[0].keyword == "struct")
        #expect(declarations[1].body?[1].keyword == "struct")
        #expect(declarations[1].body?[2].keyword == "struct")
        #expect(declarations[2].keyword == "#if")
        #expect(declarations[3].keyword == "let")
    }

    @Test func parseSymbolImportCorrectly() {
        let input = """
        import protocol SomeModule.SomeProtocol
        import class SomeModule.SomeClass
        import enum SomeModule.SomeEnum
        import struct SomeModule.SomeStruct
        import typealias SomeModule.SomeTypealias
        import let SomeModule.SomeGlobalConstant
        import var SomeModule.SomeGlobalVariable
        import func SomeModule.SomeFunc

        struct Foo {
            init() {}
            public func instanceMethod() {}
        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        #expect(declarations[0].keyword == "import")
        #expect(declarations[1].keyword == "import")
        #expect(declarations[2].keyword == "import")
        #expect(declarations[3].keyword == "import")
        #expect(declarations[4].keyword == "import")
        #expect(declarations[5].keyword == "import")
        #expect(declarations[6].keyword == "import")
        #expect(declarations[7].keyword == "import")
        #expect(declarations[8].keyword == "struct")
        #expect(declarations[8].body?[0].keyword == "init")
        #expect(declarations[8].body?[1].keyword == "func")
    }

    @Test func classOverrideDoesntCrashParseDeclarations() {
        let input = """
        class Foo {
            var bar: Int?
            class override var baz: String
        }
        """
        let tokens = tokenize(input)
        _ = Formatter(tokens).parseDeclarations()
    }

    @Test func parseDeclarationRangesInType() throws {
        let input = """
        class Foo {
            let bar = "bar"
            let baaz = "baaz"
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        #expect(declarations.count == 1)
        #expect(declarations[0].range == 0 ... 28)

        #expect(declarations[0].body?.count == 2)

        let barDeclarationRange = try #require(declarations[0].body?[0].range)
        #expect(barDeclarationRange == 6 ... 16)
        #expect(formatter.tokens[barDeclarationRange].string == "    let bar = \"bar\"\n")

        let baazDeclarationRange = try #require(declarations[0].body?[1].range)
        #expect(baazDeclarationRange == 17 ... 27)
        #expect(formatter.tokens[baazDeclarationRange].string == "    let baaz = \"baaz\"\n")
    }

    @Test func parseDeclarationRangesInConditionalCompilation() throws {
        let input = """
        #if DEBUG
        let bar = "bar"
        let baaz = "baaz"
        #endif
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        #expect(declarations.count == 1)
        #expect(declarations[0].range == 0 ... 24)
        #expect(declarations[0].tokens.map(\.string).joined() == input)

        #expect(declarations[0].body?.count == 2)

        let barDeclarationRange = try #require(declarations[0].body?[0].range)
        #expect(barDeclarationRange == 4 ... 13)
        #expect(formatter.tokens[barDeclarationRange].string == "let bar = \"bar\"\n")

        let baazDeclarationRange = try #require(declarations[0].body?[1].range)
        #expect(baazDeclarationRange == 14 ... 23)
        #expect(formatter.tokens[baazDeclarationRange].string == "let baaz = \"baaz\"\n")
    }

    @Test func parseConditionalCompilationWithNoInnerDeclarations() {
        let input = """
        struct Foo {
            // This type is empty
        }
        extension Foo {
            // This extension is empty
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()
        #expect(declarations.count == 2)

        #expect(declarations[0].tokens.map(\.string).joined() == """
            struct Foo {
                // This type is empty
            }

            """)

        #expect(declarations[1].tokens.map(\.string).joined() == """
            extension Foo {
                // This extension is empty
            }
            """)
    }

    @Test func parseConditionalCompilationWithArgument() {
        let input = """
        #if os(Linux)
        #error("Linux is currently not supported")
        #endif
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()
        #expect(declarations.count == 1)
        #expect(declarations[0].tokens.map(\.string).joined() == input)
    }

    @Test func parseIfExpressionDeclaration() {
        let input = """
        private lazy var x: [Any] =
          if let b {
            [b]
          } else if false {
            []
          } else {
            [1, 2]
          }

        private lazy var y = f()
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()
        #expect(declarations.count == 2)

        #expect(declarations[0].tokens.string == """
        private lazy var x: [Any] =
          if let b {
            [b]
          } else if false {
            []
          } else {
            [1, 2]
          }


        """)

        #expect(declarations[1].tokens.string == "private lazy var y = f()")
    }

    @Test func parseDeclarationsWithMalformedTypes() {
        let input = """
        extension Foo {
            /// Invalid type, should still get handled properly
            private var foo: FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }
        }

        extension Foo {
            /// Invalid type, should still get handled properly
            func foo() -> FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }

            func bar() {}
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()
        #expect(declarations.count == 2)
        #expect(declarations[0].body?.count == 1)
        #expect(declarations[1].body?.count == 2)

        #expect(declarations[0].body?[0].tokens.string == """
            /// Invalid type, should still get handled properly
            private var foo: FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }

        """)

        #expect(declarations[1].body?[0].tokens.string == """
            /// Invalid type, should still get handled properly
            func foo() -> FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }


        """)
    }

    // MARK: declarationScope

    @Test func declarationScope_classAndGlobals() {
        let input = """
        let foo = Foo()

        class Foo {
            let instanceMember = Bar()
        }

        let bar = Bar()
        """

        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        #expect(formatter.declarationScope(at: 3) == .global) // foo
        #expect(formatter.declarationScope(at: 20) == .type) // instanceMember
        #expect(formatter.declarationScope(at: 33) == .global) // bar
    }

    @Test func declarationScope_classAndLocal() {
        let input = """
        class Foo {
            let instanceMember1 = Bar()

            var instanceMember2: Bar = {
                Bar()
            }

            func instanceMethod() {
                let localMember1 = Bar()
            }

            let instanceMember3 = Bar()

            let instanceMemberClosure = Foo {
                let localMember2 = Bar()
            }
        }
        """

        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        #expect(formatter.declarationScope(at: 9) == .type) // instanceMember1
        #expect(formatter.declarationScope(at: 21) == .type) // instanceMember2
        #expect(formatter.declarationScope(at: 31) == .local) // Bar()
        #expect(formatter.declarationScope(at: 42) == .type) // instanceMethod
        #expect(formatter.declarationScope(at: 51) == .local) // localMember1
        #expect(formatter.declarationScope(at: 66) == .type) // instanceMember3
        #expect(formatter.declarationScope(at: 78) == .type) // instanceMemberClosure
        #expect(formatter.declarationScope(at: 89) == .local) // localMember2
    }

    @Test func declarationScope_protocol() {
        let input = """
        protocol Bar {
            var foo { get }
        }
        """

        let formatter = Formatter(tokenize(input))
        #expect(formatter.declarationScope(at: 7) == .type)
    }

    @Test func declarationScope_doCatch() {
        let input = """
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            return error
        }
        """

        let formatter = Formatter(tokenize(input))
        #expect(formatter.declarationScope(at: 5) == .local)
    }

    @Test func declarationScope_ifLet() {
        let input = """
        if let foo = bar {
            return foo
        }
        """

        let formatter = Formatter(tokenize(input))
        #expect(formatter.declarationScope(at: 2) == .local)
    }

    // MARK: spaceEquivalentToWidth

    @Test func spaceEquivalentToWidth() {
        let formatter = Formatter([])
        #expect(formatter.spaceEquivalentToWidth(10) == "          ")
    }

    @Test func spaceEquivalentToWidthWithTabs() {
        let options = FormatOptions(indent: "\t", tabWidth: 4, smartTabs: false)
        let formatter = Formatter([], options: options)
        #expect(formatter.spaceEquivalentToWidth(10) == "\t\t  ")
    }

    // MARK: spaceEquivalentToTokens

    @Test func spaceEquivalentToCode() {
        let tokens = tokenize("let a = b + c")
        let formatter = Formatter(tokens)
        #expect(formatter.spaceEquivalentToTokens(from: 0, upTo: tokens.count) == "             ")
    }

    @Test func spaceEquivalentToImageLiteral() {
        let tokens = tokenize("let a = #imageLiteral(resourceName: \"abc.png\")")
        let formatter = Formatter(tokens)
        #expect(formatter.spaceEquivalentToTokens(from: 0, upTo: tokens.count) == "          ")
    }

    // MARK: startOfConditionalStatement

    @Test func ifTreatedAsConditional() {
        let formatter = Formatter(tokenize("if bar == baz {}"))
        for i in formatter.tokens.indices.dropLast(2) {
            #expect(formatter.startOfConditionalStatement(at: i) == 0)
        }
    }

    @Test func ifLetTreatedAsConditional() {
        let formatter = Formatter(tokenize("if let bar = baz {}"))
        for i in formatter.tokens.indices.dropLast(2) {
            #expect(formatter.startOfConditionalStatement(at: i) == 0)
        }
    }

    @Test func guardLetTreatedAsConditional() {
        let formatter = Formatter(tokenize("guard let foo = bar else {}"))
        for i in formatter.tokens.indices.dropLast(4) {
            #expect(formatter.startOfConditionalStatement(at: i) == 0)
        }
    }

    @Test func letNotTreatedAsConditional() {
        let formatter = Formatter(tokenize("let foo = bar, bar = baz"))
        for i in formatter.tokens.indices {
            #expect(formatter.startOfConditionalStatement(at: i == nil))
        }
    }

    @Test func enumCaseNotTreatedAsConditional() {
        let formatter = Formatter(tokenize("enum Foo { case bar }"))
        for i in formatter.tokens.indices {
            #expect(formatter.startOfConditionalStatement(at: i == nil))
        }
    }

    @Test func startOfConditionalStatementConditionContainingUnParenthesizedClosure() {
        let formatter = Formatter(tokenize("""
        if let btn = btns.first { !$0.isHidden } {}
        """))
        #expect(formatter.startOfConditionalStatement(at: 12) == 0)
        #expect(formatter.startOfConditionalStatement(at: 21) == 0)
    }

    // MARK: isStartOfStatement

    @Test func asyncAfterFuncNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        func foo()
            async
        """))
        #expect(!(formatter.isStartOfStatement(at: 7)))
    }

    @Test func asyncLetTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        async let foo = bar()
        """))
        #expect(formatter.isStartOfStatement(at: 0))
    }

    @Test func asyncIdentifierTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        func async() {}
        async()
        """))
        #expect(formatter.isStartOfStatement(at: 9))
    }

    @Test func asyncIdentifierNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        func async() {}
        let foo =
            async()
        """))
        #expect(!(formatter.isStartOfStatement(at: 16)))
    }

    @Test func numericFunctionArgumentNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        let foo = bar(
            200
        )
        """))
        #expect(!(formatter.isStartOfStatement(at: 10, treatingCollectionKeysAsStart: false)))
    }

    @Test func stringLiteralFunctionArgumentNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        let foo = bar(
            "baz"
        )
        """))
        #expect(!(formatter.isStartOfStatement(at: 10, treatingCollectionKeysAsStart: false)))
    }

    // MARK: - parseTypes

    @Test func parseSimpleType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo = .init()
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo")
    }

    @Test func parseOptionalType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo??? = .init()
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo???")
    }

    @Test func parseIOUType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo!! = .init()
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo!!")
    }

    @Test func doesntParseTernaryOperatorAsType() {
        let formatter = Formatter(tokenize("""
        Foo.bar ? .foo : .bar
        """))
        #expect(formatter.parseType(at: 0)?.string == "Foo.bar")
    }

    @Test func doesntParseMacroInvocationAsType() {
        let formatter = Formatter(tokenize("""
        let foo = #colorLiteral(1, 2, 3)
        """))
        #expect(formatter.parseType(at: 6 == nil))
    }

    @Test func doesntParseSelectorAsType() {
        let formatter = Formatter(tokenize("""
        let foo = #selector(Foo.bar)
        """))
        #expect(formatter.parseType(at: 6 == nil))
    }

    @Test func doesntParseArrayAsType() {
        let formatter = Formatter(tokenize("""
        let foo = [foo, bar].member()
        """))
        #expect(formatter.parseType(at: 6 == nil))
    }

    @Test func doesntParseDictionaryAsType() {
        let formatter = Formatter(tokenize("""
        let foo = [foo: bar, baaz: quux].member()
        """))
        #expect(formatter.parseType(at: 6 == nil))
    }

    @Test func parsesArrayAsType() {
        let formatter = Formatter(tokenize("""
        let foo = [Foo]()
        """))
        #expect(formatter.parseType(at: 6)?.string == "[Foo]")
    }

    @Test func parsesDictionaryAsType() {
        let formatter = Formatter(tokenize("""
        let foo = [Foo: Bar]()
        """))
        #expect(formatter.parseType(at: 6)?.string == "[Foo: Bar]")
    }

    @Test func parseGenericType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo<Bar, Baaz> = .init()
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo<Bar, Baaz>")
    }

    @Test func parseOptionalGenericType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo<Bar, Baaz>? = .init()
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo<Bar, Baaz>?")
    }

    @Test func parseDictionaryType() {
        let formatter = Formatter(tokenize("""
        let foo: [Foo: Bar] = [:]
        """))
        #expect(formatter.parseType(at: 5)?.string == "[Foo: Bar]")
    }

    @Test func parseOptionalDictionaryType() {
        let formatter = Formatter(tokenize("""
        let foo: [Foo: Bar]? = [:]
        """))
        #expect(formatter.parseType(at: 5)?.string == "[Foo: Bar]?")
    }

    @Test func parseTupleType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) = (Foo(), Bar())
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar)")
    }

    @Test func parseClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) -> (Foo, Bar) = { foo, bar in (foo, bar) }
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) -> (Foo, Bar)")
    }

    @Test func parseThrowingClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) throws -> Void
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) throws -> Void")
    }

    @Test func parseTypedThrowingClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) throws(MyFeatureError) -> Void
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) throws(MyFeatureError) -> Void")
    }

    @Test func parseAsyncClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) async -> Void
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) async -> Void")
    }

    @Test func parseAsyncThrowsClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) async throws -> Void
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) async throws -> Void")
    }

    @Test func parseTypedAsyncThrowsClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) async throws(MyCustomError) -> Void
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) async throws(MyCustomError) -> Void")
    }

    @Test func parseClosureTypeWithOwnership() {
        let formatter = Formatter(tokenize("""
        let foo: (consuming Foo, borrowing Bar) -> (Foo, Bar) = { foo, bar in (foo, bar) }
        """))
        #expect(formatter.parseType(at: 5)?.string == "(consuming Foo, borrowing Bar) -> (Foo, Bar)")
    }

    @Test func parseOptionalReturningClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) -> (Foo, Bar)? = { foo, bar in (foo, bar) }
        """))
        #expect(formatter.parseType(at: 5)?.string == "(Foo, Bar) -> (Foo, Bar)?")
    }

    @Test func parseOptionalClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: ((Foo, Bar) -> (Foo, Bar)?)? = { foo, bar in (foo, bar) }
        """))
        #expect(formatter.parseType(at: 5)?.string == "((Foo, Bar) -> (Foo, Bar)?)?")
    }

    @Test func parseOptionalClosureTypeWithOwnership() {
        let formatter = Formatter(tokenize("""
        let foo: ((consuming Foo, borrowing Bar) -> (Foo, Bar)?)? = { foo, bar in (foo, bar) }
        """))
        #expect(formatter.parseType(at: 5)?.string == "((consuming Foo, borrowing Bar) -> (Foo, Bar)?)?")
    }

    @Test func parseExistentialAny() {
        let formatter = Formatter(tokenize("""
        let foo: any Foo
        """))
        #expect(formatter.parseType(at: 5)?.string == "any Foo")
    }

    @Test func parseCompoundType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo.Bar.Baaz
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo.Bar.Baaz")
    }

    @Test func doesntParseLeadingDotAsType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo = .Bar.baaz
        """))
        #expect(formatter.parseType(at: 9)?.string == nil)
    }

    @Test func parseCompoundGenericType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo<Bar>.Bar.Baaz<Quux.V2>
        """))
        #expect(formatter.parseType(at: 5)?.string == "Foo<Bar>.Bar.Baaz<Quux.V2>")
    }

    @Test func parseExistentialTypeWithSubtype() {
        let formatter = Formatter(tokenize("""
        let foo: (any Foo).Bar.Baaz
        """))
        #expect(formatter.parseType(at: 5)?.string == "(any Foo).Bar.Baaz")
    }

    @Test func parseOpaqueReturnType() {
        let formatter = Formatter(tokenize("""
        var body: some View { EmptyView() }
        """))
        #expect(formatter.parseType(at: 5)?.string == "some View")
    }

    @Test func parameterPackTypes() {
        let formatter = Formatter(tokenize("""
        func foo<each T>() -> repeat each T {
          return repeat each T.self
        }

        func eachFirst<each T: Collection>(_ item: repeat each T) -> (repeat (each T).Element?) {
            return (repeat (each item).first)
        }
        """))
        #expect(formatter.parseType(at: 4)?.string == "each T")
        #expect(formatter.parseType(at: 13)?.string == "repeat each T")
        #expect(formatter.parseType(at: 62)?.string == "repeat (each T).Element?")
    }

    @Test func parseInvalidType() {
        let formatter = Formatter(tokenize("""
        let foo = { foo, bar in (foo, bar) }
        """))
        #expect(formatter.parseType(at: 4)?.string == nil)
        #expect(formatter.parseType(at: 5)?.string == nil)
        #expect(formatter.parseType(at: 6)?.string == nil)
        #expect(formatter.parseType(at: 7)?.string == nil)
    }

    @Test func multilineType() {
        let formatter = Formatter(tokenize("""
        extension Foo.Bar
            .Baaz.Quux
            .InnerType1
            .InnerType2
        { }
        """))

        #expect(formatter.parseType(at: 2)?.string == "Foo.Bar.Baaz.Quux.InnerType1.InnerType2")
    }

    @Test func parseTuples() {
        let input = """
        let tuple: (foo: Foo, bar: Bar)
        let closure: (foo: Foo, bar: Bar) -> Void
        let valueWithRedundantParens: (Foo)
        let voidValue: ()
        let tupleWithComments: (
            bar: String, // comment A
            quux: String // comment B
        )  // Trailing comment
        """

        let formatter = Formatter(tokenize(input))

        #expect(formatter.parseType(at: 5)?.string == "(foo: Foo, bar: Bar)")
        #expect(formatter.parseType(at: 5)?.isTuple == true)

        #expect(formatter.parseType(at: 23)?.string == "(foo: Foo, bar: Bar) -> Void")
        #expect(formatter.parseType(at: 23)?.isTuple == false)

        #expect(formatter.parseType(at: 45)?.string == "(Foo)")
        #expect(formatter.parseType(at: 45)?.isTuple == false)

        #expect(formatter.parseType(at: 54)?.string == "()")
        #expect(formatter.parseType(at: 54)?.isTuple == false)

        #expect(formatter.parseType(at: 62)?.isTuple == true)
        #expect(formatter.parseType(at: 62)?.string == "(bar: String,  quux: String  )")
    }

    // MARK: - parseExpressionRange

    @Test func parseIndividualExpressions() {
        #expect(isSingleExpression(#"Foo()"#))
        #expect(isSingleExpression(#"Foo("bar")"#))
        #expect(isSingleExpression(#"Foo.init()"#))
        #expect(isSingleExpression(#"Foo.init("bar")"#))
        #expect(isSingleExpression(#"foo.bar"#))
        #expect(isSingleExpression(#"foo .bar"#))
        #expect(isSingleExpression(#"foo["bar"]("baaz")"#))
        #expect(isSingleExpression(#"foo().bar().baaz[]().bar"#))
        #expect(isSingleExpression(#"foo?.bar?().baaz!.quux ?? """#))
        #expect(isSingleExpression(#"1"#))
        #expect(isSingleExpression(#"10.0"#))
        #expect(isSingleExpression(#"10000"#))
        #expect(isSingleExpression(#"-24.0"#))
        #expect(isSingleExpression(#"3.14e2"#))
        #expect(isSingleExpression(#"1 + 2"#))
        #expect(isSingleExpression(#"-0.05 * 10"#))
        #expect(isSingleExpression(#"0...10"#))
        #expect(isSingleExpression(#"0..<20"#))
        #expect(isSingleExpression(#"0 ... array.indices.last"#))
        #expect(isSingleExpression(#"true"#))
        #expect(isSingleExpression(#"false"#))
        #expect(isSingleExpression(#"!boolean"#))
        #expect(isSingleExpression(#"boolean || !boolean && boolean"#))
        #expect(isSingleExpression(#"boolean ? value : value"#))
        #expect(isSingleExpression(#"foo"#))
        #expect(isSingleExpression(#""foo""#))
        #expect(isSingleExpression(##"#"raw string"#"##))
        #expect(isSingleExpression(###"##"raw string"##"###))
        #expect(isSingleExpression(#"["foo", "bar"]"#))
        #expect(isSingleExpression(#"["foo": bar]"#))
        #expect(isSingleExpression(#"(tuple: "foo", bar: "baaz")"#))
        #expect(isSingleExpression(#"foo.bar { "baaz"}"#))
        #expect(isSingleExpression(#"foo.bar({ "baaz" })"#))
        #expect(isSingleExpression(#"foo.bar() { "baaz" }"#))
        #expect(isSingleExpression(#"foo.bar { "baaz" } anotherTrailingClosure: { "quux" }"#))
        #expect(isSingleExpression(#"try foo()"#))
        #expect(isSingleExpression(#"try! foo()"#))
        #expect(isSingleExpression(#"try? foo()"#))
        #expect(isSingleExpression(#"try await foo()"#))
        #expect(isSingleExpression(#"foo is Foo"#))
        #expect(isSingleExpression(#"foo as Foo"#))
        #expect(isSingleExpression(#"foo as? Foo"#))
        #expect(isSingleExpression(#"foo as! Foo"#))
        #expect(isSingleExpression(#"foo ? bar : baaz"#))
        #expect(isSingleExpression(#".implicitMember"#))
        #expect(isSingleExpression(#"\Foo.explicitKeypath"#))
        #expect(isSingleExpression(#"\.inferredKeypath"#))
        #expect(isSingleExpression(#"#selector(Foo.bar)"#))
        #expect(isSingleExpression(#"#macro()"#))
        #expect(isSingleExpression(#"#outerMacro(12, #innerMacro(34), "some text")"#))
        #expect(isSingleExpression(#"try { try printThrows(foo) }()"#))
        #expect(isSingleExpression(#"try! { try printThrows(foo) }()"#))
        #expect(isSingleExpression(#"try? { try printThrows(foo) }()"#))
        #expect(isSingleExpression(#"await { await printAsync(foo) }()"#))
        #expect(isSingleExpression(#"try await { try await printAsyncThrows(foo) }()"#))
        #expect(isSingleExpression(#"Foo<Bar>()"#))
        #expect(isSingleExpression(#"each foo"#))
        #expect(isSingleExpression(#"repeat each foo.var.baaz"#))
        #expect(isSingleExpression(#"repeat (each item).first"#))
        #expect(isSingleExpression(#"Foo<Bar, Baaz>(quux: quux)"#))
        #expect(!isSingleExpression(#"if foo { "foo" } else { "bar" }"#))
        #expect(!isSingleExpression(#"foo.bar, baaz.quux"#))

        #expect(isSingleExpression(
            #"if foo { "foo" } else { "bar" }"#,
            allowConditionalExpressions: true
        ))

        #expect(isSingleExpression("""
        if foo {
          "foo"
        } else {
          "bar"
        }
        """, allowConditionalExpressions: true))

        #expect(isSingleExpression("""
        switch foo {
        case true:
            "foo"
        case false:
            "bar"
        }
        """, allowConditionalExpressions: true))

        #expect(isSingleExpression("""
        foo
            .bar
        """))

        #expect(isSingleExpression("""
        foo?
            .bar?()
            .baaz![0]
        """))

        #expect(isSingleExpression(#"""
        """
        multi-line string
        """
        """#))

        #expect(isSingleExpression(##"""
        #"""
        raw multi-line string
        """#
        """##))

        #expect(!(isSingleExpression(#"foo = bar"#)))
        #expect(!(isSingleExpression(#"foo = "foo"#)))
        #expect(!(isSingleExpression(#"10 20 30"#)))
        #expect(!(isSingleExpression(#"foo bar"#)))
        #expect(!(isSingleExpression(#"foo? bar"#)))

        #expect(!(isSingleExpression("""
        foo
            () // if you have a linebreak before a method call, its parsed as a tuple
        """)))

        #expect(!(isSingleExpression("""
        foo
            [0] // if you have a linebreak before a subscript, its invalid
        """)))

        #expect(!(isSingleExpression("""
        #if DEBUG
        foo
        #else
        bar
        #endif
        """)))
    }

    @Test func parseMultipleSingleLineExpressions() {
        let input = """
        foo
        foo?.bar().baaz()
        24
        !foo
        methodCall()
        foo ?? bar ?? baaz
        """

        // Each line is a single expression
        let expectedExpressions = input.components(separatedBy: "\n")
        #expect(parseExpressions(input) == expectedExpressions)
    }

    @Test func parseMultipleLineExpressions() {
        let input = """
        [
            "foo",
            "bar"
        ].map {
            $0.uppercased()
        }

        foo?.bar().methodCall(
            foo: foo,
            bar: bar)

        foo.multipleTrailingClosure {
            print("foo")
        } anotherTrailingClosure: {
            print("bar")
        }
        """

        let expectedExpressions = [
            """
            [
                "foo",
                "bar"
            ].map {
                $0.uppercased()
            }
            """,
            """
            foo?.bar().methodCall(
                foo: foo,
                bar: bar)
            """,
            """
            foo.multipleTrailingClosure {
                print("foo")
            } anotherTrailingClosure: {
                print("bar")
            }
            """,
        ]

        #expect(parseExpressions(input) == expectedExpressions)
    }

    @Test func parsedExpressionInIfConditionExcludesConditionBody() {
        let input = """
        if let bar = foo.bar {
          print(bar)
        }

        if foo.contains(where: { $0.isEmpty }) {
          print("Empty foo")
        }
        """

        #expect(parseExpression(in: input, at: 8) == "foo.bar")
        #expect(parseExpression(in: input, at: 25) == "foo.contains(where: { $0.isEmpty })")
    }

    @Test func parsedExpressionInIfConditionExcludesConditionBody_trailingClosureEdgeCase() {
        // This code is generally considered an anti-pattern, and outputs the following warning when compiled:
        // warning: trailing closure in this context is confusable with the body of the statement; pass as a parenthesized argument to silence this warning
        let input = """
        if foo.contains { $0.isEmpty } {
          print("Empty foo")
        }
        """

        // We don't bother supporting this, since it would increase the complexity of the parser.
        // A more correct result would be `foo.contains { $0.isEmpty }`.
        #expect(parseExpression(in: input, at: 2) == "foo.contains")
    }

    func isSingleExpression(_ string: String, allowConditionalExpressions: Bool = false) -> Bool {
        let formatter = Formatter(tokenize(string))
        guard let expressionRange = formatter.parseExpressionRange(startingAt: 0, allowConditionalExpressions: allowConditionalExpressions) else { return false }
        return expressionRange.upperBound == formatter.tokens.indices.last!
    }

    func parseExpressions(_ string: String) -> [String] {
        let formatter = Formatter(tokenize(string))
        var expressions = [String]()

        var parseIndex = 0
        while let expressionRange = formatter.parseExpressionRange(startingAt: parseIndex) {
            let expression = formatter.tokens[expressionRange].map(\.string).joined()
            expressions.append(expression)

            if let nextExpressionIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound) {
                parseIndex = nextExpressionIndex
            } else {
                return expressions
            }
        }

        return expressions
    }

    func parseExpression(in input: String, at index: Int) -> String {
        let formatter = Formatter(tokenize(input))
        guard let expressionRange = formatter.parseExpressionRange(startingAt: index) else { return "" }
        return formatter.tokens[expressionRange].map(\.string).joined()
    }

    // MARK: parseExpressionRange(endingAt:)

    @Test func parseExpressionEndingAt() {
        // Simple cases
        #expect(isSingleExpressionParsedFromEnd("foo"))
        #expect(isSingleExpressionParsedFromEnd("42"))

        // Postfix operators
        #expect(isSingleExpressionParsedFromEnd("foo!"))
        #expect(isSingleExpressionParsedFromEnd("foo?"))

        // Method calls and subscripts
        #expect(isSingleExpressionParsedFromEnd("foo.bar()"))
        #expect(isSingleExpressionParsedFromEnd("foo[0]"))

        // Prefix operators and keywords
        #expect(isSingleExpressionParsedFromEnd("!foo"))
        #expect(isSingleExpressionParsedFromEnd("try foo()"))
        #expect(isSingleExpressionParsedFromEnd("await foo()"))

        // Infix operators
        #expect(isSingleExpressionParsedFromEnd("foo + bar"))
        #expect(isSingleExpressionParsedFromEnd("foo * bar + baz"))
        #expect(isSingleExpressionParsedFromEnd("foo == bar.baaz"))
        #expect(isSingleExpressionParsedFromEnd("foo == .baaz"))
        #expect(isSingleExpressionParsedFromEnd("foo == !baaz"))
        #expect(isSingleExpressionParsedFromEnd("0 == -baaz"))

        // Type operators
        #expect(isSingleExpressionParsedFromEnd("foo as String"))
        #expect(isSingleExpressionParsedFromEnd("foo as! String"))
        #expect(isSingleExpressionParsedFromEnd("foo as? String"))
        #expect(isSingleExpressionParsedFromEnd("foo is String"))

        // Complex expressions with operators in the middle
        #expect(isSingleExpressionParsedFromEnd("foo!.bar"))
        #expect(isSingleExpressionParsedFromEnd("foo?[bar]?.baaz"))
        #expect(isSingleExpressionParsedFromEnd("foo!.bar + baz"))
        #expect(isSingleExpressionParsedFromEnd("obj.foo!.bar().baz"))
        #expect(isSingleExpressionParsedFromEnd("foo!.bar as String"))
        #expect(isSingleExpressionParsedFromEnd("try foo!.bar()"))
        #expect(isSingleExpressionParsedFromEnd("await foo!.bar()"))
        #expect(isSingleExpressionParsedFromEnd("try! foo.bar"))
        #expect(isSingleExpressionParsedFromEnd("try? foo()"))

        // Closures and literals
        #expect(isSingleExpressionParsedFromEnd("{ foo }"))
        #expect(isSingleExpressionParsedFromEnd("[1, 2, 3]"))
    }

    func isSingleExpressionParsedFromEnd(_ input: String) -> Bool {
        let formatter = Formatter(tokenize(input))
        let lastTokenIndex = formatter.tokens.count - 1
        guard let expressionRange = formatter.parseExpressionRange(endingAt: lastTokenIndex) else { return false }
        return formatter.tokens[expressionRange].string == input
    }

    // MARK: parseExpressionRange(containing:)

    @Test func parseExpressionRangeContaining() {
        // Simple cases
        #expect(parseExpression(in: "foo!", containing: "!") == "foo!")

        // Force unwrap in different contexts
        #expect(parseExpression(in: "foo(bar: foo!.bar)", containing: "!") == "foo!.bar")
        #expect(parseExpression(in: "let foo = foo!.bar + baz", containing: "!") == "foo!.bar + baz")
        #expect(parseExpression(in: "if foo, foo!.bar == quux", containing: "!") == "foo!.bar == quux")
        #expect(parseExpression(in: "[foo!.bar, baz]", containing: "!") == "foo!.bar")
        #expect(parseExpression(in: "(foo!.bar, baz)", containing: "!") == "foo!.bar")
        #expect(parseExpression(in: "return foo!.bar + baz", containing: "!") == "foo!.bar + baz")
        #expect(parseExpression(in: "return foo[bar]!.baaz", containing: "!") == "foo[bar]!.baaz")
        #expect(parseExpression(in: "array[foo!.bar]", containing: "!") == "foo!.bar")
        #expect(parseExpression(in: "{ foo!.bar }", containing: "!") == "foo!.bar")
        #expect(parseExpression(in: "foo as! Foo", containing: "!") == "foo as! Foo")
        #expect(parseExpression(in: "foo! + \"suffix\"", containing: "!") == "foo! + \"suffix\"")
        #expect(parseExpression(in: "foo(\"test\".data(using: .utf8)!)", containing: "!") == "\"test\".data(using: .utf8)!")

        // Multiple force unwraps
        #expect(parseExpression(in: "foo!.bar! + baz", containing: "!") == "foo!.bar! + baz")

        // Force unwrap in method chains
        #expect(parseExpression(in: "obj.foo!.bar().baz", containing: "!") == "obj.foo!.bar().baz")

        // Force unwrap with prefix operators
        #expect(parseExpression(in: "try foo!.bar()", containing: "!") == "try foo!.bar()")
        #expect(parseExpression(in: "await foo!.bar()", containing: "!") == "await foo!.bar()")

        // Force unwrap with type operators
        #expect(parseExpression(in: "foo!.bar as! String", containing: "!") == "foo!.bar as! String")

        #expect(parseExpression(in: #"XCTAssertEqual(route.query as! [String: String], ["a": "b"])"#, containing: "!") == "route.query as! [String: String]")
    }

    func parseExpression(in expression: String, containing: String) -> String? {
        let formatter = Formatter(tokenize(expression))
        guard let tokenIndex = formatter.tokens.firstIndex(where: { $0.string == containing }),
              let range = formatter.parseExpressionRange(containing: tokenIndex)
        else {
            return nil
        }
        return formatter.tokens[range].string
    }

    // MARK: isStoredProperty

    @Test func isStoredProperty() {
        #expect(isStoredProperty("var foo: String"))
        #expect(isStoredProperty("let foo = 42"))
        #expect(isStoredProperty("let foo: Int = 42"))
        #expect(isStoredProperty("var foo: Int = 42"))
        #expect(isStoredProperty("@Environment(\\.myEnvironmentProperty) var foo", at: 7))

        #expect(isStoredProperty("""
        var foo: String {
          didSet {
            print(newValue)
          }
        }
        """))

        #expect(isStoredProperty("""
        var foo: String {
          willSet {
            print(newValue)
          }
        }
        """))

        #expect(!(isStoredProperty("""
        var foo: String {
            "foo"
        }
        """)))

        #expect(!(isStoredProperty("""
        var foo: String {
            get { "foo" }
            set { print(newValue) }
        }
        """)))
    }

    func isStoredProperty(_ input: String, at index: Int = 0) -> Bool {
        let formatter = Formatter(tokenize(input))
        return formatter.isStoredProperty(atIntroducerIndex: index)
    }

    // MARK: scopeType

    @Test func scopeTypeForArrayExtension() {
        let input = "extension [Int] {}"
        let formatter = Formatter(tokenize(input))
        #expect(formatter.scopeType(at: 2) == .arrayType)
    }

    // MARK: parseFunctionDeclarationArgumentLabels

    @Test func parseFunctionDeclarationArguments() {
        let input = """
        func foo(_ foo: Foo, bar: Bar, quux _: Quux, last baaz: Baaz) {}
        func bar() {}
        """

        let formatter = Formatter(tokenize(input))

        let arguments = formatter.parseFunctionDeclarationArguments(startOfScope: 3) // foo(...)

        #expect(arguments.count == 4)

        // First argument: _ foo: Foo
        #expect(arguments[0].externalLabel == nil)
        #expect(arguments[0].internalLabel == "foo")
        #expect(arguments[0].externalLabelIndex == 4)
        #expect(arguments[0].internalLabelIndex == 6)
        #expect(arguments[0].type.string == "Foo")

        // Second argument: bar: Bar
        #expect(arguments[1].externalLabel == "bar")
        #expect(arguments[1].internalLabel == "bar")
        #expect(arguments[1].externalLabelIndex == nil)
        #expect(arguments[1].internalLabelIndex == 12)
        #expect(arguments[1].type.string == "Bar")

        // Third argument: quux _: Quux
        #expect(arguments[2].externalLabel == "quux")
        #expect(arguments[2].internalLabel == nil)
        #expect(arguments[2].externalLabelIndex == 18)
        #expect(arguments[2].internalLabelIndex == 20)
        #expect(arguments[2].type.string == "Quux")

        // Fourth argument: last baaz: Baaz
        #expect(arguments[3].externalLabel == "last")
        #expect(arguments[3].internalLabel == "baaz")
        #expect(arguments[3].externalLabelIndex == 26)
        #expect(arguments[3].internalLabelIndex == 28)
        #expect(arguments[3].type.string == "Baaz")

        #expect(formatter.parseFunctionDeclarationArguments(startOfScope: 40) == // bar()
            [])
    }

    @Test func parseFunctionCallArgumentLabels() {
        let input = """
        foo(Foo(foo: foo), bar: Bar(bar), foo, quux: Quux(), last: Baaz(foo: foo))

        print(formatter.isOperator(at: 0))
        """

        let formatter = Formatter(tokenize(input))
        #expect(formatter.parseFunctionCallArguments(startOfScope: 1).map(\.label) == // foo(...)
            [nil, "bar", nil, "quux", "last"])

        #expect(formatter.parseFunctionCallArguments(startOfScope: 3).map(\.label) == // Foo(...)
            ["foo"])

        #expect(formatter.parseFunctionCallArguments(startOfScope: 15).map(\.label) == // Bar(...)
            [nil])

        #expect(formatter.parseFunctionCallArguments(startOfScope: 27).map(\.label) == // Quux()
            [])

        #expect(formatter.parseFunctionCallArguments(startOfScope: 49).map(\.label) == // isOperator(...)
            ["at"])
    }

    @Test func parseFunctionDeclarationWithEffects() throws {
        let input = """
        struct FooBar {

            func foo(bar: Bar, baaz: Baaz) async throws(GenericError<Foo>) -> Foo<Bar, Baaz> {
                Foo(bar: bar, baaz: baaz)
            }

        }
        """

        let formatter = Formatter(tokenize(input))
        let function = try #require(formatter.parseFunctionDeclaration(keywordIndex: 8))

        #expect(function.keywordIndex == 8)
        #expect(function.name == "foo")
        #expect(function.genericParameterRange == nil)
        #expect(formatter.tokens[function.argumentsRange].string == "(bar: Bar, baaz: Baaz)")
        #expect(function.arguments.count == 2)
        #expect(try formatter.tokens[#require(function.effectsRange)].string == "async throws(GenericError<Foo>)")
        #expect(function.effects == ["async", "throws(GenericError<Foo>)"])
        #expect(function.returnOperatorIndex == 34)
        #expect(try formatter.tokens[#require(function.returnType?.range)].string == "Foo<Bar, Baaz>")
        #expect(function.whereClauseRange == nil)
        #expect(try formatter.tokens[#require(function.bodyRange)].string == """
        {
                Foo(bar: bar, baaz: baaz)
            }
        """)
    }

    @Test func parseFunctionDeclarationWithGeneric() throws {
        let input = """
        public func genericFoo<Bar: Baaz>(bar: Bar) rethrows where Baaz.Quux == Foo {
            print(bar)
        }

        func bar() { print("bar") }
        """

        let formatter = Formatter(tokenize(input))

        let function = try #require(formatter.parseFunctionDeclaration(keywordIndex: 2))
        #expect(function.keywordIndex == 2)
        #expect(function.name == "genericFoo")
        #expect(try formatter.tokens[#require(function.genericParameterRange)].string == "<Bar: Baaz>")
        #expect(formatter.tokens[function.argumentsRange].string == "(bar: Bar)")
        #expect(function.arguments.count == 1)
        #expect(try formatter.tokens[#require(function.effectsRange)].string == "rethrows")
        #expect(function.effects == ["rethrows"])
        #expect(function.returnOperatorIndex == nil)
        #expect(function.returnType?.range == nil)
        #expect(try formatter.tokens[#require(function.whereClauseRange)].string == "where Baaz.Quux == Foo ")
        #expect(try formatter.tokens[#require(function.bodyRange)].string == """
        {
            print(bar)
        }
        """)

        let secondFunction = try #require(formatter.parseFunctionDeclaration(keywordIndex: 41))
        #expect(secondFunction.keywordIndex == 41)
        #expect(secondFunction.name == "bar")
        #expect(secondFunction.genericParameterRange == nil)
        #expect(formatter.tokens[secondFunction.argumentsRange].string == "()")
        #expect(secondFunction.arguments.count == 0)
        #expect(secondFunction.effectsRange == nil)
        #expect(secondFunction.effects == [])
        #expect(secondFunction.returnOperatorIndex == nil)
        #expect(secondFunction.returnType?.range == nil)
        #expect(secondFunction.whereClauseRange == nil)
        #expect(try formatter.tokens[#require(secondFunction.bodyRange)].string == #"{ print("bar") }"#)
    }

    @Test func parseProtocolFunctionRequirements() throws {
        let input = """
        protocol FooBarProtocol {
            func foo(bar: Bar, baaz: Baaz) async throws -> Module.Foo<Bar, Baaz> where Bar == Baaz.Quux

            subscript<Bar: Baaz>(_ bar: Bar) throws
        }
        """

        let formatter = Formatter(tokenize(input))

        let function = try #require(formatter.parseFunctionDeclaration(keywordIndex: 7))
        #expect(function.keywordIndex == 7)
        #expect(function.name == "foo")
        #expect(function.genericParameterRange == nil)
        #expect(formatter.tokens[function.argumentsRange].string == "(bar: Bar, baaz: Baaz)")
        #expect(function.arguments.count == 2)
        #expect(try formatter.tokens[#require(function.effectsRange)].string == "async throws")
        #expect(function.effects == ["async", "throws"])
        #expect(function.returnOperatorIndex == 27)
        #expect(try formatter.tokens[#require(function.returnType?.range)].string == "Module.Foo<Bar, Baaz>")
        #expect(try formatter.tokens[#require(function.whereClauseRange)].string == "where Bar == Baaz.Quux")
        #expect(function.bodyRange == nil)

        let secondFunction = try #require(formatter.parseFunctionDeclaration(keywordIndex: 51))
        #expect(secondFunction.keywordIndex == 51)
        #expect(secondFunction.name == nil)
        #expect(try formatter.tokens[#require(secondFunction.genericParameterRange)].string == "<Bar: Baaz>")
        #expect(formatter.tokens[secondFunction.argumentsRange].string == "(_ bar: Bar)")
        #expect(secondFunction.arguments.count == 1)
        #expect(try formatter.tokens[#require(secondFunction.effectsRange)].string == "throws")
        #expect(secondFunction.effects == ["throws"])
        #expect(secondFunction.returnOperatorIndex == nil)
        #expect(secondFunction.returnType?.range == nil)
        #expect(secondFunction.whereClauseRange == nil)
        #expect(secondFunction.bodyRange == nil)
    }

    @Test func parseFailableInit() throws {
        let input = """
        init() {}
        init?() { return nil }
        """

        let formatter = Formatter(tokenize(input))

        let firstInit = try #require(formatter.parseFunctionDeclaration(keywordIndex: 0))
        #expect(firstInit.keywordIndex == 0)
        #expect(firstInit.name == nil)
        #expect(formatter.tokens[firstInit.argumentsRange].string == "()")
        #expect(firstInit.arguments.count == 0)
        #expect(firstInit.effects == [])
        #expect(firstInit.returnOperatorIndex == nil)
        #expect(firstInit.whereClauseRange == nil)
        #expect(try formatter.tokens[#require(firstInit.bodyRange)].string == "{}")

        let secondInit = try #require(formatter.parseFunctionDeclaration(keywordIndex: 7))
        #expect(secondInit.keywordIndex == 7)
        #expect(secondInit.name == nil)
        #expect(formatter.tokens[secondInit.argumentsRange].string == "()")
        #expect(secondInit.arguments.count == 0)
        #expect(secondInit.effects == [])
        #expect(secondInit.returnOperatorIndex == nil)
        #expect(secondInit.whereClauseRange == nil)
        #expect(try formatter.tokens[#require(secondInit.bodyRange)].string == "{ return nil }")
    }

    @Test func parseMarkdownFile() throws {
        let input = #"""
        # Sample README

        This is a nice project with lots of cool APIs to know about, including:

        ```swift
        func foo(
            bar: Bar
            baaz: Baaz
        ) -> Foo {}
        ```

        and:

          ```swift no-format
          class Foo {
              public init() {}
              public func bar() {}
          }
          ```

        This sample code even has a multi-line string in it:

        ```swift --indentstrings true
        let codeBlock = """
          ```swift
          print("foo")
          ```

          ```diff
          - print("foo")
          + print("bar")
          ```
          """
        ```

        Try it out!
        """#

        let codeBlocks = try parseCodeBlocks(fromMarkdown: input, language: "swift")

        #expect(codeBlocks[0].text == #"""
            func foo(
                bar: Bar
                baaz: Baaz
            ) -> Foo {}
            """#)

        #expect(codeBlocks[1].text == #"""
              class Foo {
                  public init() {}
                  public func bar() {}
              }
            """#)

        #expect(codeBlocks[1].options == "no-format")

        #expect(codeBlocks[2].text == #"""
            let codeBlock = """
              ```swift
              print("foo")
              ```

              ```diff
              - print("foo")
              + print("bar")
              ```
              """
            """#)

        #expect(codeBlocks[2].options == "--indentstrings true")
    }

    @Test func parseMarkdownWithUnbalancedDelimiters() {
        let input = """
        # Sample README

        This is a nice project with lots of cool APIs to know about, including:

        ```swift
        func foo(
            bar: Bar
            baaz: Baaz
        ) -> Foo {}

        ```swift
        foo(bar: bar, baaz: baaz)
        ```
        """

        #expect(throws: (any Error).self) { try parseCodeBlocks(fromMarkdown: input, language: "swift") }
    }

    @Test func commaSeparatedElementsInScope() {
        let input = """
        [
            1,
            2,
            3
        ]
        """

        let formatter = Formatter(tokenize(input))
        let elements = formatter.commaSeparatedElementsInScope(startOfScope: 0).map { formatter.tokens[$0].string }
        #expect(elements == [
            "1",
            "2",
            "3",
        ])
    }

    @Test func commaSeparatedElementsInScopeWithTrailingComma() {
        let input = """
        foo(
            foo: foo(),
            bar: bar(foo, bar),
            baaz: baaz.quux,
        )
        """

        let formatter = Formatter(tokenize(input))
        let elements = formatter.commaSeparatedElementsInScope(startOfScope: 1).map { formatter.tokens[$0].string }
        #expect(elements == [
            "foo: foo()",
            "bar: bar(foo, bar)",
            "baaz: baaz.quux",
        ])
    }

    @Test func parseCommentRange() throws {
        let input = """
        import FooLib

        // Class declaration
        class MyClass {}

        // Other comment

        /// Foo bar
        /// baaz quux
        @Foo
        struct MyStruct {}
        """

        let formatter = Formatter(tokenize(input))
        let classCommentRange = try #require(formatter.parseDocCommentRange(forDeclarationAt: 9)) // class
        let structCommentRange = try #require(formatter.parseDocCommentRange(forDeclarationAt: 30)) // struct

        #expect(formatter.tokens[classCommentRange].string == """
        // Class declaration
        """)

        #expect(formatter.tokens[structCommentRange].string == """
        /// Foo bar
        /// baaz quux
        """)
    }

    @Test func parseFunctionArgumentWithAttribute() throws {
        let input = "init(@ViewBuilder content: () -> Content) {}"
        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        let funcDecl = try #require(formatter.parseFunctionDeclaration(keywordIndex: 0))
        #expect(funcDecl.arguments.count == 1)

        let arg = funcDecl.arguments[0]
        #expect(arg.internalLabel == "content")
        #expect(arg.type.string == "() -> Content")
        #expect(arg.attributes == ["@ViewBuilder"])
    }

    @Test func parseFunctionArgumentWithGenericAttribute() throws {
        let input = "init(@DictionaryBuilder<String, Int> content: () -> [String: Int]) {}"
        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        let funcDecl = try #require(formatter.parseFunctionDeclaration(keywordIndex: 0))
        #expect(funcDecl.arguments.count == 1)

        let arg = funcDecl.arguments[0]
        #expect(arg.internalLabel == "content")
        #expect(arg.type.string == "() -> [String: Int]")
        #expect(arg.attributes == ["@DictionaryBuilder<String, Int>"])
    }

    @Test func parseDeclarationsWithViewBuilderProperty() {
        let input = """
        struct Foo {
            @Environment(\\.bar) private var bar

            @ViewBuilder let content: Content
            let title: String
        }
        """
        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        let declarations = formatter.parseDeclarations()
        guard let typeDecl = declarations.first?.asTypeDeclaration else {
            Issue.record("Failed to parse type declaration")
            return
        }

        // Should have 3 property declarations
        let properties = typeDecl.body.filter { $0.keyword == "var" || $0.keyword == "let" }
        #expect(properties.count == 3)

        // Check that @ViewBuilder property is parsed correctly
        let viewBuilderProp = properties.first { prop in
            formatter.tokens[prop.keywordIndex + 2].string == "content"
        }
        #expect(viewBuilderProp, "@ViewBuilder property should be found" != nil)
        #expect(viewBuilderProp?.keyword == "let")
    }

    @Test func parseDeclarationsWithViewBuilderPropertyNoBlankLine() {
        // @ViewBuilder property immediately after another property (no blank line)
        let input = """
        struct Foo {
            @Environment(\\.sizeClass) private var sizeClass
            @ViewBuilder let actionBar: ActionBar
            let title: String
        }
        """
        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        let declarations = formatter.parseDeclarations()
        guard let typeDecl = declarations.first?.asTypeDeclaration else {
            Issue.record("Failed to parse type declaration")
            return
        }

        let properties = typeDecl.body.filter { $0.keyword == "var" || $0.keyword == "let" }
        #expect(properties.count == 3, "Should find 3 properties: sizeClass, actionBar, title")
    }
}
)