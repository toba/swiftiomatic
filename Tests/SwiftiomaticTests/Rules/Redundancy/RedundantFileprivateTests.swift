import Testing
@testable import Swiftiomatic

@Suite struct RedundantFileprivateTests {
    @Test func fileScopeFileprivateVarChangedToPrivate() {
        let input = """
        fileprivate var foo = "foo"
        """
        let output = """
        private var foo = "foo"
        """
        testFormatting(for: input, output, rule: .redundantFileprivate)
    }

    @Test func fileScopeFileprivateVarNotChangedToPrivateIfFragment() {
        let input = """
        fileprivate var foo = "foo"
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarChangedToPrivateIfNotAccessedFromAnotherType() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
        }
        """
        let output = """
        struct Foo {
            private var foo = "foo"
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarChangedToPrivateIfNotAccessedFromAnotherTypeAndFileIncludesImports() {
        let input = """
        import Foundation

        struct Foo {
            fileprivate var foo = "foo"
        }
        """
        let output = """
        import Foundation

        struct Foo {
            private var foo = "foo"
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromAnotherType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        struct Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromSubclass() {
        let input = """
        class Foo {
            fileprivate func foo() {}
        }

        class Bar: Foo {
            func bar() {
                return foo()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromAFunction() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        func getFoo() -> String {
            return Foo().foo
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromAConstant() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        let kFoo = Foo().foo
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes],
        )
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromAVar() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromCode() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromAClosure() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print({ Foo().foo }())
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options, exclude: [.redundantClosure],
        )
    }

    @Test func fileprivateVarNotChangedToPrivateIfAccessedFromAnExtensionOnAnotherType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarChangedToPrivateIfAccessedFromAnExtensionOnSameType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }
        """
        let output = """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarChangedToPrivateIfAccessedViaSelfFromAnExtensionOnSameType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(self.foo)
            }
        }
        """
        let output = """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(self.foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, output, rule: .redundantFileprivate, options: options,
            exclude: [.redundantSelf],
        )
    }

    @Test func fileprivateMultiLetNotChangedToPrivateIfAccessedOutsideType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo", bar = "bar"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }

        extension Bar {
            func bar() {
                print(Foo().bar)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options,
            exclude: [.singlePropertyPerLine],
        )
    }

    @Test func fileprivateInitChangedToPrivateIfConstructorNotCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }
        """
        let output = """
        struct Foo {
            private init() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes],
        )
    }

    @Test func fileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType2() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        struct Bar {
            let foo = Foo()
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes],
        )
    }

    @Test func fileprivateStructMemberNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate let bar: String
        }

        let foo = Foo(bar: "test")
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes],
        )
    }

    @Test func fileprivateClassMemberChangedToPrivateEvenIfConstructorCalledOutsideType() {
        let input = """
        class Foo {
            fileprivate let bar: String
        }

        let foo = Foo()
        """
        let output = """
        class Foo {
            private let bar: String
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, output, rule: .redundantFileprivate, options: options,
            exclude: [.propertyTypes],
        )
    }

    @Test func fileprivateExtensionFuncNotChangedToPrivateIfPartOfProtocolConformance() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInnerTypeNotChangedToPrivate() {
        let input = """
        struct Foo {
            fileprivate enum Bar {
                case a, b
            }

            fileprivate let bar: Bar
        }

        func foo(foo: Foo) {
            print(foo.bar)
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input,
            rule: .redundantFileprivate,
            options: options,
            exclude: [.wrapEnumCases],
        )
    }

    @Test func fileprivateClassTypeMemberNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate class var bar = "bar"
        }

        func foo() {
            print(Foo.bar)
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func overriddenFileprivateInitNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Foo, Equatable {
            override init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func nonOverriddenFileprivateInitChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Baz {
            override init() {
                super.init()
            }
        }
        """
        let output = """
        class Foo {
            private init() {}
        }

        class Bar: Baz {
            override init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInitNotChangedToPrivateWhenUsingTypeInferredInits() {
        let input = """
        struct Example {
            fileprivate init() {}
        }

        enum Namespace {
            static let example: Example = .init()
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes],
        )
    }

    @Test func fileprivateInitNotChangedToPrivateWhenUsingTrailingClosureInit() {
        let input = """
        private struct Foo {}

        public struct Bar {
            fileprivate let consumeFoo: (Foo) -> Void
        }

        public func makeBar() -> Bar {
            Bar { _ in }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateNotChangedToPrivateWhenAccessedFromExtensionOnContainingType() {
        let input = """
        extension Foo.Bar {
            fileprivate init() {}
        }

        extension Foo {
            func baz() -> Foo.Bar {
                return Bar()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateNotChangedToPrivateWhenAccessedFromExtensionOnNestedType() {
        let input = """
        extension Foo {
            fileprivate init() {}
        }

        extension Foo.Bar {
            func baz() -> Foo {
                return Foo()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInExtensionNotChangedToPrivateWhenAccessedFromSubclass() {
        let input = """
        class Foo: Bar {
            func quux() {
                baz()
            }
        }

        extension Bar {
            fileprivate func baz() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInitNotChangedToPrivateWhenAccessedFromSubclass() {
        let input = """
        public class Foo {
            fileprivate init() {}
        }

        private class Bar: Foo {
            init(something: String) {
                print(something)
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInExtensionNotChangedToPrivateWhenAccessedFromExtensionOnSubclass() {
        let input = """
        class Foo: Bar {}

        extension Foo {
            func quux() {
                baz()
            }
        }

        extension Bar {
            fileprivate func baz() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateVarWithPropertWrapperNotChangedToPrivateIfAccessedFromSubclass() {
        let input = """
        class Foo {
            @Foo fileprivate var foo = 5
        }

        class Bar: Foo {
            func bar() {
                return $foo
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInArrayExtensionNotChangedToPrivateWhenAccessedInFile() {
        let input = """
        extension [String] {
            fileprivate func fileprivateMember() {}
        }

        extension Namespace {
            func testCanAccessFileprivateMember() {
                ["string", "array"].fileprivateMember()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    @Test func fileprivateInArrayExtensionNotChangedToPrivateWhenAccessedInFile2() {
        let input = """
        extension Array<String> {
            fileprivate func fileprivateMember() {}
        }

        extension Namespace {
            func testCanAccessFileprivateMember() {
                ["string", "array"].fileprivateMember()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(
            for: input, rule: .redundantFileprivate,
            options: options, exclude: [.typeSugar],
        )
    }
}
