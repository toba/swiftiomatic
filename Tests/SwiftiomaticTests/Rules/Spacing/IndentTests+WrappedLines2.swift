import Testing
@testable import Swiftiomatic

extension IndentTests {
    @Test func chainedClosureIndentsAfterVarDeclaration() {
        let input = """
        var foo: Int
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        var foo: Int
        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedClosureIndentsAfterLetDeclaration() {
        let input = """
        let foo: Int
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        let foo: Int
        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedClosureIndentsSeparatedByComments() {
        let input = """
        foo {
            doFoo()
        }
        // bar
        .bar {
            doBar()
        }
        // baz
        .baz {
            doBaz($0)
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.blankLinesBetweenScopes],
        )
    }

    @Test func chainedFunctionIndents() {
        let input = """
        Button(action: {
            print("foo")
        })
        .buttonStyle(bar())
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func chainedFunctionIndentWithXcodeIndentation() {
        let input = """
        Button(action: {
            print("foo")
        })
        .buttonStyle(bar())
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func wrappedClosureIndentAfterAssignment() {
        let input = """
        let bar =
            baz { _ in
                print("baz")
            }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func chainedFunctionsInPropertySetter() {
        let input = """
        private let foo = bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo = bar(a: "A", b: "B")
            .baz()!
            .quux
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedFunctionsInPropertySetterOnNewLine() {
        let input = """
        private let foo =
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo =
            bar(a: "A", b: "B")
                .baz()!
                .quux
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedFunctionsInsideIf() {
        let input = """
        if foo {
        return bar()
        .baz()
        }
        """
        let output = """
        if foo {
            return bar()
                .baz()
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedFunctionsInsideForLoop() {
        let input = """
        for x in y {
        foo
        .bar {
        baz()
        }
        .quux()
        }
        """
        let output = """
        for x in y {
            foo
                .bar {
                    baz()
                }
                .quux()
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedFunctionsAfterAnIfStatement() {
        let input = """
        if foo {}
        bar
        .baz {
        }
        .quux()
        """
        let output = """
        if foo {}
        bar
            .baz {
            }
            .quux()
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.emptyBraces])
    }

    @Test func indentInsideWrappedIfStatementWithClosureCondition() {
        let input = """
        if foo({ 1 }) ||
        bar {
        baz()
        }
        """
        let output = """
        if foo({ 1 }) ||
            bar {
            baz()
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    @Test func indentInsideWrappedClassDefinition() {
        let input = """
        class Foo
        : Bar {
        baz()
        }
        """
        let output = """
        class Foo
            : Bar {
            baz()
        }
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.leadingDelimiters, .wrapMultilineStatementBraces],
        )
    }

    @Test func indentInsideWrappedProtocolDefinition() {
        let input = """
        protocol Foo
        : Bar, Baz {
        baz()
        }
        """
        let output = """
        protocol Foo
            : Bar, Baz {
            baz()
        }
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.leadingDelimiters, .wrapMultilineStatementBraces],
        )
    }

    @Test func indentInsideWrappedVarStatement() {
        let input = """
        var Foo:
        Bar {
        return 5
        }
        """
        let output = """
        var Foo:
            Bar {
            return 5
        }
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.wrapMultilineStatementBraces],
        )
    }

    @Test func noIndentAfterOperatorDeclaration() {
        let input = """
        infix operator ?=
        func ?= (lhs _: Int, rhs _: Int) -> Bool {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentAfterChevronOperatorDeclaration() {
        let input = """
        infix operator =<<
        func =<< <T>(lhs _: T, rhs _: T) -> T {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentWrappedStringDictionaryKeysAndValues() {
        let input = """
        [
        \"foo\":
        \"bar\",
        \"baz\":
        \"quux\",
        ]
        """
        let output = """
        [
            \"foo\":
                \"bar\",
            \"baz\":
                \"quux\",
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentWrappedEnumDictionaryKeysAndValues() {
        let input = """
        [
        .foo:
        .bar,
        .baz:
        .quux,
        ]
        """
        let output = """
        [
            .foo:
                .bar,
            .baz:
                .quux,
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentWrappedFunctionArgument() {
        let input = """
        foobar(baz: a &&
        b)
        """
        let output = """
        foobar(baz: a &&
            b)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentWrappedFunctionClosureArgument() {
        let input = """
        foobar(baz: { a &&
        b })
        """
        let output = """
        foobar(baz: { a &&
                b })
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.trailingClosures, .braces],
        )
    }

    @Test func indentWrappedFunctionWithClosureArgument() {
        let input = """
        foo(bar: { bar in
                bar()
            },
            baz: baz)
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentClassDeclarationContainingComment() {
        let input = """
        class Foo: Bar,
            // Comment
            Baz {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func wrappedLineAfterTypeAttribute() {
        let input = """
        let f: @convention(swift)
            (Int) -> Int = { x in x }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func wrappedLineAfterTypeAttribute2() {
        let input = """
        func foo(_: @escaping
            (Int) -> Int) {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func wrappedLineAfterNonTypeAttribute() {
        let input = """
        @discardableResult
        func foo() -> Int { 5 }
        """
        testFormatting(for: input, rule: .indent, exclude: [.wrapFunctionBodies])
    }

    @Test func indentWrappedClosureAfterSwitch() {
        let input = """
        switch foo {
        default:
            break
        }
        bar
            .map {
                // baz
            }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func singleIndentTrailingClosureBody() {
        let input = """
        func foo() {
            method(
                withParameter: 1,
                otherParameter: 2
            ) { [weak self] in
                guard let error = error else { return }
                print("and a trailing closure")
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .balanced)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func singleIndentTrailingClosureBody2() {
        let input = """
        func foo() {
            method(withParameter: 1,
                   otherParameter: 2) { [weak self] in
                guard let error = error else { return }
                print("and a trailing closure")
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [
                .wrapConditionalBodies, .wrapMultilineStatementBraces,
                .blankLinesAfterGuardStatements,
            ],
        )
    }

    @Test func doubleIndentTrailingClosureBody() {
        let input = """
        func foo() {
            method(
                withParameter: 1,
                otherParameter: 2) { [weak self] in
                    guard let error = error else { return }
                    print("and a trailing closure")
                }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [
                .wrapConditionalBodies, .wrapMultilineStatementBraces,
                .blankLinesAfterGuardStatements,
            ],
        )
    }

    @Test func doubleIndentTrailingClosureBody2() {
        let input = """
        extension Foo {
            func bar() -> Bar? {
                return Bar(with: Baz(
                    baz: baz)) { _ in
                        print("hello")
                    }
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.wrapMultilineStatementBraces],
        )
    }

    @Test func indentTrailingClosureAfterChainedMethodCall() {
        let input = """
        Foo()
            .bar(
                baaz: baaz,
                quux: quux)
            {
                print("Trailing closure")
            }
            .methodCallAfterTrailingClosure()

        Foo().bar(baaz: baaz, quux, quux) {
            print("Trailing closure")
        }
        """

        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentNonTrailingClosureAfterChainedMethodCall() {
        let input = """
        Foo()
            .bar(
                baaz: baaz,
                quux: quux,
                closure: {
                    print("Trailing closure")
                })

        Foo().bar(baaz: baaz, quux, quux, closure: {
            print("Trailing closure")
        })
        """

        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentTrailingClosureAfterNonChainedMethodCall() {
        let input = """
        Foo(
            baaz: baaz,
            quux: quux)
        {
            print("Trailing closure")
        }
        .methodCallAfterTrailingClosure()

        Foo().bar(baaz: baaz, quux, quux, closure: {
            print("Trailing closure")
        })
        """

        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func noDoubleIndentTrailingClosureBodyIfLineStartsWithClosingBrace() {
        let input = """
        let alert = Foo.alert(buttonCallback: {
            okBlock()
        }, cancelButtonTitle: cancelTitle) {
            cancelBlock()
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func singleIndentTrailingClosureBodyThatStartsOnFollowingLine() {
        let input = """
        func foo() {
            method(
                withParameter: 1,
                otherParameter: 2)
            { [weak self] in
                guard let error = error else { return }
                print("and a trailing closure")
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.braces, .wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func singleIndentTrailingClosureBodyOfShortMethod() {
        let input = """
        method(withParameter: 1) { [weak self] in
            guard let error = error else { return }
            print("and a trailing closure")
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func noDoubleIndentInInsideClosure() {
        let input = """
        let foo = bar({ baz
            in
            baz
        })
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.trailingClosures],
        )
    }

    @Test func noDoubleIndentInInsideClosure2() {
        let input = """
        foo(where: { _ in
            bar()
        }) { _ in
            print("and a trailing closure")
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noDoubleIndentInInsideClosure3() {
        let input = """
        foo {
            [weak self] _ in
            self?.bar()
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noDoubleIndentInInsideClosure4() {
        let input = """
        foo {
            (baz: Int) in
            self?.bar(baz)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noDoubleIndentInInsideClosure5() {
        let input = """
        foo { [weak self] bar in
            for baz in bar {
                self?.print(baz)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noDoubleIndentInInsideClosure6() {
        let input = """
        foo { (bar: [Int]) in
            for baz in bar {
                print(baz)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

}
