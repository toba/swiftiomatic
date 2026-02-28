import Testing
@testable import Swiftiomatic

@Suite struct RedundantSelfTests {
    // explicitSelf = .remove

    @Test func simpleRemoveRedundantSelf() {
        let input = """
        func foo() { self.bar() }
        """
        let output = """
        func foo() { bar() }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func removeSelfInsideStringInterpolation() {
        let input = """
        class Foo {
            var bar: String?
            func baz() {
                print(\"\\(self.bar)\")
            }
        }
        """
        let output = """
        class Foo {
            var bar: String?
            func baz() {
                print(\"\\(bar)\")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func noRemoveSelfForArgument() {
        let input = """
        func foo(bar: Int) { self.bar = bar }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveSelfForLocalVariable() {
        let input = """
        func foo() { var bar = self.bar }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func removeSelfForLocalVariableOn5_4() {
        let input = """
        func foo() { var bar = self.bar }
        """
        let output = """
        func foo() { var bar = bar }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: options, exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noRemoveSelfForCommaDelimitedLocalVariables() {
        let input = """
        func foo() { let foo = self.foo, bar = self.bar }
        """
        testFormatting(
            for: input, rule: .redundantSelf, exclude: [
                .singlePropertyPerLine,
                .wrapFunctionBodies,
            ],
        )
    }

    @Test func removeSelfForCommaDelimitedLocalVariablesOn5_4() {
        let input = """
        func foo() { let foo = self.foo, bar = self.bar }
        """
        let output = """
        func foo() { let foo = self.foo, bar = bar }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: options, exclude: [.singlePropertyPerLine, .wrapFunctionBodies],
        )
    }

    @Test func noRemoveSelfForCommaDelimitedLocalVariables2() {
        let input = """
        func foo() {
            let foo: Foo, bar: Bar
            foo = self.foo
            bar = self.bar
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine])
    }

    @Test func noRemoveSelfForTupleAssignedVariables() {
        let input = """
        func foo() { let (bar, baz) = (self.bar, self.baz) }
        """
        testFormatting(
            for: input, rule: .redundantSelf, exclude: [
                .singlePropertyPerLine,
                .wrapFunctionBodies,
            ],
        )
    }

    // TODO: make this work
    //    func testRemoveSelfForTupleAssignedVariablesOn5_4() {
    //        let input = "func foo() { let (bar, baz) = (self.bar, self.baz) }"
    //        let output = "func foo() { let (bar, baz) = (bar, baz) }"
    //        let options = FormatOptions(swiftVersion: "5.4")
    //        testFormatting(for: input, output, rule: .redundantSelf,
    //                       options: options)
    //    }

    @Test func noRemoveSelfForTupleAssignedVariablesFollowedByRegularVariable() {
        let input = """
        func foo() {
            let (foo, bar) = (self.foo, self.bar), baz = self.baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine])
    }

    @Test func noRemoveSelfForTupleAssignedVariablesFollowedByRegularLet() {
        let input = """
        func foo() {
            let (foo, bar) = (self.foo, self.bar)
            let baz = self.baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine])
    }

    @Test func noRemoveNonRedundantNestedFunctionSelf() {
        let input = """
        func foo() { func bar() { self.bar() } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveNonRedundantNestedFunctionSelf2() {
        let input = """
        func foo() {
            func bar() {}
            self.bar()
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveNonRedundantNestedFunctionSelf3() {
        let input = """
        func foo() { let bar = 5; func bar() { self.bar = bar } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveClosureSelf() {
        let input = """
        func foo() { bar { self.bar = 5 } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveSelfAfterOptionalReturn() {
        let input = """
        func foo() -> String? {
            var index = startIndex
            if !matching(self[index]) {
                break
            }
            index = self.index(after: index)
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveRequiredSelfInExtensions() {
        let input = """
        extension Foo {
            func foo() {
                var index = 5
                if true {
                    break
                }
                index = self.index(after: index)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfBeforeInit() {
        let input = """
        convenience init() { self.init(5) }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func removeSelfInsideSwitch() {
        let input = """
        func foo() {
            switch self.bar {
            case .foo:
                self.baz()
            }
        }
        """
        let output = """
        func foo() {
            switch bar {
            case .foo:
                baz()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func removeSelfInsideSwitchWhere() {
        let input = """
        func foo() {
            switch self.bar {
            case .foo where a == b:
                self.baz()
            }
        }
        """
        let output = """
        func foo() {
            switch bar {
            case .foo where a == b:
                baz()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func removeSelfInsideSwitchWhereAs() {
        let input = """
        func foo() {
            switch self.bar {
            case .foo where a == b as C:
                self.baz()
            }
        }
        """
        let output = """
        func foo() {
            switch bar {
            case .foo where a == b as C:
                baz()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func removeSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() { self.bar = 6 }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            init() { bar = 6 }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveSelfInClosureInsideIf() {
        let input = """
        if foo { bar { self.baz() } }
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func noRemoveSelfForErrorInCatch() {
        let input = """
        do {} catch { self.error = error }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfForErrorInDoThrowsCatch() {
        let input = """
        do throws(Foo) {} catch { self.error = error }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfForNewValueInSet() {
        let input = """
        var foo: Int { set { self.newValue = newValue } get { return 0 } }
        """
        testFormatting(
            for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noRemoveSelfForCustomNewValueInSet() {
        let input = """
        var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }
        """
        testFormatting(
            for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noRemoveSelfForNewValueInWillSet() {
        let input = """
        var foo: Int { willSet { self.newValue = newValue } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
    }

    @Test func noRemoveSelfForCustomNewValueInWillSet() {
        let input = """
        var foo: Int { willSet(n00b) { self.n00b = n00b } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
    }

    @Test func noRemoveSelfForOldValueInDidSet() {
        let input = """
        var foo: Int { didSet { self.oldValue = oldValue } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
    }

    @Test func noRemoveSelfForCustomOldValueInDidSet() {
        let input = """
        var foo: Int { didSet(oldz) { self.oldz = oldz } }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
    }

    @Test func noRemoveSelfForIndexVarInFor() {
        let input = """
        for foo in bar { self.foo = foo }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    @Test func noRemoveSelfForKeyValueTupleInFor() {
        let input = """
        for (foo, bar) in baz { self.foo = foo; self.bar = bar }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    @Test func removeSelfFromComputedVar() {
        let input = """
        var foo: Int { return self.bar }
        """
        let output = """
        var foo: Int { return bar }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func removeSelfFromOptionalComputedVar() {
        let input = """
        var foo: Int? { return self.bar }
        """
        let output = """
        var foo: Int? { return bar }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func removeSelfFromNamespacedComputedVar() {
        let input = """
        var foo: Swift.String { return self.bar }
        """
        let output = """
        var foo: Swift.String { return bar }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func removeSelfFromGenericComputedVar() {
        let input = """
        var foo: Foo<Int> { return self.bar }
        """
        let output = """
        var foo: Foo<Int> { return bar }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func removeSelfFromComputedArrayVar() {
        let input = """
        var foo: [Int] { return self.bar }
        """
        let output = """
        var foo: [Int] { return bar }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func removeSelfFromVarSetter() {
        let input = """
        var foo: Int { didSet { self.bar() } }
        """
        let output = """
        var foo: Int { didSet { bar() } }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
    }

    @Test func noRemoveSelfFromVarClosure() {
        let input = """
        var foo = { self.bar }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfFromLazyVar() {
        let input = """
        lazy var foo = self.bar
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func removeSelfFromLazyVar() {
        let input = """
        lazy var foo = self.bar
        """
        let output = """
        lazy var foo = bar
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func removeSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        let output = """
        var baz = bar
        lazy var foo = bar
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfFromLazyVarClosure() {
        let input = """
        lazy var foo = { self.bar }()
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.redundantClosure])
    }

    @Test func noRemoveSelfFromLazyVarClosure2() {
        let input = """
        lazy var foo = { let bar = self.baz }()
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfFromLazyVarClosure3() {
        let input = """
        lazy var foo = { [unowned self] in let bar = self.baz }()
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func removeSelfFromVarInFuncWithUnusedArgument() {
        let input = """
        func foo(bar _: Int) { self.baz = 5 }
        """
        let output = """
        func foo(bar _: Int) { baz = 5 }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func removeSelfFromVarMatchingUnusedArgument() {
        let input = """
        func foo(bar _: Int) { self.bar = 5 }
        """
        let output = """
        func foo(bar _: Int) { bar = 5 }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveSelfFromVarMatchingRenamedArgument() {
        let input = """
        func foo(bar baz: Int) { self.baz = baz }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveSelfFromVarRedeclaredInSubscope() {
        let input = """
        func foo() {
            if quux {
                let bar = 5
            }
            let baz = self.bar
        }
        """
        let output = """
        func foo() {
            if quux {
                let bar = 5
            }
            let baz = bar
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func noRemoveSelfFromVarDeclaredLaterInScope() {
        let input = """
        func foo() {
            let bar = self.baz
            let baz = quux
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfFromVarDeclaredLaterInOuterScope() {
        let input = """
        func foo() {
            if quux {
                let bar = self.baz
            }
            let baz = 6
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInWhilePreceededByVarDeclaration() {
        let input = """
        var index = start
        while index < end {
            index = self.index(after: index)
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInLocalVarPrecededByLocalVarFollowedByIfComma() {
        let input = """
        func foo() {
            let bar = Bar()
            let baz = Baz()
            self.baz = baz
            if let bar = bar, bar > 0 {}
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInLocalVarPrecededByIfLetContainingClosure() {
        let input = """
        func foo() {
            if let bar = 5 { baz { _ in } }
            let quux = self.quux
        }
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func noRemoveSelfForVarCreatedInGuardScope() {
        let input = """
        func foo() {
            guard let bar = 5 else {}
            let baz = self.bar
        }
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func removeSelfForVarCreatedInIfScope() {
        let input = """
        func foo() {
            if let bar = bar {}
            let baz = self.bar
        }
        """
        let output = """
        func foo() {
            if let bar = bar {}
            let baz = bar
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func noRemoveSelfForVarDeclaredInWhileCondition() {
        let input = """
        while let foo = bar { self.foo = foo }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    @Test func removeSelfForVarNotDeclaredInWhileCondition() {
        let input = """
        while let foo == bar { self.baz = 5 }
        """
        let output = """
        while let foo == bar { baz = 5 }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    @Test func noRemoveSelfForVarDeclaredInSwitchCase() {
        let input = """
        switch foo {
        case bar: let baz = self.baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfAfterGenericInit() {
        let input = """
        init(bar: Int) {
            self = Foo<Bar>()
            self.bar(bar)
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func removeSelfInClassFunction() {
        let input = """
        class Foo {
            class func foo() {
                func bar() { self.foo() }
            }
        }
        """
        let output = """
        class Foo {
            class func foo() {
                func bar() { foo() }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func removeSelfInStaticFunction() {
        let input = """
        struct Foo {
            static func foo() {
                func bar() { self.foo() }
            }
        }
        """
        let output = """
        struct Foo {
            static func foo() {
                func bar() { foo() }
            }
        }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [
                .enumNamespaces,
                .wrapFunctionBodies,
            ],
        )
    }

    @Test func removeSelfInClassFunctionWithModifiers() {
        let input = """
        class Foo {
            class private func foo() {
                func bar() { self.foo() }
            }
        }
        """
        let output = """
        class Foo {
            class private func foo() {
                func bar() { foo() }
            }
        }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf,
            exclude: [.modifierOrder, .wrapFunctionBodies],
        )
    }

    @Test func noRemoveSelfInClassFunction() {
        let input = """
        class Foo {
            class func foo() {
                var foo: Int
                func bar() { self.foo() }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveSelfForVarDeclaredAfterRepeatWhile() {
        let input = """
        class Foo {
            let foo = 5
            func bar() {
                repeat {} while foo
                let foo = 6
                self.foo()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfForVarInClosureAfterRepeatWhile() {
        let input = """
        class Foo {
            let foo = 5
            func bar() {
                repeat {} while foo
                ({ self.foo() })()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInClosureAfterVar() {
        let input = """
        var foo: String
        bar { self.baz() }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInClosureAfterNamespacedVar() {
        let input = """
        var foo: Swift.String
        bar { self.baz() }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInClosureAfterOptionalVar() {
        let input = """
        var foo: String?
        bar { self.baz() }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInClosureAfterGenericVar() {
        let input = """
        var foo: Foo<Int>
        bar { self.baz() }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInClosureAfterArray() {
        let input = """
        var foo: [Int]
        bar { self.baz() }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInExpectFunction() {
        let input = """
        class FooTests: XCTestCase {
            let foo = 1
            func testFoo() {
                expect(self.foo) == 1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveNestedSelfInExpectFunction() {
        let input = """
        func testFoo() {
            expect(Foo.validate(bar: self.bar)).to(equal(1))
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

}
