import Testing
@testable import Swiftiomatic

@Suite struct RedundantEquatableTests {
    @Test func removeSimpleEquatableConformanceOnType() {
        let input = """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func ==(lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
                    && lhs.baaz == rhs.baaz
            }
        }

        struct Baaz: Hashable {
            let foo: Foo

            static func ==(_ lhs: Baaz, _ rhs: Baaz) -> Bool {
                return lhs.foo == rhs.foo
            }
        }
        """

        let output = """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz
        }

        struct Baaz: Hashable {
            let foo: Foo
        }
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .blankLinesAtEndOfScope])
    }

    @Test func removeSimpleEquatableConformanceInExtensionType() {
        let input = """
        struct Foo {
            static let shared: Foo = .init()

            let bar: Bar

            var baaz: Baaz {
                didSet {
                    print("Updated baaz")
                }
            }

            var quux: Quux {
                Quux(baaz)
            }
        }

        extension Foo: Equatable {
            static func ==(lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz 
            }
        }
        """

        let output = """
        struct Foo {
            static let shared: Foo = .init()

            let bar: Bar

            var baaz: Baaz {
                didSet {
                    print("Updated baaz")
                }
            }

            var quux: Quux {
                Quux(baaz)
            }
        }

        extension Foo: Equatable {}
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces])
    }

    @Test func removeSimpleEquatableConformanceUsingSelfInExtensionType() {
        let input = """
        struct Foo {
            let bar: Bar
            let baaz: Baaz
        }

        extension Foo: Equatable {
            static func ==(lhs: Self, rhs: Self) -> Bool {
                lhs.bar == rhs.bar
                    && lhs.baaz == rhs.baaz
            }
        }
        """

        let output = """
        struct Foo {
            let bar: Bar
            let baaz: Baaz
        }

        extension Foo: Equatable {}
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces])
    }

    @Test func preservesEquatableImplementationNotComparingAllProperties() {
        let input = """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func == (_ lhs: Foo, _ rhs: Foo) -> Equatable {
                lhs.bar == rhs.bar
            }
        }

        struct Baaz: Equatable {
            let foo: Foo

            static func == (_ lhs: Foo, _ rhs: Baaz) -> Equatable {
                lhs.foo.bar == rhs.foo.bar
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    @Test func preservesEquatableImplementationInClass() {
        let input = """
        class Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func == (_ lhs: Foo, _ rhs: Foo) -> Equatable {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    @Test func adoptsEquatableMacroOnClass() {
        let input = """
        import FooLib

        class Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func ==(lhs: Foo, rhs: Foo) -> Equatable {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }

        class Quux {
            let bar: Bar
            let baaz: Baaz
        }

        extension Quux: Equatable, OtherConformance {
            static func ==(_ lhs: Quux, _ rhs: Quux) -> Equatable {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }
        """

        let output = """
        import FooLib
        import MyEquatableMacroLib

        @Equatable
        class Foo {
            let bar: Bar
            let baaz: Baaz
        }

        @Equatable
        class Quux {
            let bar: Bar
            let baaz: Baaz
        }

        extension Quux: OtherConformance {}
        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib")
        )

        testFormatting(
            for: input, [output],
            rules: [.redundantEquatable, .emptyBraces, .blankLinesAtEndOfScope, .wrapAttributes, .sortImports],
            options: options
        )
    }

    @Test func adoptsEquatableMacroOnClassInFragment() {
        let input = """
        import FooLib

        class Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func ==(lhs: Foo, rhs: Foo) -> Equatable {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }

        class Quux {
            let bar: Bar
            let baaz: Baaz
        }

        extension Quux: Equatable, OtherConformance {
            static func ==(_ lhs: Quux, _ rhs: Quux) -> Equatable {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }
        """

        let output = """
        import FooLib

        @Equatable
        class Foo {
            let bar: Bar
            let baaz: Baaz
        }

        @Equatable
        class Quux {
            let bar: Bar
            let baaz: Baaz
        }

        extension Quux: OtherConformance {}
        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib"),
            fragment: true
        )

        testFormatting(
            for: input, [output],
            rules: [.redundantEquatable, .emptyBraces, .blankLinesAtEndOfScope, .wrapAttributes, .sortImports],
            options: options
        )
    }

    @Test func structEquatableExtensionWithWhereClause() {
        let input = """
        struct Foo<Bar> {
            let bar: Bar
        }

        extension Foo: Equatable where Bar: Equatable {
            static func ==(lhs: Self, rhs: Self) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """

        let output = """
        struct Foo<Bar> {
            let bar: Bar
        }

        extension Foo: Equatable where Bar: Equatable {}
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces])
    }

    @Test func classEquatableExtensionWithWhereClause() {
        let input = """
        class Foo<Bar> {
            let bar: Bar
        }

        extension Foo: Equatable where Bar: Equatable {
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib")
        )

        testFormatting(for: input, rule: .redundantEquatable, options: options)
    }

    @Test func preservesHashableConformance() {
        let input = """
        class Foo {
            let bar: Bar
        }

        extension Foo: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.bar == rhs.bar
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
            }
        }
        """

        let output = """
        import MyEquatableMacroLib

        @Equatable
        class Foo {
            let bar: Bar
        }

        extension Foo: Hashable {
            func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
            }
        }
        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib")
        )
        testFormatting(for: input, [output], rules: [.redundantEquatable, .blankLinesAtEndOfScope, .wrapAttributes], options: options)
    }

    @Test func insertsImportBelowHeaderCommentWithNoOtherComments() {
        let input = """
        // Created by Cal Stephens on 9/25/24.
        // Copyright © 2024 Airbnb Inc. All rights reserved.

        class Foo {
            let bar: Bar
        }

        extension Foo: Equatable {
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """

        let output = """
        // Created by Cal Stephens on 9/25/24.
        // Copyright © 2024 Airbnb Inc. All rights reserved.

        import MyEquatableMacroLib

        @Equatable
        class Foo {
            let bar: Bar
        }

        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib")
        )

        testFormatting(
            for: input, [output],
            rules: [.redundantEquatable, .blankLinesAtEndOfScope, .emptyExtensions, .wrapAttributes, .consecutiveBlankLines],
            options: options
        )
    }

    @Test func insertsImportBelowHeaderCommentWithOtherComments() {
        let input = """
        // Created by Cal Stephens on 9/25/24.
        // Copyright © 2024 Airbnb Inc. All rights reserved.

        import BarLib
        import FooLib

        class Foo {
            let bar: Bar
        }

        extension Foo: Equatable {
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """

        let output = """
        // Created by Cal Stephens on 9/25/24.
        // Copyright © 2024 Airbnb Inc. All rights reserved.

        import BarLib
        import FooLib
        import MyEquatableMacroLib

        @Equatable
        class Foo {
            let bar: Bar
        }

        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib")
        )

        testFormatting(
            for: input, [output],
            rules: [.redundantEquatable, .blankLinesAtEndOfScope, .emptyExtensions, .wrapAttributes, .consecutiveBlankLines, .sortImports],
            options: options
        )
    }

    @Test func removeSimpleEquatableConformanceOnNestedType() {
        let input = """
        enum Foo {
            enum Bar {
                struct Baaz: Equatable {
                    let foo: String
                    let bar: String

                    static func ==(lhs: Baaz, rhs: Baaz) -> Bool {
                        lhs.foo == rhs.foo
                            && lhs.bar == rhs.bar
                    }
                }
            }
        }
        """

        let output = """
        enum Foo {
            enum Bar {
                struct Baaz: Equatable {
                    let foo: String
                    let bar: String
                }
            }
        }
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .blankLinesAtEndOfScope])
    }

    @Test func removeSimpleSelfEquatableConformanceOnNestedType() {
        let input = """
        enum Foo {
            enum Bar {
                struct Baaz: Equatable {
                    let foo: String
                    let bar: String

                    static func ==(lhs: Self, rhs: Self) -> Bool {
                        lhs.foo == rhs.foo
                            && lhs.bar == rhs.bar
                    }
                }
            }
        }
        """

        let output = """
        enum Foo {
            enum Bar {
                struct Baaz: Equatable {
                    let foo: String
                    let bar: String
                }
            }
        }
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .blankLinesAtEndOfScope])
    }

    @Test func removeSimpleEquatableConformanceOnNestedTypeWithExtension() {
        let input = """
        enum Foo {
            enum Bar {
                struct Baaz {
                    let foo: String
                    let bar: String
                }
            }
        }

        extension Foo.Bar.Baaz: Equatable {
            static func ==(lhs: Baaz, rhs: Baaz) -> Bool {
                lhs.foo == rhs.foo
                    && lhs.bar == rhs.bar
            }
        }
        """

        let output = """
        enum Foo {
            enum Bar {
                struct Baaz {
                    let foo: String
                    let bar: String
                }
            }
        }

        extension Foo.Bar.Baaz: Equatable {}
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces])
    }

    @Test func adoptsEquatableMacroOnNestedTypeWithExtension() {
        let input = """
        enum Foo {
            enum Bar {
                final class Baaz {
                    let foo: String
                    let bar: String
                }
            }
        }

        extension Foo.Bar.Baaz: Equatable {
            static func ==(lhs: Self, rhs: Self) -> Bool {
                lhs.foo == rhs.foo
                    && lhs.bar == rhs.bar
            }
        }
        """

        let output = """
        import MyEquatableMacroLib

        enum Foo {
            enum Bar {
                @Equatable
                final class Baaz {
                    let foo: String
                    let bar: String
                }
            }
        }

        """

        let options = FormatOptions(
            typeAttributes: .prevLine,
            equatableMacro: .macro("@Equatable", module: "MyEquatableMacroLib")
        )

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces, .wrapAttributes, .emptyExtensions, .consecutiveBlankLines], options: options)
    }

    @Test func preserveCustomEquatableImplementationComparingAnyClass() {
        // `AnyClass` defines an `==` operator but is not Equatable.
        let input = """
        struct Foo: Equatable {
            let classValue: AnyClass

            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.classValue == rhs.classValue
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    @Test func preserveCustomEquatableImplementationComparingTuple() {
        // Tuples define an `==` operator but are not Equatable.
        let input = """
        struct Foo: Equatable {
            let tupleValue: (string: String, int: Int)

            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.tupleValue == rhs.tupleValue
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    @Test func preserveCustomEquatableImplementationComparingOptionalTuple() {
        // Tuples define an `==` operator but are not Equatable.
        let input = """
        struct Foo: Equatable {
            let tupleValue: (string: String, int: Int)?

            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.tupleValue == rhs.tupleValue
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    @Test func preserveEquatableImplementationWithUsableFromInlineAttribute() {
        let input = """
        public struct Foo: Equatable {
            let bar: String

            @usableFromInline
            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    @Test func preserveEquatableImplementationWithInlinableAttribute() {
        let input = """
        public struct Foo: Equatable {
            let bar: String

            @inlinable
            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }
}
