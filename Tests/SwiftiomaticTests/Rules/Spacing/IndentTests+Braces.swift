import Testing
@testable import Swiftiomatic

extension IndentTests {
    // indent braces

    @Test func elseClauseIndenting() {
        let input = """
        if x {
        bar
        } else {
        baz
        }
        """
        let output = """
        if x {
            bar
        } else {
            baz
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func noIndentBlankLines() {
        let input = """
        {

        // foo
        }
        """
        let output = """
        {

            // foo
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.blankLinesAtStartOfScope])
    }

    @Test func nestedBraces() {
        let input = """
        ({
        // foo
        }, {
        // bar
        })
        """
        let output = """
        ({
            // foo
        }, {
            // bar
        })
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func braceIndentAfterComment() {
        let input = """
        if foo { // comment
        bar
        }
        """
        let output = """
        if foo { // comment
            bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func braceIndentAfterClosingScope() {
        let input = """
        foo(bar(baz), {
        quux
        bleem
        })
        """
        let output = """
        foo(bar(baz), {
            quux
            bleem
        })
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.trailingClosures])
    }

    @Test func braceIndentAfterLineWithParens() {
        let input = """
        ({
        foo()
        bar
        })
        """
        let output = """
        ({
            foo()
            bar
        })
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func unindentClosingParenAroundBraces() {
        let input = """
        quux(success: {
            self.bar()
                })
        """
        let output = """
        quux(success: {
            self.bar()
        })
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentDoubleParenthesizedClosures() {
        let input = """
        foo(bar: Foo(success: { _ in
            self.bar()
        }, failure: { _ in
            self.baz()
        }))
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentUnbalancedBraces() {
        let input = """
        foo(bar()
            .map {
                .baz($0)
            })
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentClosureArguments() {
        let input = """
        quux(bar: {
          print(bar)
        },
        baz: {
          print(baz)
        })
        """
        let output = """
        quux(bar: {
                 print(bar)
             },
             baz: {
                 print(baz)
             })
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureArguments2() {
        let input = """
        foo(bar: {
                print(bar)
            },
            baz: {
                print(baz)
            }
        )
        """
        testFormatting(for: input, rule: .indent, exclude: [.wrapArguments])
    }

    @Test func indentWrappedClosureParameters() {
        let input = """
        foo { (
            bar: Int,
            baz: Int
        ) in
            print(bar + baz)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentWrappedClosureCaptureList() {
        let input = """
        foo { [
            title = title,
            weak topView = topView
        ] in
            print(title)
            _ = topView
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    // TODO: add `unwrap` rule to improve this case
    @Test func indentWrappedClosureCaptureList2() {
        let input = """
        class A {}
        let a = A()
        let f = { [
            weak a
        ]
        (
            x: Int,
            y: Int
        )
            throws
            ->
            Int
        in
            print("Hello, World! " + String(x + y))
            return x + y
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
    }

    @Test func indentWrappedClosureCaptureListWithUnwrappedParameters() {
        let input = """
        foo { [
            title = title,
            weak topView = topView
        ] (bar: Int) in
            print(title, bar)
            _ = topView
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentTrailingClosureArgumentsAfterFunction() {
        let input = """
        var epoxyViewportLogger = EpoxyViewportLogger(
            debounceInterval: 0.5,
            viewportStartImpressionHandler: { [weak self] _, viewportLoggingContext in
                self?.viewportLoggingRegistry.logViewportSessionStart(with: viewportLoggingContext)
            }) { [weak self] _, viewportLoggingContext in
                self?.viewportLoggingRegistry.logViewportSessionEnd(with: viewportLoggingContext)
            }
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func indentAllmanTrailingClosureArguments() {
        let input = """
        let foo = Foo
            .bar
            { _ in
                bar()
            }
            .baz(5)
            {
                baz()
            }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func indentAllmanTrailingClosureArguments2() {
        let input = """
        DispatchQueue.main.async
        {
            foo()
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentAllmanTrailingClosureArgumentsAfterFunction() {
        let input = """
        func foo()
        {
            return
        }

        Foo
            .bar()
            .baz
            {
                baz()
            }
            .quux
            {
                quux()
            }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(
            for: input, rule: .indent, options: options
        )
    }

    @Test func noDoubleIndentClosureArguments() {
        let input = """
        let foo = foo(bar(
            { baz },
            { quux }
        ))
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentLineAfterIndentedWrappedClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = Builder().build(
                bar: bar) { viewController in
                    viewController.dismiss(animated, true)
                }

            return viewController
        }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.braces, .wrapMultilineStatementBraces, .redundantProperty, .wrapArguments],
        )
    }

    @Test func indentLineAfterIndentedInlineClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = foo(Builder().build(
                bar: bar)) { _ in ViewController() }

            return viewController
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.redundantProperty, .wrapArguments])
    }

    @Test func indentLineAfterNonIndentedClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = Builder().build(bar: bar) { viewController in
                viewController.dismiss(animated, true)
            }

            return viewController
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.redundantProperty])
    }

    @Test func indentMultilineStatementDoesNotFailToTerminate() {
        let input = """
        foo(one: 1,
            two: 2).bar { _ in
            "one"
        }
        """
        let options = FormatOptions(wrapArguments: .afterFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

}
