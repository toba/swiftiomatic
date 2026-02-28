import Testing
@testable import Swiftiomatic

extension RedundantSelfTests {
    @Test func noInsertSelfForPatternLet() {
        let input = """
        class Foo {
            func foo() {}
            func bar() {
                switch x {
                case .bar(let foo, var bar): print(foo + bar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForPatternLet2() {
        let input = """
        class Foo {
            func foo() {}
            func bar() {
                switch x {
                case let .foo(baz): print(baz)
                case .bar(let foo, var bar): print(foo + bar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForTypeOf() {
        let input = """
        class Foo {
            var type: String?
            func bar() {
                print(\"\\(type(of: self))\")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForConditionalLocal() {
        let input = """
        class Foo {
            func foo() {
                #if os(watchOS)
                    var foo: Int
                #else
                    var foo: Float
                #endif
                print(foo)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func insertSelfInExtension() {
        let input = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let output = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func globalAfterTypeNotTreatedAsMember() {
        let input = """
        struct Foo {
            var foo = 1
        }

        var bar = 5

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func forWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                for bar in self where bar.baz {
                    return bar
                }
                return nil
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func switchCaseWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func switchCaseVarDoesNotLeak() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedInSwitchCaseLet() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedInSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedInDidSet() {
        let input = """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedAfterLet() {
        let input = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = foo
                baz(x)
            }

            func baz(_: String) {}
        }
        """
        let output = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = self.foo
                self.baz(x)
            }

            func baz(_: String) {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfNotInsertedInParameterNames() {
        let input = """
        class Foo {
            let a: String

            func bar() {
                foo(a: a)
            }
        }
        """
        let output = """
        class Foo {
            let a: String

            func bar() {
                foo(a: self.a)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfNotInsertedInCaseLet() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                if case let .some(a) = self.a, case var .some(b) = self.b {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfNotInsertedInCaseLet2() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func baz() {
                if case let .foos(a, b) = foo, case let .bars(a, b) = bar {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfNotInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                let (a, b) = (self.a, self.b)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.singlePropertyPerLine],
        )
    }

    @Test func insertSelfForMemberNamedLazy() {
        let input = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(lazy)
            }
        }
        """
        let output = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(self.lazy)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForVarDefinedInIfCaseLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                if case let .c(localVar) = self.d, localVar == .e {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForVarDefinedInUnhoistedIfCaseLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                if case .c(let localVar) = self.d, localVar == .e {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.hoistPatternLet],
        )
    }

    @Test func noInsertSelfForVarDefinedInFor() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                for localVar in 0 ..< 6 where localVar < 5 {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForVarDefinedInWhileLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                while let localVar = self.localVar, localVar < 5 {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfInCaptureList() {
        let input = """
        class Thing {
            var a: String? { nil }

            func foo() {
                let b = ""
                { [weak a = b] _ in }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noInsertSelfInCaptureList2() {
        let input = """
        class Thing {
            var a: String? { nil }

            func foo() {
                { [weak a] _ in }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noInsertSelfInCaptureList3() {
        let input = """
        class A {
            var thing: B? { fatalError() }

            func foo() {
                let thing2 = B()
                let _: (Bool) -> Void = { [weak thing = thing2] _ in
                    thing?.bar()
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func bodilessFunctionDoesNotBreakParser() {
        let input = """
        @_silgen_name("foo")
        func foo(_: CFString, _: CFTypeRef) -> Int?

        enum Bar {
            static func baz() {
                fatalError()
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func functionWithNoBodyFollowedByStaticFunction() {
        let input = """
        struct Foo {
            let foo: String

            @_silgen_name("__MARKER_doIt")
            func doIt(_ x: String) -> Int?

            static func bar() {
                print(self.foo)
            }
        }
        """

        let output = """
        struct Foo {
            let foo: String

            @_silgen_name("__MARKER_doIt")
            func doIt(_ x: String) -> Int?

            static func bar() {
                print(foo)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func noInsertSelfBeforeSet() {
        let input = """
        class Foo {
            var foo: Bool

            var bar: Bool {
                get { self.foo }
                set { self.foo = newValue }
            }

            required init() {}

            func set() {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfInMacro() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: __myVar)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfBeforeBinding() {
        let input = """
        struct MyView: View {
            @Environment(ViewModel.self) var viewModel

            var body: some View {
                @Bindable var viewModel = self.viewModel
                ZStack {
                    MySubview(
                        navigationPath: $viewModel.navigationPath
                    )
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert, swiftVersion: "5.10")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfInKeyPath() {
        let input = """
        class UserScreenPresenter: ScreenPresenter {
            func onAppear() {
                self.sessionInteractor.stage.compactMap(\\.?.session).latestValues(on: .main)
            }

            private var session: Session?
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    // explicitSelf = .initOnly

    @Test func preserveSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func removeSelfIfNotInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            func baz() {
                self.bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func insertSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                bar = baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func removeSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = self.baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfDotTypeInsideClassInitEdgeCase() {
        let input = """
        class Foo {
            let type: Int

            init() {
                self.type = 5
            }

            func baz() {
                switch type {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedInTupleInInit() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func selfInsertedAfterLetInInit() {
        let input = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                foo = baz
            }
        }
        """
        let output = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                self.foo = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfRuleDoesNotErrorForStaticFuncInProtocolWithWhere() {
        let input = """
        protocol Foo where Self: Bar {
            static func baz() -> Self
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfRuleDoesNotErrorForStaticFuncInStructWithWhere() {
        let input = """
        struct Foo<T> where T: Bar {
            static func baz() -> Foo {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.simplifyGenericConstraints],
        )
    }

    @Test func redundantSelfRuleDoesNotErrorForClassFuncInClassWithWhere() {
        let input = """
        class Foo<T> where T: Bar {
            class func baz() -> Foo {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.simplifyGenericConstraints],
        )
    }

    @Test func redundantSelfRuleFailsInInitOnlyMode() {
        let input = """
        class Foo {
            func foo() -> Foo? {
                guard let bar = { nil }() else {
                    return nil
                }
            }

            static func baz() -> String? {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(
            for: input,
            rule: .redundantSelf,
            options: options,
            exclude: [.redundantClosure],
        )
    }

}
