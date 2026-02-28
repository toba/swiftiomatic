import Testing
@testable import Swiftiomatic

@Suite struct RedundantBackticksTests {
    @Test func removeRedundantBackticksInLet() {
        let input = """
        let `foo` = bar
        """
        let output = """
        let foo = bar
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundKeyword() {
        let input = """
        let `let` = foo
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundSelf() {
        let input = """
        let `self` = foo
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundClassSelfInTypealias() {
        let input = """
        typealias `Self` = Foo
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundClassSelfAsReturnType() {
        let input = """
        func foo(bar: `Self`) { print(bar) }
        """
        let output = """
        func foo(bar: Self) { print(bar) }
        """
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.wrapFunctionBodies])
    }

    @Test func removeBackticksAroundClassSelfAsParameterType() {
        let input = """
        func foo() -> `Self` {}
        """
        let output = """
        func foo() -> Self {}
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundClassSelfArgument() {
        let input = """
        func foo(`Self`: Foo) { print(Self) }
        """
        let output = """
        func foo(Self: Foo) { print(Self) }
        """
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveBackticksAroundKeywordFollowedByType() {
        let input = """
        let `default`: Int = foo
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundContextualGet() {
        let input = """
        var foo: Int {
            `get`()
            return 5
        }
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundGetArgument() {
        let input = """
        func foo(`get` value: Int) { print(value) }
        """
        let output = """
        func foo(get value: Int) { print(value) }
        """
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
    }

    @Test func removeBackticksAroundTypeAtRootLevel() {
        let input = """
        enum `Type` {}
        """
        let output = """
        enum Type {}
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundTypeInsideType() {
        let input = """
        struct Foo {
            enum `Type` {}
        }
        """
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.enumNamespaces])
    }

    @Test func noRemoveBackticksAroundLetArgument() {
        let input = """
        func foo(`let`: Foo) { print(`let`) }
        """
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveBackticksAroundTrueArgument() {
        let input = """
        func foo(`true`: Foo) { print(`true`) }
        """
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.wrapFunctionBodies])
    }

    @Test func removeBackticksAroundTrueArgument() {
        let input = """
        func foo(`true`: Foo) { print(`true`) }
        """
        let output = """
        func foo(true: Foo) { print(`true`) }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantBackticks, options: options, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveBackticksAroundTypeProperty() {
        let input = """
        var type: Foo.`Type`
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundTypePropertyInsideType() {
        let input = """
        struct Foo {
            enum `Type` {}
        }
        """
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.enumNamespaces])
    }

    @Test func noRemoveBackticksAroundTrueProperty() {
        let input = """
        var type = Foo.`true`
        """
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.propertyTypes])
    }

    @Test func removeBackticksAroundTrueProperty() {
        let input = """
        var type = Foo.`true`
        """
        let output = """
        var type = Foo.true
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantBackticks, options: options, exclude: [.propertyTypes])
    }

    @Test func removeBackticksAroundProperty() {
        let input = """
        var type = Foo.`bar`
        """
        let output = """
        var type = Foo.bar
        """
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.propertyTypes])
    }

    @Test func removeBackticksAroundKeywordProperty() {
        let input = """
        var type = Foo.`default`
        """
        let output = """
        var type = Foo.default
        """
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.propertyTypes])
    }

    @Test func removeBackticksAroundKeypathProperty() {
        let input = """
        var type = \\.`bar`
        """
        let output = """
        var type = \\.bar
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundKeypathKeywordProperty() {
        let input = """
        var type = \\.`default`
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundKeypathKeywordPropertyInSwift5() {
        let input = """
        var type = \\.`default`
        """
        let output = """
        var type = \\.default
        """
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, output, rule: .redundantBackticks, options: options)
    }

    @Test func noRemoveBackticksAroundInitPropertyInSwift5() {
        let input = """
        let foo: Foo = .`init`
        """
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, rule: .redundantBackticks, options: options, exclude: [.propertyTypes])
    }

    @Test func noRemoveBackticksAroundAnyProperty() {
        let input = """
        enum Foo {
            case `Any`
        }
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundGetInSubscript() {
        let input = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            `get`(name)
        }
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundActorProperty() {
        let input = """
        let `actor`: Foo
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundActorRvalue() {
        let input = """
        let foo = `actor`
        """
        let output = """
        let foo = actor
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundActorLabel() {
        let input = """
        init(`actor`: Foo)
        """
        let output = """
        init(actor: Foo)
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func removeBackticksAroundActorLabel2() {
        let input = """
        init(`actor` foo: Foo)
        """
        let output = """
        init(actor foo: Foo)
        """
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundUnderscore() {
        let input = """
        func `_`<T>(_ foo: T) -> T { foo }
        """
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveBackticksAroundShadowedSelf() {
        let input = """
        struct Foo {
            let `self`: URL

            func printURL() {
                print("My URL is \\(self.`self`)")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: .redundantBackticks, options: options)
    }

    @Test func noRemoveBackticksAroundDollar() {
        let input = """
        @attached(peer, names: prefixed(`$`))
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    @Test func noRemoveBackticksAroundRawIdentifier() {
        let input = """
        func `function with raw identifier`() -> String {
            "foo"
        }

        let `property with raw identifier` = `function with raw identifier`()
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }
}
