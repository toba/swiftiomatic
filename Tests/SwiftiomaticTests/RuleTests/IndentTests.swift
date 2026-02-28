import Testing
@testable import Swiftiomatic

@Suite struct IndentTests {
    @Test func reduceIndentAtStartOfFile() {
        let input = """
            foo()
        """
        let output = """
        foo()
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func reduceIndentAtEndOfFile() {
        let input = """
        foo()
           bar()
        """
        let output = """
        foo()
        bar()
        """
        testFormatting(for: input, output, rule: .indent)
    }

    // indent parens

    @Test func simpleScope() {
        let input = """
        foo(
        bar
        )
        """
        let output = """
        foo(
            bar
        )
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func nestedScope() {
        let input = """
        foo(
        bar {
        }
        )
        """
        let output = """
        foo(
            bar {
            }
        )
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.emptyBraces])
    }

    @Test func nestedScopeOnSameLine() {
        let input = """
        foo(bar(
        baz
        ))
        """
        let output = """
        foo(bar(
            baz
        ))
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func nestedScopeOnSameLine2() {
        let input = """
        foo(bar(in:
        baz))
        """
        let output = """
        foo(bar(in:
            baz))
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentNestedArrayLiteral() {
        let input = """
        foo(bar: [
        .baz,
        ])
        """
        let output = """
        foo(bar: [
            .baz,
        ])
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func closingScopeAfterContent() {
        let input = """
        foo(
        bar
        )
        """
        let output = """
        foo(
            bar
        )
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func closingNestedScopeAfterContent() {
        let input = """
        foo(bar(
        baz
        ))
        """
        let output = """
        foo(bar(
            baz
        ))
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedFunctionArguments() {
        let input = """
        foo(
        bar,
        baz
        )
        """
        let output = """
        foo(
            bar,
            baz
        )
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func functionArgumentsWrappedAfterFirst() {
        let input = """
        func foo(bar: Int,
        baz: Int)
        """
        let output = """
        func foo(bar: Int,
                 baz: Int)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentPreservedForNestedWrappedParameters() {
        let input = """
        let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                                 status: .enabled)),
                                          invoicingURL: .invoicing,
                                          paymentFormURL: .paymentForm)
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func indentPreservedForNestedWrappedParameters2() {
        let input = """
        let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                                 status: .enabled),
                                                           invoicingURL: .invoicing,
                                                           paymentFormURL: .paymentForm))
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func indentPreservedForNestedWrappedParameters3() {
        let input = """
        let loginResponse = LoginResponse(
            status: .success(.init(accessToken: session,
                                   status: .enabled),
                             invoicingURL: .invoicing,
                             paymentFormURL: .paymentForm)
        )
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func indentTrailingClosureInParensContainingUnwrappedArguments() {
        let input = """
        let foo = bar(baz {
            quux(foo, bar)
        })
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentTrailingClosureInParensContainingWrappedArguments() {
        let input = """
        let foo = bar(baz {
            quux(foo,
                 bar)
        })
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentTrailingClosureInParensContainingWrappedArguments2() {
        let input = """
        let foo = bar(baz {
            quux(
                foo,
                bar
            )
        })
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentImbalancedNestedClosingParens() {
        let input = """
        Foo(bar:
            Bar(
                baz: quux
            ))
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentChainedCallAfterClosingParen() {
        let input = """
        foo(
            bar: { baz in
                baz()
            })
            .quux {
                View()
            }
        """
        testFormatting(for: input, rule: .indent, exclude: [.wrapArguments])
    }

    @Test func indentChainedCallAfterClosingParen2() {
        let input = """
        func makeEpoxyModel() -> EpoxyModeling {
            LegacyEpoxyModelBuilder<BasicRow>(
                dataID: DataID.dismissModalBody.rawValue,
                content: .init(titleText: content.title, subtitleText: content.bodyHtml),
                style: Style.standard
                    .with(property: newValue)
                    .with(anotherProperty: newValue))
                .with(configurer: { view, content, _, _ in
                    view.setHTMLText(content.subtitleText?.unstyledText)
                })
                .build()
        }
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent modifiers

    @Test func noIndentWrappedModifiersForProtocol() {
        let input = """
        @objc
        private
        protocol Foo {}
        """
        testFormatting(for: input, rule: .indent, exclude: [.modifiersOnSameLine])
    }

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
            for: input, rule: .indent, options: options,
            exclude: [.redundantReturn],
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

    // indent switch/case

    @Test func switchCaseIndenting() {
        let input = """
        switch x {
        case foo:
        break
        case bar:
        break
        default:
        break
        }
        """
        let output = """
        switch x {
        case foo:
            break
        case bar:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func switchWrappedCaseIndenting() {
        let input = """
        switch x {
        case foo,
        bar,
            baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case foo,
             bar,
             baz:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    @Test func switchWrappedEnumCaseIndenting() {
        let input = """
        switch x {
        case .foo,
        .bar,
            .baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case .foo,
             .bar,
             .baz:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    @Test func switchWrappedEnumCaseIndentingVariant2() {
        let input = """
        switch x {
        case
        .foo,
        .bar,
            .baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case
            .foo,
            .bar,
            .baz:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    @Test func switchWrappedEnumCaseIsIndenting() {
        let input = """
        switch x {
        case is Foo.Type,
            is Bar.Type:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case is Foo.Type,
             is Bar.Type:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    @Test func switchCaseIsDictionaryIndenting() {
        let input = """
        switch x {
        case foo is [Key: Value]:
        fallthrough
        default:
        break
        }
        """
        let output = """
        switch x {
        case foo is [Key: Value]:
            fallthrough
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func enumCaseIndenting() {
        let input = """
        enum Foo {
        case Bar
        case Baz
        }
        """
        let output = """
        enum Foo {
            case Bar
            case Baz
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func enumCaseIndentingCommas() {
        let input = """
        enum Foo {
        case Bar,
        Baz
        }
        """
        let output = """
        enum Foo {
            case Bar,
                 Baz
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapEnumCases])
    }

    @Test func genericEnumCaseIndenting() {
        let input = """
        enum Foo<T> {
        case Bar
        case Baz
        }
        """
        let output = """
        enum Foo<T> {
            case Bar
            case Baz
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentSwitchAfterRangeCase() {
        let input = """
        switch x {
        case 0 ..< 2:
            switch y {
            default:
                break
            }
        default:
            break
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.blankLineAfterSwitchCase])
    }

    @Test func indentEnumDeclarationInsideSwitchCase() {
        let input = """
        switch x {
        case y:
        enum Foo {
        case z
        }
        bar()
        default: break
        }
        """
        let output = """
        switch x {
        case y:
            enum Foo {
                case z
            }
            bar()
        default: break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.blankLineAfterSwitchCase])
    }

    @Test func indentEnumCaseBodyAfterWhereClause() {
        let input = """
        switch foo {
        case _ where baz < quux:
            print(1)
            print(2)
        default:
            break
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.blankLineAfterSwitchCase])
    }

    @Test func indentSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        // comment
        case y:
        // comment
        break
        // comment
        case z:
        break
        }
        """
        let output = """
        switch x {
        // comment
        case y:
            // comment
            break
        // comment
        case z:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.blankLineAfterSwitchCase])
    }

    @Test func indentMultilineSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        /*
         * comment
         */
        case y:
        break
        /*
         * comment
         */
        default:
        break
        }
        """
        let output = """
        switch x {
        /*
         * comment
         */
        case y:
            break
        /*
         * comment
         */
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentEnumCaseComment() {
        let input = """
        enum Foo {
           /// bar
           case bar
        }
        """
        let output = """
        enum Foo {
            /// bar
            case bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentMultipleSingleLineSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        // comment 1
        // comment 2
        case y:
        // comment
        break
        }
        """
        let output = """
        switch x {
        // comment 1
        // comment 2
        case y:
            // comment
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentIfCase() {
        let input = """
        {
        if case let .foo(msg) = error {}
        }
        """
        let output = """
        {
            if case let .foo(msg) = error {}
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentGuardCase() {
        let input = """
        {
        guard case .Foo = error else {}
        }
        """
        let output = """
        {
            guard case .Foo = error else {}
        }
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func indentIfElse() {
        let input = """
        if foo {
        } else if let bar = baz,
                  let baz = quux {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func nestedIndentIfElse() {
        let input = """
        if bar {} else if baz,
                          quux
        {
            if foo {
            } else if let bar = baz,
                      let baz = quux {}
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentIfCaseLet() {
        let input = """
        if case let foo = foo,
           let bar = bar {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultipleIfLet() {
        let input = """
        if let foo = foo, let bar = bar,
           let baz = baz {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentWrappedConditionAlignsWithParen() {
        let input = """
        do {
            if let foo = foo(
                bar: 5
            ), let bar = bar,
            baz == quux {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentWrappedConditionAlignsWithParen2() {
        let input = """
        do {
            if let foo = foo({
                bar()
            }), bar == baz,
            let quux == baz {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentUnknownDefault() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown default:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentUnknownDefaultOnOwnLine() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown
            default:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentUnknownCase() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown case _:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown case _:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentUnknownCaseOnOwnLine() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown
            case _:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown
        case _:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedClassDeclaration() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapMultilineStatementBraces],
        )
    }

    @Test func wrappedClassDeclarationLikeXcode() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        let output = """
        class Foo: Bar,
        Baz {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func wrappedClassDeclarationWithBracesOnSameLineLikeXcode() {
        let input = """
        class Foo: Bar,
        Baz {}
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func wrappedClassDeclarationWithBraceOnNextLineLikeXcode() {
        let input = """
        class Foo: Bar,
            Baz
        {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func wrappedClassWhereDeclarationLikeXcode() {
        let input = """
        class Foo<T>: Bar
            where T: Baz {
            init() {}
        }
        """
        let output = """
        class Foo<T>: Bar
        where T: Baz {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.simplifyGenericConstraints],
        )
    }

    @Test func indentSwitchCaseDo() {
        let input = """
        switch foo {
        case .bar: do {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    // indentCase = true

    @Test func switchCaseWithIndentCaseTrue() {
        let input = """
        switch x {
        case foo:
        break
        case bar:
        break
        default:
        break
        }
        """
        let output = """
        switch x {
            case foo:
                break
            case bar:
                break
            default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchWrappedEnumCaseWithIndentCaseTrue() {
        let input = """
        switch x {
        case .foo,
        .bar,
            .baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
            case .foo,
                 .bar,
                 .baz:
                break
            default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(
            for: input,
            output,
            rule: .indent,
            options: options,
            exclude: [.sortSwitchCases],
        )
    }

    @Test func indentMultilineSwitchCaseCommentsWithIndentCaseTrue() {
        let input = """
        switch x {
        /*
         * comment
         */
        case y:
        break
        /*
         * comment
         */
        default:
        break
        }
        """
        let output = """
        switch x {
            /*
             * comment
             */
            case y:
                break
            /*
             * comment
             */
            default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func noMangleLabelWhenIndentCaseTrue() {
        let input = """
        foo: while true {
            break foo
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test
    func indentMultipleSingleLineSwitchCaseCommentsWithCommentsIgnoredCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch x {
            // bar
            case .y: return 1
            // baz
            case .z: return 2
        }
        """
        let options = FormatOptions(indentCase: true, indentComments: false)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentUnknownDefaultCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch foo {
        case .bar:
            break
        @unknown default:
            break
        }
        """
        let output = """
        switch foo {
            case .bar:
                break
            @unknown default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentUnknownCaseCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch foo {
        case .bar:
            break
        @unknown case _:
            break
        }
        """
        let output = """
        switch foo {
            case .bar:
                break
            @unknown case _:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentSwitchCaseDoWhenIndentCaseTrue() {
        let input = """
        switch foo {
            case .bar: do {
                    baz()
                }
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent wrapped lines

    @Test func wrappedLineAfterOperator() {
        let input = """
        if x {
        let y = foo +
        bar
        }
        """
        let output = """
        if x {
            let y = foo +
                bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterComma() {
        let input = """
        let a = b,
        b = c
        """
        let output = """
        let a = b,
            b = c
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.singlePropertyPerLine])
    }

    @Test func wrappedBeforeComma() {
        let input = """
        let a = b
        , b = c
        """
        let output = """
        let a = b
            , b = c
        """
        testFormatting(
            for: input, output, rule: .indent, exclude: [
                .leadingDelimiters,
                .singlePropertyPerLine,
            ],
        )
    }

    @Test func wrappedLineAfterCommaInsideArray() {
        let input = """
        [
        foo,
        bar,
        ]
        """
        let output = """
        [
            foo,
            bar,
        ]
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeCommaInsideArray() {
        let input = """
        [
        foo
        , bar,
        ]
        """
        let output = """
        [
            foo
            , bar,
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.leadingDelimiters],
        )
    }

    @Test func wrappedLineAfterCommaInsideInlineArray() {
        let input = """
        [foo,
        bar]
        """
        let output = """
        [foo,
         bar]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func wrappedLineBeforeCommaInsideInlineArray() {
        let input = """
        [foo
        , bar]
        """
        let output = """
        [foo
         , bar]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.leadingDelimiters],
        )
    }

    @Test func wrappedLineAfterColonInFunction() {
        let input = """
        func foo(bar:
        baz)
        """
        let output = """
        func foo(bar:
            baz)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func noDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = """
        (foo as
        Bar)
        """
        let output = """
        (foo as
            Bar)
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func noDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = """
        (foo
        as Bar)
        """
        let output = """
        (foo
            as Bar)
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func doubleIndentWhenScopesSeparatedByWrap() {
        let input = """
        (foo
        as Bar {
        baz
        })
        """
        let output = """
        (foo
            as Bar {
                baz
            })
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    @Test func noDoubleIndentWhenScopesSeparatedByWrap() {
        let input = """
        (foo
        as Bar {
        baz
        }
        )
        """
        let output = """
        (foo
            as Bar {
                baz
            }
        )
        """
        testFormatting(
            for: input, output, rule: .indent,
            exclude: [.wrapArguments, .redundantParens],
        )
    }

    @Test func noPermanentReductionInScopeAfterWrap() {
        let input = """
        { foo
        as Bar
        let baz = 5
        }
        """
        let output = """
        { foo
            as Bar
            let baz = 5
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeOperator() {
        let input = """
        if x {
        let y = foo
        + bar
        }
        """
        let output = """
        if x {
            let y = foo
                + bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeIsOperator() {
        let input = """
        if x {
        let y = foo
        is Bar
        }
        """
        let output = """
        if x {
            let y = foo
                is Bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterForKeyword() {
        let input = """
        for
        i in range {}
        """
        let output = """
        for
            i in range {}
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterInKeyword() {
        let input = """
        for i in
        range {}
        """
        let output = """
        for i in
            range {}
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterDot() {
        let input = """
        let foo = bar.
        baz
        """
        let output = """
        let foo = bar.
            baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeDot() {
        let input = """
        let foo = bar
        .baz
        """
        let output = """
        let foo = bar
            .baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeWhere() {
        let input = """
        let foo = bar
        where foo == baz
        """
        let output = """
        let foo = bar
            where foo == baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineAfterWhere() {
        let input = """
        let foo = bar where
        foo == baz
        """
        let output = """
        let foo = bar where
            foo == baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineBeforeGuardElse() {
        let input = """
        guard let foo = bar
        else { return }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func wrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = """
        guard let foo = bar else
        { return }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.elseOnSameLine, .wrapConditionalBodies],
        )
    }

    @Test func wrappedLineAfterComment() {
        let input = """
        foo = bar && // comment
        baz
        """
        let output = """
        foo = bar && // comment
            baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedLineInClosure() {
        let input = """
        forEach { item in
        print(item)
        }
        """
        let output = """
        forEach { item in
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedGuardInClosure() {
        let input = """
        forEach { foo in
            guard let foo = foo,
                  let bar = bar else { break }
        }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapMultilineStatementBraces, .wrapConditionalBodies],
        )
    }

    @Test func consecutiveWraps() {
        let input = """
        let a = b +
        c +
        d
        """
        let output = """
        let a = b +
            c +
            d
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrapReset() {
        let input = """
        let a = b +
        c +
        d
        let a = b +
        c +
        d
        """
        let output = """
        let a = b +
            c +
            d
        let a = b +
            c +
            d
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentElseAfterComment() {
        let input = """
        if x {}
        // comment
        else {}
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func wrappedLinesWithComments() {
        let input = """
        let foo = bar ||
         // baz||
        quux
        """
        let output = """
        let foo = bar ||
            // baz||
            quux
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func noIndentAfterAssignOperatorToVariable() {
        let input = """
        let greaterThan = >
        let lessThan = <
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentAfterDefaultAsIdentifier() {
        let input = """
        let foo = FileManager.default
        /// Comment
        let bar = 0
        """
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
    }

    @Test func indentClosureStartingOnIndentedLine() {
        let input = """
        foo
        .bar {
        baz()
        }
        """
        let output = """
        foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInVar() {
        let input = """
        var foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        var foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInLet() {
        let input = """
        let foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        let foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInTypedVar() {
        let input = """
        var: Int foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        var: Int foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentClosureStartingOnIndentedLineInTypedLet() {
        let input = """
        let: Int foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        let: Int foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func nestedWrappedIfIndents() {
        let input = """
        if foo {
        if bar &&
        (baz ||
        quux) {
        foo()
        }
        }
        """
        let output = """
        if foo {
            if bar &&
                (baz ||
                    quux) {
                foo()
            }
        }
        """
        testFormatting(
            for: input, output, rule: .indent, exclude: [
                .andOperator,
                .wrapMultilineStatementBraces,
            ],
        )
    }

    @Test func wrappedEnumThatLooksLikeIf() {
        let input = """
        foo &&
         bar.if {
        foo()
        }
        """
        let output = """
        foo &&
            bar.if {
                foo()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func chainedClosureIndents() {
        let input = """
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
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

    @Test func chainedClosureIndentsAfterIfCondition() {
        let input = """
        if foo {
        bar()
        .baz()
        }

        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        if foo {
            bar()
                .baz()
        }

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

    @Test func chainedClosureIndentsAfterIfCondition2() {
        let input = """
        if foo {
        bar()
        .baz()
        }

        foo
        .bar {
        baz()
        }.bar {
        baz()
        }
        """
        let output = """
        if foo {
            bar()
                .baz()
        }

        foo
            .bar {
                baz()
            }.bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineFunctionChains])
    }

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

    @Test func noDoubleIndentForInInsideFunction() {
        let input = """
        func foo() { // comment here
            for idx in 0 ..< 100 {
                print(idx)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noUnindentTrailingClosure() {
        let input = """
        private final class Foo {
            func animateTransition() {
                guard let fromVC = transitionContext.viewController(forKey: .from),
                      let toVC = transitionContext.viewController(forKey: .to) else {
                    return
                }

                UIView.transition(
                    with: transitionContext.containerView,
                    duration: transitionDuration(using: transitionContext),
                    options: []) {
                        fromVC.view.alpha = 0
                        transitionContext.containerView.addSubview(toVC.view)
                        toVC.view.frame = transitionContext.finalFrame(for: toVC)
                        toVC.view.alpha = 1
                    } completion: { _ in
                        transitionContext.completeTransition(true)
                        fromVC.view.removeFromSuperview()
                    }
            }
        }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapArguments, .wrapMultilineStatementBraces],
        )
    }

    @Test func indentChainedPropertiesAfterFunctionCall() {
        let input = """
        let foo = Foo(
            bar: baz
        )
        .bar
        .baz
        """
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
    }

    @Test func indentChainedPropertiesAfterFunctionCallWithXcodeIndentation() {
        let input = """
        let foo = Foo(
            bar: baz
        )
        .bar
        .baz
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    @Test func indentChainedPropertiesAfterFunctionCall2() {
        let input = """
        let foo = Foo({
            print("")
        })
        .bar
        .baz
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.trailingClosures, .propertyTypes],
        )
    }

    @Test func indentChainedPropertiesAfterFunctionCallWithXcodeIndentation2() {
        let input = """
        let foo = Foo({
            print("")
        })
        .bar
        .baz
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.trailingClosures, .propertyTypes],
        )
    }

    @Test func indentChainedMethodsAfterTrailingClosure() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar()
            .baz()
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentChainedMethodsAfterTrailingClosureWithXcodeIndentation() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar()
            .baz()
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentChainedMethodsAfterWrappedMethodAfterTrailingClosure() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar(foo: 1,
                 bar: baz ? 2 : 3)
            .baz()
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentChainedMethodsAfterWrappedMethodAfterTrailingClosureWithXcodeIndentation() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar(foo: 1,
                 bar: baz ? 2 : 3)
            .baz()
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func chainedFunctionOnNewLineWithXcodeIndentation() {
        let input = """
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        bar(a: "A", b: "B")
            .baz()!
            .quux
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func chainedFunctionOnNewLineWithXcodeIndentation2() {
        let input = """
        let foo = bar
            .baz { _ in
                true
            }
            .quux { _ in
                false
            }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func commentSeparatedChainedFunctionAfterBraceWithXcodeIndentation() {
        let input = """
        func foo() {
            bar {
                doSomething()
            }
            // baz
            .baz()
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func chainedFunctionsInPropertySetterOnNewLineWithXcodeIndentation() {
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
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func chainedFunctionsInFunctionWithReturnOnNewLineWithXcodeIndentation() {
        let input = """
        func foo() -> Bool {
        return
        bar(a: "A", b: "B")
        .baz()!
        .quux
        }
        """
        let output = """
        func foo() -> Bool {
            return
                bar(a: "A", b: "B")
                .baz()!
                .quux
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func chainedFunctionInGuardIndentation() {
        let input = """
        guard
            let baz = foo
            .bar
            .baz
        else { return }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func chainedFunctionInGuardWithXcodeIndentation() {
        let input = """
        guard
            let baz = foo
            .bar
            .baz
        else { return }
        """
        let output = """
        guard
            let baz = foo
                .bar
                .baz
        else { return }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(
            for: input, output, rule: .indent,
            options: options, exclude: [.wrapConditionalBodies],
        )
    }

    @Test func chainedFunctionInGuardIndentation2() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
              .filter { $0 == 4 }
              .isEmpty,
              yetAnotherBool
        else { return }
        """
        testFormatting(
            for: input, rule: .indent,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func chainedFunctionInGuardWithXcodeIndentation2() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
            .filter { $0 == 4 }
            .isEmpty,
            yetAnotherBool
        else { return }
        """
        // TODO: fix indent for `yetAnotherBool`
        let output = """
        guard aBool,
              anotherBool,
              aTestArray
                  .map { $0 * 2 }
                  .filter { $0 == 4 }
                  .isEmpty,
                  yetAnotherBool
        else { return }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(
            for: input, output, rule: .indent,
            options: options, exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func wrappedChainedFunctionsWithNestedScopeIndent() {
        let input = """
        var body: some View {
            VStack {
                ZStack {
                    Text()
                }
                .gesture(DragGesture()
                    .onChanged { value in
                        print(value)
                    })
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func conditionalInitArgumentIndentAfterBrace() {
        let input = """
        struct Foo: Codable {
            let value: String
            let number: Int

            enum CodingKeys: String, CodingKey {
                case value
                case number
            }

            #if DEBUG
                init(
                    value: String,
                    number: Int
                ) {
                    self.value = value
                    self.number = number
                }
            #endif
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func conditionalInitArgumentIndentAfterBraceNoIndent() {
        let input = """
        struct Foo: Codable {
            let value: String
            let number: Int

            enum CodingKeys: String, CodingKey {
                case value
                case number
            }

            #if DEBUG
            init(
                value: String,
                number: Int
            ) {
                self.value = value
                self.number = number
            }
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func conditionalCompiledWrappedChainedFunctionIndent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
                .frame(minWidth: 200)
            #elseif os(macOS)
                    .frame(minWidth: 150)
            #else
                        .frame(minWidth: 0)
            #endif
        }
        """
        let output = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
            .frame(minWidth: 200)
            #elseif os(macOS)
            .frame(minWidth: 150)
            #else
            .frame(minWidth: 0)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .indent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func conditionalCompiledWrappedChainedFunctionIndent2() {
        let input = """
        var body: some View {
            Text(
                "Hello"
            )
            #if os(macOS)
                .frame(minWidth: 200)
            #elseif os(macOS)
                    .frame(minWidth: 150)
            #else
                        .frame(minWidth: 0)
            #endif
        }
        """
        let output = """
        var body: some View {
            Text(
                "Hello"
            )
            #if os(macOS)
            .frame(minWidth: 200)
            #elseif os(macOS)
            .frame(minWidth: 150)
            #else
            .frame(minWidth: 0)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .indent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func conditionalCompiledWrappedChainedFunctionWithIfdefNoIndent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
                .frame(minWidth: 200)
            #elseif os(macOS)
                    .frame(minWidth: 150)
            #else
                        .frame(minWidth: 0)
            #endif
        }
        """
        let output = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
            .frame(minWidth: 200)
            #elseif os(macOS)
            .frame(minWidth: 150)
            #else
            .frame(minWidth: 0)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func conditionalCompiledWrappedChainedFunctionWithIfdefOutdent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
        #if os(macOS)
        .frame(minWidth: 200)
        #elseif os(macOS)
                .frame(minWidth: 150)
        #else
                    .frame(minWidth: 0)
        #endif
        }
        """
        let output = """
        var body: some View {
            VStack {
                // some view
            }
        #if os(macOS)
            .frame(minWidth: 200)
        #elseif os(macOS)
            .frame(minWidth: 150)
        #else
            .frame(minWidth: 0)
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func chainedOrOperatorsInFunctionWithReturnOnNewLine() {
        let input = """
        func foo(lhs: Bool, rhs: Bool) -> Bool {
        return
        lhs == rhs &&
        lhs == rhs &&
        lhs == rhs
        }
        """
        let output = """
        func foo(lhs: Bool, rhs: Bool) -> Bool {
            return
                lhs == rhs &&
                lhs == rhs &&
                lhs == rhs
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func wrappedSingleLineClosureOnNewLine() {
        let input = """
        func foo() {
            let bar =
                { print("foo") }
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.braces])
    }

    @Test func wrappedMultilineClosureOnNewLine() {
        let input = """
        func foo() {
            let bar =
                {
                    print("foo")
                }
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.braces])
    }

    @Test func wrappedMultilineClosureOnNewLineWithAllmanBraces() {
        let input = """
        func foo() {
            let bar =
            {
                print("foo")
            }
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.braces],
        )
    }

    @Test func indentChainedPropertiesAfterMultilineStringXcode() {
        let input = """
        let foo = \"\""
        bar
        \"\""
            .bar
            .baz
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func wrappedExpressionIndentAfterTryInClosure() {
        let input = """
        getter = { in
            try foo ??
                bar
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func noIndentTryAfterCommaInCollection() {
        let input = """
        let expectedTabs: [Pet] = [
            viewModel.bird,
            try #require(viewModel.cat),
            try #require(viewModel.dog),
            viewModel.snake,
        ]
        """
        testFormatting(for: input, rule: .indent, exclude: [.hoistTry])
    }

    @Test func indentChainedFunctionAfterTryInParens() {
        let input = """
        func fooify(_ array: [FooBar]) -> [Foo] {
            return (
                try? array
                    .filter { !$0.isBar }
                    .compactMap { $0.foo }
            ) ?? []
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentLabelledTrailingClosure() {
        let input = """
        var buttonLabel: some View {
            label()
                .if(isInline) {
                    $0.font(.hsBody)
                }
                else: {
                    $0.font(.hsControl)
                }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentLinewrappedMultipleTrailingClosures() {
        let input = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }
        completion: { finished in
            context.completeTransition(finished)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentLinewrappedMultipleTrailingClosures2() {
        let input = """
        func foo() {
            UIView.animate(withDuration: 0) {
                fromView.transform = .identity
            }
            completion: { finished in
                context.completeTransition(finished)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent comments

    @Test func commentIndenting() {
        let input = """
        /* foo
        bar */
        """
        let output = """
        /* foo
         bar */
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func commentIndentingWithTrailingClose() {
        let input = """
        /*
        foo
        */
        """
        let output = """
        /*
         foo
         */
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func commentIndentingWithTrailingClose2() {
        let input = """
        /* foo
        */
        """
        let output = """
        /* foo
         */
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func nestedCommentIndenting() {
        let input = """
        /*
         class foo() {
             /*
              * Nested comment
              */
             bar {}
         }
         */
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func nestedCommentIndenting2() {
        let input = """
        /*
        Some description;
        ```
        func foo() {
            bar()
        }
        ```
        */
        """
        let output = """
        /*
         Some description;
         ```
         func foo() {
             bar()
         }
         ```
         */
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func commentedCodeBlocksNotIndented() {
        let input = """
        func foo() {
        //    var foo: Int
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func blankCodeCommentBlockLinesNotIndented() {
        let input = """
        func foo() {
        //
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func commentedCodeAfterBracketNotIndented() {
        let input = """
        let foo = [
        //    first,
            second,
        ]
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func commentedCodeAfterBracketNotIndented2() {
        let input = """
        let foo = [first,
        //           second,
                   third]
        """
        testFormatting(for: input, rule: .indent)
    }

    // TODO: maybe need special case handling for this?
    @Test func indentWrappedTrailingComment() {
        let input = """
        let foo = 5 // a wrapped
                    // comment
                    // block
        """
        let output = """
        let foo = 5 // a wrapped
        // comment
        // block
        """
        testFormatting(for: input, output, rule: .indent)
    }

    // indent multiline strings

    @Test func simpleMultilineString() {
        let input = """
        \"\"\"
            hello
            world
        \"\"\"
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentIndentedSimpleMultilineString() {
        let input = """
        {
        \"\"\"
            hello
            world
            \"\"\"
        }
        """
        let output = """
        {
            \"\"\"
            hello
            world
            \"\"\"
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func multilineStringWithEscapedLinebreak() {
        let input = """
        \"\"\"
            hello \
            world
        \"\"\"
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultilineStringWrappedAfter() {
        let input = """
        foo(baz:
            \"\""
            baz
            \"\"")
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultilineStringInNestedCalls() {
        let input = """
        foo(bar(\"\""
        baz
        \"\""))
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultilineStringInFunctionWithfollowingArgument() {
        let input = """
        foo(bar(\"\""
        baz
        \"\"", quux: 5))
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func reduceIndentForMultilineString() {
        let input = """
        switch foo {
            case bar:
                return \"\""
                baz
                \"\""
        }
        """
        let output = """
        switch foo {
        case bar:
            return \"\""
            baz
            \"\""
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func reduceIndentForMultilineString2() {
        let input = """
            foo(\"\""
            bar
            \"\"")
        """
        let output = """
        foo(\"\""
        bar
        \"\"")
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentMultilineStringWithMultilineInterpolation() {
        let input = """
        func foo() {
            \"\""
                bar
                    \\(bar.map {
                        baz
                    })
                quux
            \"\""
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultilineStringWithMultilineNestedInterpolation() {
        let input = """
        func foo() {
            \"\""
                bar
                    \\(bar.map {
                        \"\""
                            quux
                        \"\""
                    })
                quux
            \"\""
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultilineStringWithMultilineNestedInterpolation2() {
        let input = """
        func foo() {
            \"\""
                bar
                    \\(bar.map {
                        \"\""
                            quux
                        \"\""
                    }
                    )
                quux
            \"\""
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.wrapArguments])
    }

    // indentStrings = true

    @Test func indentMultilineStringInMethod() {
        let input = #"""
        func foo() {
            let sql = """
            SELECT *
            FROM authors
            WHERE authors.name LIKE '%David%'
            """
        }
        """#
        let output = #"""
        func foo() {
            let sql = """
                SELECT *
                FROM authors
                WHERE authors.name LIKE '%David%'
                """
        }
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func noIndentMultilineStringWithOmittedReturn() {
        let input = #"""
        var string: String {
            """
            SELECT *
            FROM authors
            WHERE authors.name LIKE '%David%'
            """
        }
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func noIndentMultilineStringOnOwnLineInMethodCall() {
        let input = #"""
        #expect(loggingService.assertions == """
            My long multi-line assertion.
            This error was not recoverable.
            """)
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentMultilineStringInMethodCall() {
        let input = #"""
        #expect(loggingService.assertions == """
        My long multi-line assertion.
        This error was not recoverable.
        """)
        """#
        let output = #"""
        #expect(loggingService.assertions == """
            My long multi-line assertion.
            This error was not recoverable.
            """)
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentMultilineStringAtTopLevel() {
        let input = #"""
        let sql = """
        SELECT *
        FROM  authors,
              books
        WHERE authors.name LIKE '%David%'
             AND pubdate < $1
        """
        """#
        let output = #"""
        let sql = """
          SELECT *
          FROM  authors,
                books
          WHERE authors.name LIKE '%David%'
               AND pubdate < $1
          """
        """#
        let options = FormatOptions(indent: "  ", indentStrings: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentMultilineStringWithBlankLine() {
        let input = #"""
        let generatedClass = """
        import UIKit

        class ViewController: UIViewController { }
        """
        """#

        let output = #"""
        let generatedClass = """
            import UIKit
        \#("    ")
            class ViewController: UIViewController { }
            """
        """#
        let options = FormatOptions(truncateBlankLines: false, indentStrings: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentMultilineStringPreservesBlankLines() {
        let input = #"""
        let generatedClass = """
            import UIKit
        \#("    ")
            class ViewController: UIViewController { }
            """
        """#
        let options = FormatOptions(truncateBlankLines: false, indentStrings: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func unindentMultilineStringAtTopLevel() {
        let input = #"""
        let sql = """
          SELECT *
          FROM  authors,
                books
          WHERE authors.name LIKE '%David%'
               AND pubdate < $1
          """
        """#
        let output = #"""
        let sql = """
        SELECT *
        FROM  authors,
              books
        WHERE authors.name LIKE '%David%'
             AND pubdate < $1
        """
        """#
        let options = FormatOptions(indent: "  ", indentStrings: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentUnderIndentedMultilineStringPreservesBlankLineIndent() {
        let input = #"""
        class Main {
            func main() {
                print("""
            That've been not indented at all.
            \#n\#
            After SwiftFormat it causes a compiler error in the line above.
            """)
            }
        }
        """#
        let output = #"""
        class Main {
            func main() {
                print("""
                That've been not indented at all.
                \#n\#
                After SwiftFormat it causes a compiler error in the line above.
                """)
            }
        }
        """#
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentUnderIndentedMultilineStringDoesNotAddIndent() {
        let input = #"""
        class Main {
            func main() {
                print("""
            That've been not indented at all.

            After SwiftFormat it causes a compiler error in the line above.
            """)
            }
        }
        """#
        let output = #"""
        class Main {
            func main() {
                print("""
                That've been not indented at all.
            \#("    ")
                After SwiftFormat it causes a compiler error in the line above.
                """)
            }
        }
        """#
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    // indent multiline raw strings

    @Test func indentIndentedSimpleRawMultilineString() {
        let input = """
        {
        ##\"\"\"
            hello
            world
            \"\"\"##
        }
        """
        let output = """
        {
            ##\"\"\"
            hello
            world
            \"\"\"##
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    // indent multiline regex literals

    @Test func indentMultilineRegularExpression() {
        let input = """
        let regex = #/
            (foo+)
            [bar]*
            (baz?)
        /#
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noMisindentCasePath() {
        let input = """
        reducer.pullback(
            casePath: /Action.action,
            environment: {}
        )
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent #if/#else/#elseif/#endif

    @Test(.disabled("Indent behavior differs from upstream SwiftFormat"))
    func ifDefIndentModes() {
        let input = """
        struct ContentView: View {
            var body: some View {
                // sm:options --ifdef indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // sm:options --ifdef no-indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // sm:options --ifdef outdent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif
            }
        }
        """
        let output = """
        struct ContentView: View {
            var body: some View {
                // sm:options --ifdef indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // sm:options --ifdef no-indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // sm:options --ifdef outdent

                Text("Hello, world!")
        // Comment above
        #if os(macOS)
                    .padding()
        #endif

                Text("Hello, world!")
        #if os(macOS)
                    // Comment inside
                    .padding()
        #endif
            }
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    // indent #if/#else/#elseif/#endif (mode: indent)

    @Test func ifEndifIndenting() {
        let input = """
        #if x
        // foo
        #endif
        """
        let output = """
        #if x
            // foo
        #endif
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentedIfEndifIndenting() {
        let input = """
        {
        #if x
        // foo
        foo()
        #endif
        }
        """
        let output = """
        {
            #if x
                // foo
                foo()
            #endif
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func ifElseEndifIndenting() {
        let input = """
        #if x
            // foo
        foo()
        #else
            // bar
        #endif
        """
        let output = """
        #if x
            // foo
            foo()
        #else
            // bar
        #endif
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func enumIfCaseEndifIndenting() {
        let input = """
        enum Foo {
        case bar
        #if x
        case baz
        #endif
        }
        """
        let output = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfCaseEndifIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
        case .bar: break
        #if x
            case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfCaseEndifIndenting2() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
            case .bar: break
            #if x
                case .baz: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfCaseEndifIndenting3() {
        let input = """
        switch foo {
        #if x
        case .bar: break
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
        #if x
            case .bar: break
            case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfCaseEndifIndenting4() {
        let input = """
        switch foo {
        #if x
        case .bar:
        break
        case .baz:
        break
        #endif
        }
        """
        let output = """
        switch foo {
            #if x
                case .bar:
                    break
                case .baz:
                    break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfCaseElseCaseEndifIndenting() {
        let input = """
        switch foo {
        #if x
        case .bar: break
        #else
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
        #if x
            case .bar: break
        #else
            case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfCaseElseCaseEndifIndenting2() {
        let input = """
        switch foo {
        #if x
        case .bar: break
        #else
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
            #if x
                case .bar: break
            #else
                case .baz: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func switchIfEndifInsideCaseIndenting() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
        case .bar:
            #if x
                bar()
            #endif
            baz()
        case .baz: break
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.blankLineAfterSwitchCase],
        )
    }

    @Test func switchIfEndifInsideCaseIndenting2() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
            case .bar:
                #if x
                    bar()
                #endif
                baz()
            case .baz: break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.blankLineAfterSwitchCase],
        )
    }

    @Test func ifUnknownCaseEndifIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
            @unknown case _: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .indent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifUnknownCaseEndifIndenting2() {
        let input = """
        switch foo {
            case .bar: break
            #if x
                @unknown case _: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifEndifInsideEnumIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func ifEndifInsideEnumWithTrailingCommentIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif // ends
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentCommentBeforeIfdefAroundCase() {
        let input = """
        switch x {
        // foo
        case .foo:
            break
        // conditional
        // bar
        #if BAR
            case .bar:
                break
        // baz
        #else
            case .baz:
                break
        #endif
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentCommentedCodeBeforeIfdefAroundCase() {
        let input = """
        func foo() {
        //    foo()
            #if BAR
        //        bar()
            #else
        //        baz()
            #endif
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentIfdefFollowedByCommentAroundCase() {
        let input = """
        switch x {
        case .foo:
            break
        #if BAR
            // bar
            case .bar:
                break
        #else
            // baz
            case .baz:
                break
        #endif
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentIfDefPostfixMemberSyntax() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                .font(.largeTitle)
                #elseif os(macOS)
                        .font(.headline)
                #else
                    .font(.headline)
                #endif
            }
        }
        """
        let output = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                    .font(.largeTitle)
                #elseif os(macOS)
                    .font(.headline)
                #else
                    .font(.headline)
                #endif
            }
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentIfDefPostfixMemberSyntax2() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                    .font(.largeTitle)
                #endif
                    .color(.red)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func noIndentDotExpressionInsideIfdef() {
        let input = """
        let current: Platform = {
            #if os(macOS)
                .mac
            #elseif os(Linux)
                .linux
            #elseif os(Windows)
                .windows
            #else
                fatalError("Unknown OS not supported")
            #endif
        }()
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent #if/#else/#elseif/#endif (mode: noindent)

    @Test func ifEndifNoIndenting() {
        let input = """
        #if x
        // foo
        #endif
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentedIfEndifNoIndenting() {
        let input = """
        {
        #if x
        // foo
        #endif
        }
        """
        let output = """
        {
            #if x
            // foo
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func ifElseEndifNoIndenting() {
        let input = """
        #if x
        // foo
        #else
        // bar
        #endif
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifCaseEndifNoIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifCaseEndifNoIndenting2() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
            case .bar: break
            #if x
            case .baz: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func ifUnknownCaseEndifNoIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        @unknown case _: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifUnknownCaseEndifNoIndenting2() {
        let input = """
        switch foo {
            case .bar: break
            #if x
            @unknown case _: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifEndifInsideCaseNoIndenting() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
        case .bar:
            #if x
            bar()
            #endif
            baz()
        case .baz: break
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.blankLineAfterSwitchCase],
        )
    }

    @Test func ifEndifInsideCaseNoIndenting2() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
            case .bar:
                #if x
                bar()
                #endif
                baz()
            case .baz: break
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.blankLineAfterSwitchCase],
        )
    }

    @Test func switchCaseInIfEndif() {
        let input = """
        func baz(value: Example) -> String {
            #if DEBUG
                switch value {
                    case .foo: return "foo"
                    case .bar: return "bar"
                    @unknown default: return "unknown"
                }
            #else
                switch value {
                    case .foo: return "foo"
                    case .bar: return "bar"
                    @unknown default: return "unknown"
                }
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func switchCaseInIfEndifNoIndenting() {
        let input = """
        func baz(value: Example) -> String {
            #if DEBUG
            switch value {
                case .foo: return "foo"
                case .bar: return "bar"
                @unknown default: return "unknown"
            }
            #else
            switch value {
                case .foo: return "foo"
                case .bar: return "bar"
                @unknown default: return "unknown"
            }
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifEndifInsideEnumNoIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
            case baz
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifEndifInsideEnumWithTrailingCommentNoIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
            case baz
            #endif // ends
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxNoIndenting() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                    .font(.largeTitle)
                #elseif os(macOS)
                    .font(.headline)
                #else
                    .font(.headline)
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxNoIndenting2() {
        let input = """
        func foo() {
            Button {
                "Hello"
            }
            #if DEBUG
            .foo()
            #else
            .bar()
            #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxNoIndenting3() {
        let input = """
        func foo() {
            Text(
                "Hello"
            )
            #if DEBUG
            .foo()
            #else
            .bar()
            #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func noIndentDotInitInsideIfdef() {
        let input = """
        func myFunc() -> String {
            #if DEBUG
            .init("foo")
            #elseif PROD
            .init("bar")
            #else
            .init("baz")
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func noIndentDotInitInsideIfdef2() {
        let input = """
        var title: Font {
            #if os(iOS)
            .init(style: .title2)
            #else
            .init(style: .title2, size: 40)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxPreserveKeepsAlignment() {
        let input = """
        struct Example: View {
            var body: some View {
                Text("Example")
                    .frame(maxWidth: 500, alignment: .leading)
                    #if !os(tvOS)
                    .font(.system(size: 14, design: .monospaced))
                    #endif
                    .padding(10)
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithinIndentedChain() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithinNestedChainBlock() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithinNestedChainBlock2() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                        .overlay {
                            Color.white
                        }
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithinNestedChainBlock3() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                        .overlay {
                            Color.white
                                .mask {
                                    Circle()
                                }
                        }
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithinNestedChainBlock4() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                        .overlay {
                            Color.white
                                .mask {
                                    Circle()
                                        .overlay {
                                            Rectangle()
                                        }
                                }
                        }
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithCommentBeforeModifier() {
        let input = """
        struct ContentView: View {
            var body: some View {
                Text("Hello")
                    .frame(maxWidth: 200)
                    #if os(iOS)
                    // comment about padding
                    .padding(4)
                    #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test(.disabled("Indent behavior differs from upstream SwiftFormat"))
    func ifDefPreserveWithMultiplePlatformBranches() {
        let input = """
        import SwiftUI
        import SwiftUIIntrospect
        import Testing

        @MainActor
        @Suite
        struct NavigationViewWithColumnsStyleTests {
            #if canImport(UIKit) && (os(iOS) || os(visionOS))
            typealias PlatformNavigationViewWithColumnsStyle = UISplitViewController
            #elseif canImport(UIKit) && os(tvOS)
            typealias PlatformNavigationViewWithColumnsStyle = UINavigationController
            #elseif canImport(AppKit)
            typealias PlatformNavigationViewWithColumnsStyle = NSSplitView
            #endif

            func testIntrospect() async throws {
                try await introspection(of: PlatformNavigationViewWithColumnsStyle.self) { spy in
                    NavigationView {
                        ZStack {
                            Color.red
                            Text("Something")
                        }
                    }
                    .navigationViewStyle(DoubleColumnNavigationViewStyle())
                    #if os(iOS) || os(visionOS)
                    .introspect(.navigationView(style: .columns), on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), .visionOS(.v1, .v2, .v26), customize: spy)
                    #elseif os(tvOS)
                    .introspect(.navigationView(style: .columns), on: .tvOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), customize: spy)
                    #elseif os(macOS)
                    .introspect(.navigationView(style: .columns), on: .macOS(.v10_15, .v11, .v12, .v13, .v14, .v15, .v26), customize: spy)
                    #endif
                }
            }

            func testIntrospectAsAncestor() async throws {
                try await introspection(of: PlatformNavigationViewWithColumnsStyle.self) { spy in
                    NavigationView {
                        ZStack {
                            Color.red
                            Text("Something")
                            #if os(iOS) || os(visionOS)
                            .introspect(.navigationView(style: .columns), on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), .visionOS(.v1, .v2, .v26), scope: .ancestor, customize: spy)
                            #elseif os(tvOS)
                            .introspect(.navigationView(style: .columns), on: .tvOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), scope: .ancestor, customize: spy)
                            #elseif os(macOS)
                            .introspect(.navigationView(style: .columns), on: .macOS(.v10_15, .v11, .v12, .v13, .v14, .v15, .v26), scope: .ancestor, customize: spy)
                            #endif
                        }
                    }
                    .navigationViewStyle(DoubleColumnNavigationViewStyle())
                    #if os(iOS)
                    // NB: this is necessary for ancestor introspection to work, because initially on iPad the "Customized" text isn't shown as it's hidden in the sidebar. This is why ancestor introspection is discouraged for most situations and it's opt-in.
                    .introspect(.navigationView(style: .columns), on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26)) {
                        $0.preferredDisplayMode = .oneOverSecondary
                    }
                    #endif
                }
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveMultipleModifiersInChain() {
        let input = """
        struct ContentView: View {
            var body: some View {
                Text("Example")
                    .frame(maxWidth: 200)
                    #if os(iOS)
                    .padding(4)
                    .background {
                        Color.red
                            .overlay {
                                Text("Inner")
                            }
                    }
                    .cornerRadius(8)
                    #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPreserveWithElseIfBranches() {
        let input = """
        struct ContentView: View {
            var body: some View {
                Text("Example")
                    .frame(maxWidth: 200)
                    #if os(iOS)
                    .padding(4)
                        .background {
                            Color.red
                        }
                    #elseif os(macOS)
                    .padding(10)
                        .background {
                            Color.blue
                                .overlay {
                                    Circle()
                                }
                        }
                    #else
                    .foregroundColor(.gray)
                    .shadow(radius: 2)
                    #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent #if/#else/#elseif/#endif (mode: outdent)

    @Test func ifEndifOutdenting() {
        let input = """
        #if x
        // foo
        #endif
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentedIfEndifOutdenting() {
        let input = """
        {
        #if x
        // foo
        #endif
        }
        """
        let output = """
        {
        #if x
            // foo
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func ifElseEndifOutdenting() {
        let input = """
        #if x
        // foo
        #else
        // bar
        #endif
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentedIfElseEndifOutdenting() {
        let input = """
        {
        #if x
        // foo
        foo()
        #else
        // bar
        #endif
        }
        """
        let output = """
        {
        #if x
            // foo
            foo()
        #else
            // bar
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func ifElseifEndifOutdenting() {
        let input = """
        #if x
        // foo
        #elseif y
        // bar
        #endif
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentedIfElseifEndifOutdenting() {
        let input = """
        {
        #if x
        // foo
        foo()
        #elseif y
        // bar
        #endif
        }
        """
        let output = """
        {
        #if x
            // foo
            foo()
        #elseif y
            // bar
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func nestedIndentedIfElseifEndifOutdenting() {
        let input = """
        {
        #if x
        #if y
        // foo
        foo()
        #elseif y
        // bar
        #endif
        #endif
        }
        """
        let output = """
        {
        #if x
        #if y
            // foo
            foo()
        #elseif y
            // bar
        #endif
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func doubleNestedIndentedIfElseifEndifOutdenting() {
        let input = """
        {
        #if x
        #if y
        #if z
        // foo
        foo()
        #elseif y
        // bar
        #endif
        #endif
        #endif
        }
        """
        let output = """
        {
        #if x
        #if y
        #if z
            // foo
            foo()
        #elseif y
            // bar
        #endif
        #endif
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func ifCaseEndifOutdenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifEndifInsideEnumOutdenting() {
        let input = """
        enum Foo {
            case bar
        #if x
            case baz
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifEndifInsideEnumWithTrailingCommentOutdenting() {
        let input = """
        enum Foo {
            case bar
        #if x
            case baz
        #endif // ends
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxOutdenting() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
        #if os(iOS)
                    .font(.largeTitle)
        #elseif os(macOS)
                    .font(.headline)
        #else
                    .font(.headline)
        #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxOutdenting2() {
        let input = """
        func foo() {
            Button {
                "Hello"
            }
        #if DEBUG
            .foo()
        #else
            .bar()
        #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func ifDefPostfixMemberSyntaxOutdenting3() {
        let input = """
        func foo() {
            Text(
                "Hello"
            )
        #if DEBUG
            .foo()
        #else
            .bar()
        #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent expression after return

    @Test func indentIdentifierAfterReturn() {
        let input = """
        if foo {
            return
                bar
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentEnumValueAfterReturn() {
        let input = """
        if foo {
            return
                .bar
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMultilineExpressionAfterReturn() {
        let input = """
        if foo {
            return
                bar +
                baz
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func dontIndentClosingBraceAfterReturn() {
        let input = """
        if foo {
            return
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func dontIndentCaseAfterReturn() {
        let input = """
        switch foo {
        case bar:
            return
        case baz:
            return
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func dontIndentCaseAfterWhere() {
        let input = """
        switch foo {
        case bar
        where baz:
        return
        default:
        return
        }
        """
        let output = """
        switch foo {
        case bar
            where baz:
            return
        default:
            return
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func dontIndentIfAfterReturn() {
        let input = """
        if foo {
            return
            if bar {}
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func dontIndentFuncAfterReturn() {
        let input = """
        if foo {
            return
            func bar() {}
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent fragments

    @Test func indentFragment() {
        let input = """
           func foo() {
        bar()
        }
        """
        let output = """
           func foo() {
               bar()
           }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func indentFragmentAfterBlankLines() {
        let input = """

           func foo() {
        bar()
        }
        """
        let output = """

           func foo() {
               bar()
           }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func unterminatedFragment() {
        let input = """
        class Foo {

          func foo() {
        bar()
        }
        """
        let output = """
        class Foo {

            func foo() {
                bar()
            }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(
            for: input, output, rule: .indent, options: options,
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func overTerminatedFragment() {
        let input = """
           func foo() {
        bar()
        }

        }
        """
        let output = """
           func foo() {
               bar()
           }

        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func dontCorruptPartialFragment() {
        let input = """
            } foo {
                bar
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func dontCorruptPartialFragment2() {
        let input = """
                return completionHandler(nil)
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func dontCorruptPartialFragment3() {
        let input = """
            foo: bar,
            foo1: bar2,
            foo2: bar3
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent with tabs

    @Test func tabIndentWrappedTupleWithSmartTabs() {
        let input = """
        let foo = (bar: Int,
                   baz: Int)
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func tabIndentWrappedTupleWithoutSmartTabs() {
        let input = """
        let foo = (bar: Int,
                   baz: Int)
        """
        let output = """
        let foo = (bar: Int,
        \t\t\t\t\t baz: Int)
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    @Test func tabIndentCaseWithSmartTabs() {
        let input = """
        switch x {
        case .foo,
             .bar:
          break
        }
        """
        let output = """
        switch x {
        case .foo,
             .bar:
        \tbreak
        }
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
        testFormatting(
            for: input,
            output,
            rule: .indent,
            options: options,
            exclude: [.sortSwitchCases],
        )
    }

    @Test func tabIndentCaseWithoutSmartTabs() {
        let input = """
        switch x {
        case .foo,
             .bar:
          break
        }
        """
        let output = """
        switch x {
        case .foo,
        \t\t .bar:
        \tbreak
        }
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: false)
        testFormatting(
            for: input,
            output,
            rule: .indent,
            options: options,
            exclude: [.sortSwitchCases],
        )
    }

    @Test func tabIndentCaseWithoutSmartTabs2() {
        let input = """
        switch x {
            case .foo,
                 .bar:
              break
        }
        """
        let output = """
        switch x {
        \tcase .foo,
        \t\t\t .bar:
        \t\tbreak
        }
        """
        let options = FormatOptions(
            indent: "\t", indentCase: true,
            tabWidth: 2, smartTabs: false,
        )
        testFormatting(
            for: input,
            output,
            rule: .indent,
            options: options,
            exclude: [.sortSwitchCases],
        )
    }

    // indent blank lines

    @Test func truncateBlankLineBeforeIndenting() throws {
        let input = """
        func foo() {
        \tguard bar = baz else { return }
        \t
        \tquux()
        }
        """
        let options = FormatOptions(indent: "\t", truncateBlankLines: true, tabWidth: 2)
        #expect(
            try lint(input, rules: [.indent, .trailingSpace], options: options) == [
                Formatter.Change(line: 3, rule: .trailingSpace, filePath: nil, isMove: false),
            ],
        )
    }

    @Test func noIndentBlankLinesIfTrimWhitespaceDisabled() {
        let input = """
        func foo() {
        \tguard bar = baz else { return }
        \t

        \tquux()
        }
        """
        let options = FormatOptions(indent: "\t", truncateBlankLines: false, tabWidth: 2)
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [
                .consecutiveBlankLines,
                .wrapConditionalBodies,
                .blankLinesAfterGuardStatements,
            ],
        )
    }

    // async

    @Test func asyncThrowsNotUnindented() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws -> String {}
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func asyncTypedThrowsNotUnindented() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws(Foo) -> String {}
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentAsyncLet() {
        let input = """
        func foo() async {
                async let bar = baz()
        async let baz = quux()
        }
        """
        let output = """
        func foo() async {
            async let bar = baz()
            async let baz = quux()
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentAsyncLetAfterLet() {
        let input = """
        func myFunc() {
            let x = 1
            async let foo = bar()
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentAsyncLetAfterBrace() {
        let input = """
        func myFunc() {
            let x = 1
            enum Baz {
                case foo
            }
            async let foo = bar()
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func asyncFunctionArgumentLabelNotIndented() {
        let input = """
        func multilineFunction(
            foo _: String,
            async _: String)
            -> String {}
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentIfExpressionAssignmentOnNextLine() {
        let input = """
        let foo =
        if let bar = someBar {
            bar
        } else if let baaz = someBaaz {
            baaz
        } else if let quux = someQuux {
            if let foo = someFoo {
                foo
            } else {
                quux
            }
        } else {
            foo2
        }

        print(foo)
        """

        let output = """
        let foo =
            if let bar = someBar {
                bar
            } else if let baaz = someBaaz {
                baaz
            } else if let quux = someQuux {
                if let foo = someFoo {
                    foo
                } else {
                    quux
                }
            } else {
                foo2
            }

        print(foo)
        """

        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    @Test func indentIfExpressionAssignmentOnSameLine() {
        let input = """
        let foo = if let bar {
            bar
        } else if let baaz {
            baaz
        } else if let quux {
            if let foo {
                foo
            } else {
                quux
            }
        }
        """

        testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineConditionalAssignment])
    }

    @Test func indentSwitchExpressionAssignment() {
        let input = """
        let foo =
        switch bar {
        case true:
            bar
        case baaz:
            baaz
        }
        """

        let output = """
        let foo =
            switch bar {
            case true:
                bar
            case baaz:
                baaz
            }
        """

        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentSwitchExpressionAssignmentInNestedScope() {
        let input = """
        class Foo {
            func foo() -> Foo {
                let foo =
                switch bar {
                case true:
                    bar
                case baaz:
                    baaz
                }

                return foo
            }
        }
        """

        let output = """
        class Foo {
            func foo() -> Foo {
                let foo =
                    switch bar {
                    case true:
                        bar
                    case baaz:
                        baaz
                    }

                return foo
            }
        }
        """

        testFormatting(for: input, output, rule: .indent, exclude: [.redundantProperty])
    }

    @Test func indentNestedSwitchExpressionAssignment() {
        let input = """
        let foo =
        switch bar {
        case true:
            bar
        case baaz:
            switch bar {
            case true:
                bar
            case baaz:
                baaz
            }
        }
        """

        let output = """
        let foo =
            switch bar {
            case true:
                bar
            case baaz:
                switch bar {
                case true:
                    bar
                case baaz:
                    baaz
                }
            }
        """

        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentSwitchExpressionAssignmentWithComments() {
        let input = """
        let foo =
        // There is a comment before the switch statement
        switch bar {
        // Plus a comment before each case
        case true:
            bar
        // Plus a comment before each case
        case baaz:
            baaz
        }

        print(foo)
        """

        let output = """
        let foo =
            // There is a comment before the switch statement
            switch bar {
            // Plus a comment before each case
            case true:
                bar
            // Plus a comment before each case
            case baaz:
                baaz
            }

        print(foo)
        """

        testFormatting(for: input, output, rule: .indent)
    }

    @Test func indentIfExpressionWithSingleComment() {
        let input = """
        let foo =
            // There is a comment before the first branch
            if let foo {
                foo
            } else {
                bar
            }

        print(foo)
        """

        testFormatting(for: input, rule: .indent)
    }

    @Test func indentIfExpressionWithComments() {
        let input = """
        let foo =
            // There is a comment before the first branch
            if let foo {
                foo
            }
            // There is a comment before the second branch
            else {
                bar
            }

        print(foo)
        """

        testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    @Test func indentMultilineIfExpression() {
        let input = """
        let foo =
            if
                let foo,
                foo != disallowedFoo
            {
                foo
            }
            // There is a comment before the second branch
            else {
                bar
            }

        print(foo)
        print(foo)
        """

        testFormatting(for: input, rule: .indent, exclude: [.braces])
    }

    @Test func indentNestedIfExpressionWithComments() {
        let input = """
        let foo =
            // There is a comment before the first branch
            if let foo {
                foo
            }
            // There is a comment before the second branch
            else {
                // And a comment before each of these nested branches
                if let bar {
                    bar
                }
                // And a comment before each of these nested branches
                else {
                    baaz
                }
            }

        print(foo)
        """

        testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    @Test func indentIfExpressionWithMultilineComments() {
        let input = """
        let foo =
            // There is a comment before the first branch
            // which spans across multiple lines
            if let foo {
                foo
            }
            // And also a comment before the second branch
            // which spans across multiple lines
            else {
                bar
            }
        """

        testFormatting(for: input, rule: .indent)
    }

    @Test func sE0380Example() {
        let input = """
        let bullet =
            if isRoot && (count == 0 || !willExpand) { "" }
            else if count == 0 { "- " }
            else if maxDepth <= 0 { "▹ " }
            else { "▿ " }

        print(bullet)
        """
        let options = FormatOptions()
        testFormatting(
            for: input, rule: .indent, options: options,
            exclude: [.wrapConditionalBodies, .andOperator, .redundantParens],
        )
    }

    @Test func wrappedTernaryOperatorIndentsChainedCalls() {
        let input = """
        let ternary = condition
            ? values
                .map { $0.bar }
                .filter { $0.hasFoo }
                .last
            : other.values
                .compactMap { $0 }
                .first?
                .with(property: updatedValue)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, rule: .indent, options: options)
    }

    @Test func indentSwitchCaseWhere() {
        let input = """
        switch testKey {
            case "organization"
            where testValues.map(String.init).compactMap { try? Entity.ID($0, format: .number) }
            .contains(Self.sessionInteractor.stage.value?.membership?.organization.id ?? .zero): // 2
                continue

            case "user"
            where testValues.map(String.init).compactMap { try? Entity.ID($0, format: .number) }
            .contains(Self.sessionInteractor.stage.value?.session?.user.id ?? .zero): // 3
                continue
        }
        """

        let options = FormatOptions(indentCase: true)
        testFormatting(
            for: input, rule: .indent, options: options, exclude: [
                .wrap,
                .wrapMultilineFunctionChains,
            ],
        )
    }

    @Test func guardElseIndentAfterParenthesizedExpression() {
        let input = """
        func format() {
            guard
                let result = foo(
                    bar: 5,
                    baz: 6
                )
            else {
                return
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func guardElseIndentAfterSwitchExpression() {
        let input = """
        func format(foo: String?) {
            guard
                let result =
                    switch foo {
                    case .none: "none"
                    case .some: "some"
                    }
            else {
                return
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func guardElseIndentAfterIfExpression() {
        let input = """
        func format(foo: Bool) {
            guard
                let result =
                    if foo {
                        bar
                    } else {
                        nil
                    }
            else {
                return
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func ifElseIndentAfterSwitchExpression() {
        let input = """
        func format(foo: String?) {
            if
                let result =
                    switch foo {
                    case .none: "none"
                    case .some: "some"
                    }
            {
                return true
            } else {
                return false
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentConditionalCompiledMacroInvocations() {
        let input = """
        #if true
            #warning("Warning")
        #else
            #warning("Warning")
        #endif
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func indentMacroInvocationsInCollection() {
        let input = """
        let urls = [
            googleURL,
            #URL("github.com"),
            #URL("apple.com"),
        ]
        """
        testFormatting(for: input, rule: .indent)
    }

    @Test func returnMacroInvocation() {
        let input = """
        func foo() {
            return
            #URL("github.com")
        }
        """
        let output = """
        func foo() {
            return
                #URL("github.com")
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }
}
