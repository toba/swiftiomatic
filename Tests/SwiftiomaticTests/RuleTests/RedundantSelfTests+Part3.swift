import Testing
@testable import Swiftiomatic

extension RedundantSelfTests {
    @Test func removeRedundantSelfInArrayLiteralVar() {
        let input = """
        class Foo {
            func foo() {
                var bars = [self.bar.x, self.bar.y]
                print(bars)
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                var bars = [bar.x, bar.y]
                print(bars)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func removeRedundantSelfInGuardLet() {
        let input = """
        class Foo {
            func foo() {
                guard let bar = self.baz else {
                    return
                }
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                guard let bar = baz else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func selfNotRemovedInClosureInIf() {
        let input = """
        if let foo = bar(baz: { [weak self] in
            guard let self = self else { return }
            _ = self.myVar
        }) {}
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func structSelfRemovedInTrailingClosureInIfCase() {
        let input = """
        struct A {
            func doSomething() {
                B.method { mode in
                    if case .edit = mode {
                        self.doA()
                    } else {
                        self.doB()
                    }
                }
            }

            func doA() {}
            func doB() {}
        }
        """
        let output = """
        struct A {
            func doSomething() {
                B.method { mode in
                    if case .edit = mode {
                        doA()
                    } else {
                        doB()
                    }
                }
            }

            func doA() {}
            func doB() {}
        }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: FormatOptions(swiftVersion: "5.8"),
        )
    }

    @Test func selfNotRemovedInDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            subscript(dynamicMember foo: String) -> String {
                foo + "bar"
            }

            func bar() {
                if self.foo == "foobar" {
                    return
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfNotRemovedInDeclarationWithDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            subscript(dynamicMember foo: String) -> String {
                foo + "bar"
            }

            func bar() {
                let foo = self.foo
                print(foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfNotRemovedInExtensionOfTypeWithDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {}

        extension Foo {
            subscript(dynamicMember foo: String) -> String {
                foo + "bar"
            }

            func bar() {
                if self.foo == "foobar" {
                    return
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfRemovedInNestedExtensionOfTypeWithDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            var foo: Int
            struct Foo {}
            extension Foo {
                func bar() {
                    if self.foo == "foobar" {
                        return
                    }
                }
            }
        }
        """
        let output = """
        @dynamicMemberLookup
        struct Foo {
            var foo: Int
            struct Foo {}
            extension Foo {
                func bar() {
                    if foo == "foobar" {
                        return
                    }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: options,
        )
    }

    @Test func noRemoveSelfAfterGuardCaseLetWithExplicitNamespace() {
        let input = """
        class Foo {
            var name: String?

            func bug(element: Something) {
                guard case let Something.a(name) = element
                else { return }
                self.name = name
            }
        }
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func noRemoveSelfInAssignmentInsideIfAsStatement() {
        let input = """
        if let foo = foo as? Foo, let bar = baz {
            self.bar = bar
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func noRemoveSelfInAssignmentInsideIfLetWithPostfixOperator() {
        let input = """
        if let foo = baz?.foo, let bar = baz?.bar {
            self.foo = foo
            self.bar = bar
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfParsingBug() {
        let input = """
        private class Foo {
            mutating func bar() -> Statement? {
                let start = self
                guard case Token.identifier(let name)? = self.popFirst() else {
                    self = start
                    return nil
                }
                return Statement.declaration(name: name)
            }
        }
        """
        let output = """
        private class Foo {
            mutating func bar() -> Statement? {
                let start = self
                guard case Token.identifier(let name)? = popFirst() else {
                    self = start
                    return nil
                }
                return Statement.declaration(name: name)
            }
        }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf,
            exclude: [.hoistPatternLet, .blankLinesAfterGuardStatements],
        )
    }

    @Test func redundantSelfParsingBug2() {
        let input = """
        extension Foo {
            private enum NonHashableEnum: RawRepresentable {
                case foo
                case bar

                var rawValue: RuntimeTypeTests.TestStruct {
                    return TestStruct(foo: 0)
                }

                init?(rawValue: RuntimeTypeTests.TestStruct) {
                    switch rawValue.foo {
                    case 0:
                        self = .foo
                    case 1:
                        self = .bar
                    default:
                        return nil
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfWithStaticMethodAfterForLoop() {
        let input = """
        struct Foo {
            init() {
                for foo in self.bar {}
            }

            static func foo() {}
        }

        """
        let output = """
        struct Foo {
            init() {
                for foo in bar {}
            }

            static func foo() {}
        }

        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func redundantSelfWithStaticMethodAfterForWhereLoop() {
        let input = """
        struct Foo {
            init() {
                for foo in self.bar where !bar.isEmpty {}
            }

            static func foo() {}
        }

        """
        let output = """
        struct Foo {
            init() {
                for foo in bar where !bar.isEmpty {}
            }

            static func foo() {}
        }

        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func redundantSelfRuleDoesNotErrorInForInTryLoop() {
        let input = """
        for foo in try bar() {}
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfInInitWithActorLabel() {
        let input = """
        class Foo {
            init(actor: Actor, bar: Bar) {
                self.actor = actor
                self.bar = bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfRuleFailsInGuardWithParenthesizedClosureAfterComma() {
        let input = """
        guard let foo = bar, foo.bar(baz: { $0 }) else {
            return nil
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func minSelfNotRemoved() {
        let input = """
        extension Array where Element: Comparable {
            func foo() -> Int {
                self.min()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func minSelfNotRemovedOnSwift5_4() {
        let input = """
        extension Array where Element == Foo {
            func smallest() -> Foo? {
                let bar = self.min(by: { rect1, rect2 -> Bool in
                    rect1.perimeter < rect2.perimeter
                })
                return bar
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty],
        )
    }

    @Test func disableRedundantSelfDirective() {
        let input = """
        func smallest() -> Foo? {
            // sm:disable:next redundantSelf
            let bar = self.foo { rect1, rect2 -> Bool in
                rect1.perimeter < rect2.perimeter
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty],
        )
    }

    @Test func disableRedundantSelfDirective2() {
        let input = """
        func smallest() -> Foo? {
            let bar =
                // sm:disable:next redundantSelf
                self.foo { rect1, rect2 -> Bool in
                    rect1.perimeter < rect2.perimeter
                }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty],
        )
    }

    @Test(.disabled("Inline sm:options not supported"))
    func selfInsertDirective() {
        let input = """
        func smallest() -> Foo? {
            // sm:options:next --self insert
            let bar = self.foo { rect1, rect2 -> Bool in
                rect1.perimeter < rect2.perimeter
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty],
        )
    }

    @Test func noRemoveVariableShadowedLaterInScopeInOlderSwiftVersions() {
        let input = """
        func foo() -> Bar? {
            guard let baz = self.bar else {
                return nil
            }

            let bar = Foo()
            return Bar(baz)
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func stillRemoveVariableShadowedInSameDecalarationInOlderSwiftVersions() {
        let input = """
        func foo() -> Bar? {
            guard let bar = self.bar else {
                return nil
            }
            return bar
        }
        """
        let output = """
        func foo() -> Bar? {
            guard let bar = bar else {
                return nil
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.0")
        testFormatting(
            for: input, output, rule: .redundantSelf, options: options,
            exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func shadowedSelfRemovedInGuardLet() {
        let input = """
        func foo() {
            guard let optional = self.optional else {
                return
            }
            print(optional)
        }
        """
        let output = """
        func foo() {
            guard let optional = optional else {
                return
            }
            print(optional)
        }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements],
        )
    }

    @Test func shadowedStringValueNotRemovedInInit() {
        let input = """
        init() {
            let value = "something"
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func shadowedIntValueNotRemovedInInit() {
        let input = """
        init() {
            let value = 5
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func shadowedPropertyValueNotRemovedInInit() {
        let input = """
        init() {
            let value = foo
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func shadowedFuncCallValueNotRemovedInInit() {
        let input = """
        init() {
            let value = foo()
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func shadowedFuncParamRemovedInInit() {
        let input = """
        init() {
            let value = foo(self.value)
        }
        """
        let output = """
        init() {
            let value = foo(value)
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noRemoveSelfInMacro() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: self.__myVar)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    // explicitSelf = .insert

    @Test func insertSelf() {
        let input = """
        class Foo {
            let foo: Int
            init() { foo = 5 }
        }
        """
        let output = """
        class Foo {
            let foo: Int
            init() { self.foo = 5 }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, output, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func insertSelfInActor() {
        let input = """
        actor Foo {
            let foo: Int
            init() { foo = 5 }
        }
        """
        let output = """
        actor Foo {
            let foo: Int
            init() { self.foo = 5 }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, output, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func insertSelfAfterReturn() {
        let input = """
        class Foo {
            let foo: Int
            func bar() -> Int { return foo }
        }
        """
        let output = """
        class Foo {
            let foo: Int
            func bar() -> Int { return self.foo }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, output, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func insertSelfInsideStringInterpolation() {
        let input = """
        class Foo {
            var bar: String?
            func baz() {
                print(\"\\(bar)\")
            }
        }
        """
        let output = """
        class Foo {
            var bar: String?
            func baz() {
                print(\"\\(self.bar)\")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noInterpretGenericTypesAsMembers() {
        let input = """
        class Foo {
            let foo: Bar<Int, Int>
            init() { self.foo = Int(5) }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func insertSelfForStaticMemberInClassFunction() {
        let input = """
        class Foo {
            static var foo: Int
            class func bar() { foo = 5 }
        }
        """
        let output = """
        class Foo {
            static var foo: Int
            class func bar() { self.foo = 5 }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, output, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noInsertSelfForInstanceMemberInClassFunction() {
        let input = """
        class Foo {
            var foo: Int
            class func bar() { foo = 5 }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noInsertSelfForStaticMemberInInstanceFunction() {
        let input = """
        class Foo {
            static var foo: Int
            func bar() { foo = 5 }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noInsertSelfForShadowedClassMemberInClassFunction() {
        let input = """
        class Foo {
            class func foo() {
                var foo: Int
                func bar() { foo = 5 }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noInsertSelfInForLoopTuple() {
        let input = """
        class Foo {
            var bar: Int
            func foo() { for (bar, baz) in quux {} }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noInsertSelfForTupleTypeMembers() {
        let input = """
        class Foo {
            var foo: (Int, UIColor) {
                let bar = UIColor.red
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfForArrayElements() {
        let input = """
        class Foo {
            var foo = [1, 2, nil]
            func bar() { baz(nil) }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noInsertSelfForNestedVarReference() {
        let input = """
        class Foo {
            func bar() {
                var bar = 5
                repeat { bar = 6 } while true
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input,
            rule: .redundantSelf,
            options: options,
            exclude: [.wrapLoopBodies],
        )
    }

    @Test func noInsertSelfInSwitchCaseLet() {
        let input = """
        class Foo {
            var foo: Bar? {
                switch bar {
                case let .baz(foo, _):
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfInFuncAfterImportedClass() {
        let input = """
        import class Foo.Bar
        func foo() {
            var bar = 5
            if true {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.blankLineAfterImports],
        )
    }

    @Test func noInsertSelfForSubscriptGetSet() {
        let input = """
        class Foo {
            func get() {}
            func set() {}
            subscript(key: String) -> String {
                get { return get(key) }
                set { set(key, newValue) }
            }
        }
        """
        let output = """
        class Foo {
            func get() {}
            func set() {}
            subscript(key: String) -> String {
                get { return self.get(key) }
                set { self.set(key, newValue) }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    @Test func noInsertSelfInIfCaseLet() {
        let input = """
        enum Foo {
            case bar(Int)
            var value: Int? {
                if case let .bar(value) = self { return value }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input, rule: .redundantSelf, options: options,
            exclude: [.wrapConditionalBodies],
        )
    }

}
