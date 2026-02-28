import Testing
@testable import Swiftiomatic

extension RedundantSelfTests {
    @Test func noRemoveNestedSelfInArrayInExpectFunction() {
        let input = """
        func testFoo() {
            expect(Foo.validate(bar: [self.bar])).to(equal(1))
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveNestedSelfInSubscriptInExpectFunction() {
        let input = """
        func testFoo() {
            expect(Foo.validations[self.bar]).to(equal(1))
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfInOSLogFunction() {
        let input = """
        func testFoo() {
            os_log("error: \\(self.bar) is nil")
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfInExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                log(self.foo)
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfForExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                self.log(foo)
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfInInterpolatedStringInExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                log("\\(self.foo)")
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfInExcludedInitializer() {
        let input = """
        let vc = UIHostingController(rootView: InspectionView(inspection: self.inspection))
        """
        let options = FormatOptions(selfRequired: ["InspectionView"])
        testFormatting(
            for: input,
            rule: .redundantSelf,
            options: options,
            exclude: [.propertyTypes],
        )
    }

    @Test func selfRemovedFromSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func switchCaseLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let baz:
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func switchCaseHoistedLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let .foo(baz):
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func switchCaseWhereMemberNotTreatedAsVar() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfNotRemovedInClosureAfterSwitch() {
        let input = """
        switch x {
        default:
            break
        }
        let foo = { y in
            switch y {
            default:
                self.bar()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfNotRemovedInClosureInCaseWithWhereClause() {
        let input = """
        switch foo {
        case bar where baz:
            quux = { self.foo }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfRemovedInDidSet() {
        let input = """
        class Foo {
            var bar = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func selfNotRemovedInGetter() {
        let input = """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfNotRemovedInIfdef() {
        let input = """
        func foo() {
            #if os(macOS)
                let bar = self.bar
            #endif
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfRemovedWhenFollowedBySwitchContainingIfdef() {
        let input = """
        struct Foo {
            func bar() {
                self.method(self.value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                method(value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func redundantSelfRemovedInsideConditionalCase() {
        let input = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        self.method1(self.value)
                #else
                    case .quux:
                        self.method2(self.value)
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        method1(value)
                #else
                    case .quux:
                        self.method2(value)
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func redundantSelfRemovedAfterConditionalLet() {
        let input = """
        class Foo {
            var bar: Int?
            var baz: Bool

            func foo() {
                if let bar = bar, self.baz {
                    // ...
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int?
            var baz: Bool

            func foo() {
                if let bar = bar, baz {
                    // ...
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func nestedClosureInNotMistakenForForLoop() {
        let input = """
        func f() {
            let str = "hello"
            try! str.withCString(encodedAs: UTF8.self) { _ throws in
                try! str.withCString(encodedAs: UTF8.self) { _ throws in }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func typedThrowingNestedClosureInNotMistakenForForLoop() {
        let input = """
        func f() {
            let str = "hello"
            try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in
                try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfPreservesSelfInClosureWithExplicitStrongCaptureBefore5_3() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [self] in
                    print(self.bar)
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfRemovesSelfInClosureWithExplicitStrongCapture() {
        let input = """
        class Foo {
            let foo: Int

            func baaz() {
                closure { [self, bar] baaz, quux in
                    print(self.foo)
                }
            }
        }
        """

        let output = """
        class Foo {
            let foo: Int

            func baaz() {
                closure { [self, bar] baaz, quux in
                    print(foo)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(
            for: input, output, rule: .redundantSelf, options: options, exclude: [.unusedArguments],
        )
    }

    @Test func redundantSelfRemovesSelfInClosureWithNestedExplicitStrongCapture() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(self.bar)
                    closure { [self] in
                        print(self.bar)
                    }
                    print(self.bar)
                }
            }
        }
        """

        let output = """
        class Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(self.bar)
                    closure { [self] in
                        print(bar)
                    }
                    print(self.bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfKeepsSelfInNestedClosureWithNoExplicitStrongCapture() {
        let input = """
        class Foo {
            let bar: Int
            let baaz: Int?

            func baaz() {
                closure { [self] in
                    print(self.bar)
                    closure {
                        print(self.bar)
                        if let baaz = self.baaz {
                            print(baaz)
                        }
                    }
                    print(self.bar)
                    if let baaz = self.baaz {
                        print(baaz)
                    }
                }
            }
        }
        """

        let output = """
        class Foo {
            let bar: Int
            let baaz: Int?

            func baaz() {
                closure { [self] in
                    print(bar)
                    closure {
                        print(self.bar)
                        if let baaz = self.baaz {
                            print(baaz)
                        }
                    }
                    print(bar)
                    if let baaz = baaz {
                        print(baaz)
                    }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfRemovesSelfInClosureCapturingStruct() {
        let input = """
        struct Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(self.bar)
                }
            }
        }
        """

        let output = """
        struct Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfRemovesSelfInClosureCapturingSelfWeakly() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [weak self] in
                    print(self?.bar)
                    guard let self else {
                        return
                    }
                    print(self.bar)
                    closure {
                        print(self.bar)
                    }
                    closure { [self] in
                        print(self.bar)
                    }
                    print(self.bar)
                }

                closure { [weak self] in
                    guard let self = self else {
                        return
                    }

                    print(self.bar)
                }

                closure { [weak self] in
                    guard let self = self ?? somethingElse else {
                        return
                    }

                    print(self.bar)
                }
            }
        }
        """

        let output = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [weak self] in
                    print(self?.bar)
                    guard let self else {
                        return
                    }
                    print(bar)
                    closure {
                        print(self.bar)
                    }
                    closure { [self] in
                        print(bar)
                    }
                    print(bar)
                }

                closure { [weak self] in
                    guard let self = self else {
                        return
                    }

                    print(bar)
                }

                closure { [weak self] in
                    guard let self = self ?? somethingElse else {
                        return
                    }

                    print(self.bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: options, exclude: [.redundantOptionalBinding, .blankLinesAfterGuardStatements],
        )
    }

    @Test func weakSelfNotRemovedIfNotUnwrapped() {
        let input = """
        class A {
            weak var delegate: ADelegate?

            func testFunction() {
                DispatchQueue.main.async { [weak self] in
                    self.flatMap { $0.delegate?.aDidSomething($0) }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func closureParameterListShadowingPropertyOnSelf() {
        let input = """
        class Foo {
            var bar = "bar"

            func method() {
                closure { [self] bar in
                    self.bar = bar
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func closureParameterListShadowingPropertyOnSelfInStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            func method() {
                closure { bar in
                    self.bar = bar
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func closureCaptureListShadowingPropertyOnSelf() {
        let input = """
        class Foo {
            var bar = "bar"
            var baaz = "baaz"

            func method() {
                closure { [self, bar, baaz = bar] in
                    self.bar = bar
                    self.baaz = baaz
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfKeepsSelfInClosureCapturingSelfWeaklyBefore5_8() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [weak self] in
                    print(self?.bar)
                    guard let self else {
                        return
                    }
                    print(self.bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func nonRedundantSelfNotRemovedAfterConditionalLet() {
        let input = """
        class Foo {
            var bar: Int?
            var baz: Bool

            func foo() {
                let baz = 5
                if let bar = bar, self.baz {
                    // ...
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfDoesNotGetStuckIfNoParensFound() {
        let input = """
        init<T>_ foo: T {}
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.spaceAroundOperators],
        )
    }

    @Test func noRemoveSelfInIfLetSelf() {
        let input = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInIfLetEscapedSelf() {
        let input = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func noRemoveSelfAfterGuardLetSelf() {
        let input = """
        func foo() {
            guard let self = self as? Foo else {
                return
            }
            self.bar()
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
    }

    @Test func noRemoveSelfInClosureInIfCondition() {
        let input = """
        class Foo {
            func foo() {
                if bar({ self.baz() }) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInTrailingClosureInVarAssignment() {
        let input = """
        func broken() {
            var bad = abc {
                self.foo()
                self.bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfNotRemovedWhenPropertyIsKeyword() {
        let input = """
        class Foo {
            let `default` = 5
            func foo() {
                print(self.default)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfNotRemovedWhenPropertyIsContextualKeyword() {
        let input = """
        class Foo {
            let `self` = 5
            func foo() {
                print(self.self)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfRemovedForContextualKeywordThatRequiresNoEscaping() {
        let input = """
        class Foo {
            let get = 5
            func foo() {
                print(self.get)
            }
        }
        """
        let output = """
        class Foo {
            let get = 5
            func foo() {
                print(get)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func removeSelfForMemberNamedLazy() {
        let input = """
        func foo() { self.lazy() }
        """
        let output = """
        func foo() { lazy() }
        """
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
    }

    @Test func removeRedundantSelfInArrayLiteral() {
        let input = """
        class Foo {
            func foo() {
                print([self.bar.x, self.bar.y])
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                print([bar.x, bar.y])
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

}
