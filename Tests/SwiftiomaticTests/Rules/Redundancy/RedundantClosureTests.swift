import Testing
@testable import Swiftiomatic

@Suite struct RedundantClosureTests {
    @Test func closureAroundConditionalAssignmentNotRedundantForExplicitReturn() {
        let input = """
        let myEnum = MyEnum.a
        let test: Int = {
            switch myEnum {
            case .a:
                return 0
            case .b:
                return 1
            }
        }()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, rule: .redundantClosure, options: options,
            exclude: [.propertyTypes],
        )
    }

    // MARK: redundantClosure

    @Test func removeRedundantClosureInSingleLinePropertyDeclaration() {
        let input = """
        let foo = { "Foo" }()
        let bar = { "Bar" }()

        let baaz = { "baaz" }()

        let quux = { "quux" }()
        """

        let output = """
        let foo = "Foo"
        let bar = "Bar"

        let baaz = "baaz"

        let quux = "quux"
        """

        testFormatting(for: input, output, rule: .redundantClosure)
    }

    @Test func redundantClosureWithExplicitReturn() {
        let input = """
        let foo = { return "Foo" }()

        let bar = {
            return if Bool.random() {
                "Bar"
            } else {
                "Baaz"
            }
        }()
        """

        let output = """
        let foo = "Foo"

        let bar = if Bool.random() {
                "Bar"
            } else {
                "Baaz"
            }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output], rules: [.redundantClosure],
            options: options, exclude: [.indent, .wrapMultilineConditionalAssignment],
        )
    }

    @Test func redundantClosureWithExplicitReturn2() {
        let input = """
        func foo() -> String {
            methodCall()
            return { return "Foo" }()
        }

        func bar() -> String {
            methodCall()
            return { "Bar" }()
        }

        func baaz() -> String {
            { return "Baaz" }()
        }
        """

        let output = """
        func foo() -> String {
            methodCall()
            return "Foo"
        }

        func bar() -> String {
            methodCall()
            return "Bar"
        }

        func baaz() -> String {
            "Baaz"
        }
        """

        testFormatting(for: input, [output], rules: [.redundantClosure])
    }

    @Test func keepsClosureThatIsNotCalled() {
        let input = """
        let foo = { "Foo" }
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func keepsEmptyClosures() {
        let input = """
        let foo = {}()
        let bar = { /* comment */ }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func removeRedundantClosureInMultiLinePropertyDeclaration() {
        let input = """
        lazy var bar = {
            Bar()
        }()
        """

        let output = """
        lazy var bar = Bar()
        """

        testFormatting(for: input, output, rule: .redundantClosure, exclude: [.propertyTypes])
    }

    @Test func removeRedundantClosureInMultiLinePropertyDeclarationWithString() {
        let input = #"""
        lazy var bar = {
            """
            Multiline string literal
            """
        }()
        """#

        let output = #"""
        lazy var bar = """
        Multiline string literal
        """
        """#

        testFormatting(for: input, [output], rules: [.redundantClosure, .indent])
    }

    @Test func removeRedundantClosureInMultiLinePropertyDeclarationInClass() {
        let input = """
        class Foo {
            lazy var bar = {
                return Bar();
            }()
        }
        """

        let output = """
        class Foo {
            lazy var bar = Bar()
        }
        """

        testFormatting(
            for: input, [output],
            rules: [
                .redundantClosure,
                .semicolons,
            ], exclude: [.propertyTypes],
        )
    }

    @Test func removeRedundantClosureInWrappedPropertyDeclaration_beforeFirst() {
        let input = """
        lazy var baaz = {
            Baaz(
                foo: foo,
                bar: bar)
        }()
        """

        let output = """
        lazy var baaz = Baaz(
            foo: foo,
            bar: bar)
        """

        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(
            for: input, [output],
            rules: [.redundantClosure, .wrapArguments],
            options: options, exclude: [.propertyTypes],
        )
    }

    @Test func removeRedundantClosureInWrappedPropertyDeclaration_afterFirst() {
        let input = """
        lazy var baaz = {
            Baaz(foo: foo,
                 bar: bar)
        }()
        """

        let output = """
        lazy var baaz = Baaz(foo: foo,
                             bar: bar)
        """

        let options = FormatOptions(wrapArguments: .afterFirst, closingParenPosition: .sameLine)
        testFormatting(
            for: input, [output],
            rules: [.redundantClosure, .wrapArguments],
            options: options, exclude: [.propertyTypes],
        )
    }

    @Test func redundantClosureKeepsMultiStatementClosureThatSetsProperty() {
        let input = """
        lazy var baaz = {
            let baaz = Baaz(foo: foo, bar: bar)
            baaz.foo = foo2
            return baaz
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func redundantClosureKeepsMultiStatementClosureWithMultipleStatements() {
        let input = """
        lazy var quux = {
            print("hello world")
            return "quux"
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func redundantClosureKeepsClosureWithInToken() {
        let input = """
        lazy var double = { () -> Double in
            100
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func redundantClosureKeepsMultiStatementClosureOnSameLine() {
        let input = """
        lazy var baaz = {
            print("Foo"); return baaz
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func redundantClosureRemovesComplexMultilineClosure() {
        let input = """
        lazy var closureInClosure = {
            {
              print("Foo")
              print("Bar"); return baaz
            }
        }()
        """

        let output = """
        lazy var closureInClosure = {
            print("Foo")
            print("Bar"); return baaz
        }
        """

        testFormatting(for: input, [output], rules: [.redundantClosure, .indent])
    }

    @Test func keepsClosureWithIfStatement() {
        let input = """
        lazy var baaz = {
            if let foo == foo {
                return foo
            } else {
                return Foo()
            }
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func keepsClosureWithIfStatementOnSingleLine() {
        let input = """
        lazy var baaz = {
            if let foo == foo { return foo } else { return Foo() }
        }()
        """

        testFormatting(
            for: input, rule: .redundantClosure,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func removesClosureWithIfStatementInsideOtherClosure() {
        let input = """
        lazy var baaz = {
            {
                if let foo == foo {
                    return foo
                } else {
                    return Foo()
                }
            }
        }()
        """

        let output = """
        lazy var baaz = {
            if let foo == foo {
                return foo
            } else {
                return Foo()
            }
        }
        """

        testFormatting(
            for: input, [output],
            rules: [.redundantClosure, .indent],
        )
    }

    @Test func keepsClosureWithSwitchStatement() {
        let input = """
        lazy var baaz = {
            switch foo {
            case let .some(foo):
                return foo:
            case .none:
                return Foo()
            }
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func keepsClosureWithIfDirective() {
        let input = """
        lazy var baaz = {
            #if DEBUG
                return DebugFoo()
            #else
                return Foo()
            #endif
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func keepsClosureThatCallsMethodThatReturnsNever() {
        let input = """
        lazy var foo: String = { fatalError("no default value has been set") }()
        lazy var bar: String = { return preconditionFailure("no default value has been set") }()
        """

        testFormatting(
            for: input, rule: .redundantClosure,
        )
    }

    @Test func removesClosureThatHasNestedFatalError() {
        let input = """
        lazy var foo = {
            Foo(handle: { fatalError() })
        }()
        """

        let output = """
        lazy var foo = Foo(handle: { fatalError() })
        """

        testFormatting(for: input, output, rule: .redundantClosure, exclude: [.propertyTypes])
    }

    @Test func preservesClosureWithMultipleVoidMethodCalls() {
        let input = """
        lazy var triggerSomething: Void = {
            logger.trace("log some stuff before Triggering")
            TriggerClass.triggerTheThing()
            logger.trace("Finished triggering the thing")
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func removesClosureWithMultipleNestedVoidMethodCalls() {
        let input = """
        lazy var foo: Foo = {
            Foo(handle: {
                logger.trace("log some stuff before Triggering")
                TriggerClass.triggerTheThing()
                logger.trace("Finished triggering the thing")
            })
        }()
        """

        let output = """
        lazy var foo: Foo = Foo(handle: {
            logger.trace("log some stuff before Triggering")
            TriggerClass.triggerTheThing()
            logger.trace("Finished triggering the thing")
        })
        """

        testFormatting(
            for: input, [output], rules: [.redundantClosure, .indent], exclude: [.redundantType],
        )
    }

    @Test func keepsClosureThatThrowsError() {
        let input = """
        let foo = try bar ?? { throw NSError() }()
        """
        testFormatting(for: input, rule: .redundantClosure)
    }

    @Test func keepsDiscardableResultClosure() {
        let input = """
        @discardableResult
        func discardableResult() -> String { "hello world" }

        /// We can't remove this closure, since the method called inline
        /// would return a String instead.
        let void: Void = { discardableResult() }()
        """
        testFormatting(for: input, rule: .redundantClosure, exclude: [.wrapFunctionBodies])
    }

    @Test func keepsDiscardableResultClosure2() {
        let input = """
        @discardableResult
        func discardableResult() -> String { "hello world" }

        /// We can't remove this closure, since the method called inline
        /// would return a String instead.
        let void: () = { discardableResult() }()
        """
        testFormatting(for: input, rule: .redundantClosure, exclude: [.wrapFunctionBodies])
    }

    @Test func redundantClosureDoesNotLeaveStrayTry() {
        let input = """
        let user2: User? = try {
            if let data2 = defaults.data(forKey: defaultsKey) {
                return try PropertyListDecoder().decode(User.self, from: data2)
            } else {
                return nil
            }
        }()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input,
            rules: [
                .conditionalAssignment,
                .redundantClosure,
            ],
            options: options, exclude: [.indent, .wrapMultilineConditionalAssignment],
        )
    }

    @Test func redundantClosureDoesNotLeaveStrayTryAwait() {
        let input = """
        let user2: User? = try await {
            if let data2 = defaults.data(forKey: defaultsKey) {
                return try await PropertyListDecoder().decode(User.self, from: data2)
            } else {
                return nil
            }
        }()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input,
            rules: [
                .conditionalAssignment,
                .redundantClosure,
            ],
            options: options, exclude: [.indent, .wrapMultilineConditionalAssignment],
        )
    }

}
