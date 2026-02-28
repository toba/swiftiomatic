import Testing
@testable import Swiftiomatic

@Suite struct BlankLinesBetweenScopesTests {
    @Test func blankLineBetweenFunctions() {
        let input = """
        func foo() {
        }
        func bar() {
        }
        """
        let output = """
        func foo() {
        }

        func bar() {
        }
        """
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func noBlankLineBetweenPropertyAndFunction() {
        let input = """
        var foo: Int
        func bar() {
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    @Test func blankLineBetweenFunctionsIsBeforeComment() {
        let input = """
        func foo() {
        }
        /// headerdoc
        func bar() {
        }
        """
        let output = """
        func foo() {
        }

        /// headerdoc
        func bar() {
        }
        """
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func blankLineBeforeAtObjcOnLineBeforeProtocol() {
        let input = """
        @objc
        protocol Foo {
        }
        @objc
        protocol Bar {
        }
        """
        let output = """
        @objc
        protocol Foo {
        }

        @objc
        protocol Bar {
        }
        """
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func blankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = """
        protocol Foo {
        }
        @available(iOS 8.0, OSX 10.10, *)
        class Bar {
        }
        """
        let output = """
        protocol Foo {
        }

        @available(iOS 8.0, OSX 10.10, *)
        class Bar {
        }
        """
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func noExtraBlankLineBetweenFunctions() {
        let input = """
        func foo() {
        }

        func bar() {
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    @Test func noBlankLineBetweenFunctionsInProtocol() {
        let input = """
        protocol Foo {
            func bar()
            func baz() -> Int
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func noBlankLineInsideInitFunction() {
        let input = """
        init() {
            super.init()
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func blankLineAfterProtocolBeforeProperty() {
        let input = """
        protocol Foo {
        }
        var bar: String
        """
        let output = """
        protocol Foo {
        }

        var bar: String
        """
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func noExtraBlankLineAfterSingleLineComment() {
        let input = """
        var foo: Bar? // comment

        func bar() {}
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func noExtraBlankLineAfterMultilineComment() {
        let input = """
        var foo: Bar? /* comment */

        func bar() {}
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func noBlankLineBeforeFuncAsIdentifier() {
        let input = """
        var foo: Bar?
        foo.func(x) {}
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func noBlankLineBetweenFunctionsWithInlineBody() {
        let input = """
        class Foo {
            func foo() { print(\"foo\") }
            func bar() { print(\"bar\") }
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.wrapFunctionBodies])
    }

    @Test func noBlankLineBetweenIfStatements() {
        let input = """
        func foo() {
            if x {
            }
            if y {
            }
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    @Test func noBlanksInsideClassFunc() {
        let input = """
        class func foo {
            if x {
            }
            if y {
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(
            for: input, rule: .blankLinesBetweenScopes, options: options,
            exclude: [.emptyBraces],
        )
    }

    @Test func noBlanksInsideClassVar() {
        let input = """
        class var foo: Int {
            if x {
            }
            if y {
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(
            for: input, rule: .blankLinesBetweenScopes, options: options,
            exclude: [.emptyBraces],
        )
    }

    @Test func blankLineBetweenCalledClosures() {
        let input = """
        class Foo {
            var foo = {
            }()
            func bar {
            }
        }
        """
        let output = """
        class Foo {
            var foo = {
            }()

            func bar {
            }
        }
        """
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func noBlankLineAfterCalledClosureAtEndOfScope() {
        let input = """
        class Foo {
            var foo = {
            }()
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    @Test func noBlankLineBeforeWhileInRepeatWhile() {
        let input = """
        repeat
        { print("foo") }
        while false
        { print("bar") }()
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(
            for: input, rule: .blankLinesBetweenScopes, options: options,
            exclude: [.redundantClosure, .wrapLoopBodies],
        )
    }

    @Test func blankLineBeforeWhileIfNotRepeatWhile() {
        let input = """
        func foo(x)
        {
        }
        while true
        {
        }
        """
        let output = """
        func foo(x)
        {
        }

        while true
        {
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(
            for: input, output, rule: .blankLinesBetweenScopes, options: options,
            exclude: [.emptyBraces],
        )
    }

    @Test func noInsertBlankLinesInConditionalCompilation() {
        let input = """
        struct Foo {
            #if BAR
                func something() {
                }
            #else
                func something() {
                }
            #endif
        }
        """
        testFormatting(
            for: input, rule: .blankLinesBetweenScopes,
            exclude: [.emptyBraces],
        )
    }

    @Test func noInsertBlankLineAfterBraceBeforeSourceryComment() {
        let input = """
        struct Foo {
            var bar: String

            // sourcery:inline:Foo.init
            public init(bar: String) {
                self.bar = bar
            }
            // sourcery:end
        }
        """
        testFormatting(
            for: input, rule: .blankLinesBetweenScopes,
            exclude: [.redundantPublic, .redundantMemberwiseInit],
        )
    }

    @Test func noBlankLineBetweenChainedClosures() {
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
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func noBlankLineBetweenTrailingClosures() {
        let input = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }
        completion: { finished in
            context.completeTransition(finished)
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    @Test func blankLineBetweenTrailingClosureAndLabelledLoop() {
        let input = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }
        completion: for foo in bar {
            print(foo)
        }
        """
        let output = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }

        completion: for foo in bar {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes)
    }
}
