import Testing
@testable import Swiftiomatic

@Suite struct UnusedPrivateDeclarationsTests {
    @Test func removeUnusedPrivate() {
        let input = """
        struct Foo {
            private var foo = "foo"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func removeUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func doNotRemoveUsedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func removeMultipleUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            fileprivate var baz = "baz"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func removeMixedUsedAndUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
            fileprivate var baz = "baz"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        let output = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func doNotRemoveFilePrivateUsedInSameStruct() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"

            func useFoo() {
                print(foo)
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func removeUnusedFilePrivateInNestedStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            struct Inner {
                fileprivate var foo = "foo"
            }
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"

            struct Inner {
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations, exclude: [.emptyBraces])
    }

    @Test func doNotRemoveFilePrivateUsedInNestedStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            struct Inner {
                fileprivate var foo = "foo"
                func useFoo() {
                    print(foo)
                }
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func removeUnusedFileprivateFunction() {
        let input = """
        struct Foo {
            var bar = "bar"

            fileprivate func sayHi() {
                print("hi")
            }
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, [output], rules: [.unusedPrivateDeclarations, .blankLinesAtEndOfScope])
    }

    @Test func doNotRemoveUnusedFileprivateOperatorDefinition() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func removePrivateDeclarationButDoNotRemoveUnusedPrivateType() {
        let input = """
        private struct Foo {
            private func bar() {
                print("test")
            }
        }
        """
        let output = """
        private struct Foo {
        }
        """

        testFormatting(for: input, output, rule: .unusedPrivateDeclarations, exclude: [.emptyBraces])
    }

    @Test func removePrivateDeclarationButDoNotRemovePrivateExtension() {
        let input = """
        private extension Foo {
            private func doSomething() {}
            func anotherFunction() {}
        }
        """
        let output = """
        private extension Foo {
            func anotherFunction() {}
        }
        """

        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func removesPrivateTypealias() {
        let input = """
        enum Foo {
            struct Bar {}
            private typealias Baz = Bar
        }
        """
        let output = """
        enum Foo {
            struct Bar {}
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func doesntRemoveFileprivateInit() {
        let input = """
        struct Foo {
            fileprivate init() {}
            static let foo = Foo()
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations, exclude: [.propertyTypes])
    }

    @Test func canDisableUnusedPrivateDeclarationsRule() {
        let input = """
        private enum Foo {
            // swiftformat:disable:next unusedPrivateDeclarations
            fileprivate static func bar() {}
        }
        """

        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doesNotRemovePropertyWrapperPrefixesIfUsed() {
        let input = """
        public struct ContentView: View {
            public init() {
                _showButton = .init(initialValue: false)
            }

            @State private var showButton: Bool
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations, exclude: [.privateStateVariables])
    }

    @Test func doesNotRemoveUnderscoredDeclarationIfUsed() {
        let input = """
        struct Foo {
            private var _showButton: Bool = true
            print(_showButton)
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doesNotRemoveBacktickDeclarationIfUsed() {
        let input = """
        struct Foo {
            fileprivate static var `default`: Bool = true
            func printDefault() {
                print(Foo.default)
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doesNotRemoveBacktickUsage() {
        let input = """
        struct Foo {
            fileprivate static var foo = true
            func printDefault() {
                print(Foo.`foo`)
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations, exclude: [.redundantBackticks])
    }

    @Test func doNotRemovePreservedPrivateDeclarations() {
        let input = """
        enum Foo {
            private static let registryAssociation = false
        }
        """
        let options = FormatOptions(preservedPrivateDeclarations: ["registryAssociation", "hello"])
        testFormatting(for: input, rule: .unusedPrivateDeclarations, options: options)
    }

    @Test func doNotRemoveOverridePrivateMethodDeclarations() {
        let input = """
        class Poodle: Dog {
            override private func makeNoise() {
                print("Yip!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doNotRemoveOverridePrivatePropertyDeclarations() {
        let input = """
        class Poodle: Dog {
            override private var age: Int {
                7
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doNotRemoveObjcPrivatePropertyDeclaration() {
        let input = """
        struct Foo {
            @objc
            private var bar = "bar"
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doNotRemoveObjcPrivateFunctionDeclaration() {
        let input = """
        struct Foo {
            @objc
            private func doSomething() {}
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func doNotRemoveIBActionPrivateFunctionDeclaration() {
        let input = """
        class FooViewController: UIViewController {
            @IBAction private func buttonPressed(_: UIButton) {
                print("Button pressed!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }

    @Test func removeUnusedRecursivePrivateDeclaration() {
        let input = """
        struct Planet {
            private typealias Dependencies = UniverseBuilderProviding // unused
            private var mass: Double // unused
            private func distance(to: Planet) { } // unused
            private func gravitationalForce(between other: Planet) -> Double {
                (G * mass * other.mass) / distance(to: other).squared()
            } // unused

            var ageInBillionYears: Double {
                ageInMillionYears / 1000
            }
        }
        """
        let output = """
        struct Planet {
            var ageInBillionYears: Double {
                ageInMillionYears / 1000
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclarations)
    }

    @Test func declarationNotRemovedWhenUsedOutsideFormatRange() {
        let input = """
        private let used: Int = 22
        // swiftformat:disable:all
        struct Formatting {
            let a: Int

            init() {
                self.a = used
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclarations)
    }
}
