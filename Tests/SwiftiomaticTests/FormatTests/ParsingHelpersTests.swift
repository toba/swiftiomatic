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
        let formatter = Formatter(
            tokenize(
                """
                if let foo = { () -> Int? in 5 }() {}
                """,
            ),
        )
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
        let formatter = Formatter(
            tokenize(
                """
                guard let bar = { nil }() else {
                    return nil
                }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 8))
        #expect(!(formatter.isStartOfClosure(at: 18)))
    }

    @Test func closureInIfCondition() {
        let formatter = Formatter(
            tokenize(
                """
                if let btn = btns.first { !$0.isHidden } {}
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 12))
        #expect(!(formatter.isStartOfClosure(at: 21)))
    }

    @Test func closureInIfCondition2() {
        let formatter = Formatter(
            tokenize(
                """
                if let foo, let btn = btns.first { !$0.isHidden } {}
                """,
            ),
        )
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
        let formatter = Formatter(
            tokenize(
                """
                switch foo {
                    case .bar
                    where testValues.map(String.init).compactMap { $0 }
                    .contains(baz):
                        continue
                }
                """,
            ),
        )
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
        let formatter = Formatter(
            tokenize(
                """
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
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 8)))
        #expect(formatter.isStartOfClosure(at: 12))
        for i in stride(from: 0, to: repeatCount * 16, by: 16) {
            #expect(formatter.isStartOfClosure(at: 24 + i))
            #expect(formatter.isStartOfClosure(at: 28 + i))
        }
    }

    @Test func wrappedClosureAfterAnIfStatement() {
        let formatter = Formatter(
            tokenize(
                """
                if foo {}
                bar
                    .baz {}
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 13))
    }

    @Test func wrappedClosureAfterSwitch() {
        let formatter = Formatter(
            tokenize(
                """
                switch foo {
                default:
                    break
                }
                bar
                    .map {
                        // baz
                    }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 20))
    }

    @Test func closureInsideIfCondition() {
        let formatter = Formatter(
            tokenize(
                """
                if let foo = bar(), { x == y }() {}
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 13))
        #expect(!(formatter.isStartOfClosure(at: 25)))
    }

    @Test func closureInsideIfCondition2() {
        let formatter = Formatter(
            tokenize(
                """
                if foo == bar.map { $0.baz }.sorted() {}
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 10))
        #expect(!(formatter.isStartOfClosure(at: 22)))
    }

    @Test func closureInsideIfCondition3() {
        let formatter = Formatter(
            tokenize(
                """
                if baz, let foo = bar(), { x == y }() {}
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 16))
        #expect(!(formatter.isStartOfClosure(at: 28)))
    }

    @Test func closureAfterGenericType() {
        let formatter = Formatter(tokenize("let foo = Foo<String> {}"))
        #expect(formatter.isStartOfClosure(at: 11))
    }

    @Test func allmanClosureAfterFunction() {
        let formatter = Formatter(
            tokenize(
                """
                func foo() {}
                Foo
                    .baz
                    {
                        baz()
                    }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 16))
    }

    @Test func genericInitializerTrailingClosure() {
        let formatter = Formatter(
            tokenize(
                """
                Foo<Bar>(0) { [weak self]() -> Void in }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 8))
    }

    @Test func parameterBodyAfterStringIsNotClosure() {
        let formatter = Formatter(
            tokenize(
                """
                var foo: String = "bar" {
                    didSet { print("didSet") }
                }
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 13)))
    }

    @Test func parameterBodyAfterMultilineStringIsNotClosure() {
        let formatter = Formatter(
            tokenize(
                """
                var foo: String = \"\""
                bar
                \"\"" {
                    didSet { print("didSet") }
                }
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 15)))
    }

    @Test func parameterBodyAfterNumberIsNotClosure() {
        let formatter = Formatter(
            tokenize(
                """
                var foo: Int = 10 {
                    didSet { print("didSet") }
                }
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 11)))
    }

    @Test func parameterBodyAfterClosureIsNotClosure() {
        let formatter = Formatter(
            tokenize(
                """
                var foo: () -> String = { "bar" } {
                    didSet { print("didSet") }
                }
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 22)))
    }

    @Test func parameterBodyAfterExecutedClosureIsNotClosure() {
        let formatter = Formatter(
            tokenize(
                """
                var foo: String = { "bar" }() {
                    didSet { print("didSet") }
                }
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 19)))
    }

    @Test func mainActorClosure() {
        let formatter = Formatter(
            tokenize(
                """
                let foo = { @MainActor in () }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func throwingClosure() {
        let formatter = Formatter(
            tokenize(
                """
                let foo = { bar throws in bar }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func typedThrowingClosure() {
        let formatter = Formatter(
            tokenize(
                """
                let foo = { bar throws(Foo) in bar }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 6))
    }

    @Test func nestedTypedThrowingClosures() {
        let formatter = Formatter(
            tokenize(
                """
                try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in
                    try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in }
                }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 15))
        #expect(formatter.isStartOfClosure(at: 42))
    }

    @Test func trailingClosureOnOptionalMethod() {
        let formatter = Formatter(
            tokenize(
                """
                foo.bar? { print("") }
                """,
            ),
        )
        #expect(formatter.isStartOfClosure(at: 5))
    }

    @Test func braceAfterTypedThrows() {
        let formatter = Formatter(
            tokenize(
                """
                do throws(Foo) {} catch {}
                """,
            ),
        )
        #expect(!(formatter.isStartOfClosure(at: 7)))
        #expect(!(formatter.isStartOfClosure(at: 12)))
    }

}
