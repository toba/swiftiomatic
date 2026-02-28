import Testing
@testable import Swiftiomatic

extension OrganizeDeclarationsTests {
    @Test func issue1907() {
        let input = """
        public final class Test: ObservableObject {
            var someProperty: Int? = 0

            // MARK: - Public -

            public func somePublicFunction() {
                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
            }

            // MARK: - Internal -

            func someInternalFunction() {
                guard let someProperty else {
                    return
                }

                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
            }

            // MARK: - Private -

            private func somePrivateFunction() {
                print("Hello")
                print("Hello")
            }
        }
        """

        let options = FormatOptions(
            categoryMarkComment: "MARK: - %c -",
            beforeMarks: ["class", "let", "var"],
        )

        testFormatting(for: input, rule: .organizeDeclarations, options: options)
    }

    @Test func fixesSpacingAfterMarks() {
        let input = """
        class Foo {
            // MARK: Lifecycle
            init() {}
            // MARK: Internal
            let bar = "bar"
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            let bar = "bar"
        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations, exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func removesUnnecessaryMark() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            // MARK: Internal

            let bar = "bar"

            // MARK: Internal

            let baaz = "baaz"
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            let bar = "bar"

            let baaz = "baaz"
        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations, exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func preservesUnrelatedComments() {
        let input = """
        enum Test {
            /// Test Properties
            static let foo = "foo"
            static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        testFormatting(for: input, rule: .organizeDeclarations)
    }

    @Test func noCrashWhenSortingNestedTypeDeclarations1() {
        let input = """
        public struct MyType {
            var foo: Foo {
                .foo
            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            public enum Foo {
                case foo
                case bar
                case baaz
            }
        }
        """

        let output = """
        public struct MyType {

            // MARK: Public

            public enum Foo {
                case foo
                case bar
                case baaz
            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            // MARK: Internal

            var foo: Foo {
                .foo
            }

        }
        """

        let options = FormatOptions(organizeStructThreshold: 0)
        testFormatting(
            for: input, output, rule: .organizeDeclarations, options: options,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func noCrashWhenSortingNestedTypeDeclarations2() {
        let input = """
        public struct MyType {
            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            public enum Foo {
                case foo
                case bar
                case baaz
            }
        }
        """

        let output = """
        public struct MyType {
            public enum Foo {
                case foo
                case bar
                case baaz
            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

        }
        """

        let options = FormatOptions(organizeStructThreshold: 0)
        testFormatting(
            for: input, output, rule: .organizeDeclarations, options: options,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func sortsMultipleLayersOfNestedTypes() {
        let input = """
        public struct MyType {
            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            public class Foo {
                class Baaz {
                    let b: B
                    public let a: A

                    public class Quux {
                        let b: B
                        public let a: A
                    }
                }

                let bar: Bar
                let baaz: Baaz

                public class Bar {
                    let b: B
                    public let a: A
                }
            }
        }
        """

        let output = """
        public struct MyType {
            public class Foo {

                // MARK: Public

                public class Bar {

                    // MARK: Public

                    public let a: A

                    // MARK: Internal

                    let b: B
                }

                // MARK: Internal

                class Baaz {

                    // MARK: Public

                    public class Quux {

                        // MARK: Public

                        public let a: A

                        // MARK: Internal

                        let b: B
                    }

                    public let a: A

                    // MARK: Internal

                    let b: B

                }

                let bar: Bar
                let baaz: Baaz

            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantPublic],
        )
    }

    @Test func organizeDeclarationsSortsEnumNamespace() {
        let input = """
        // sm:sort
        public enum Constants {
            public static let foo = "foo"
            public static let bar = "bar"
            public static let baaz = "baaz"
        }
        """

        let output = """
        // sm:sort
        public enum Constants {
            public static let baaz = "baaz"
            public static let bar = "bar"
            public static let foo = "foo"
        }
        """

        testFormatting(for: input, [output], rules: [.organizeDeclarations, .sortDeclarations])
    }

    @Test func issue2045() {
        let input = """
        public final class A {

          // MARK: Lifecycle

          public init(a _: Int) {}

          convenience init() {
            self.init(a: 0)
          }

          // MARK: Public

          public func a() {}

          // MARK: Private

          private enum Error: Swift.Error {
            case e
          }

          private let a1: Float = 0
          private lazy var b: String? = ""
          private let a2 = 0

          private lazy var x: [Any] =
            if let b {
              [b]
            } else if false {
              []
            } else {
              [1, 2]
            }

          private lazy var y = f()

          private var z: Set<String> = []
        }

        func f() -> Int { 0 }
        """

        let options = FormatOptions(indent: "  ")
        testFormatting(
            for: input, rule: .organizeDeclarations, options: options,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .wrapFunctionBodies],
        )
    }

    @Test func organizesProtocol() {
        let input = """
        protocol Foo {
            func foo()
            var bar: Bar { get }
            func baaz()
            associatedtype Baaz
            var quux: Quux { get set }
            associatedtype Quux
        }
        """

        let output = """
        protocol Foo {
            associatedtype Baaz
            associatedtype Quux

            var bar: Bar { get }
            var quux: Quux { get set }

            func foo()
            func baaz()
        }
        """

        let options = FormatOptions(organizeTypes: ["protocol"])
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options)
    }

    @Test func organizesProtocolWithInit() {
        let input = """
        public protocol Foo {
            func foo()
            func bar()
            init()
        }
        """

        let output = """
        public protocol Foo {
            init()

            func foo()
            func bar()
        }
        """

        let options = FormatOptions(organizeTypes: ["protocol"])
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options)
    }

    @Test func belowCustomStructMarkThreshold() {
        let input = """
        struct SmallStruct {
            func foo() {}
            let a = 1
            private let b = 2
        }
        """

        let output = """
        struct SmallStruct {
            let a = 1

            func foo() {}

            private let b = 2
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 20),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func organizedStructNowOverMarkThreshold() {
        let input = """
        struct SmallStruct {
            func foo() {}
            let a = 1
            private let b = 2
        }
        """

        let output = """
        struct SmallStruct {

            // MARK: Internal

            let a = 1

            func foo() {}

            // MARK: Private

            private let b = 2
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 4),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func belowCustomStructMarkThresholdDoesNotRemoveMarks() {
        let input = """
        struct SmallStruct {

            // MARK: Internal

            let a = 1

            func foo() {}

            // MARK: Private

            private let b = 2
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 20),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func aboveCustomStructMarkThreshold() {
        let input = """
        public struct LargeStruct {
            let a = 1
            let b = 2
            let c = 3
            public func foo() {}
            public func bar() {}
            public func baz() {}
        }
        """

        let output = """
        public struct LargeStruct {

            // MARK: Public

            public func foo() {}
            public func bar() {}
            public func baz() {}

            // MARK: Internal

            let a = 1
            let b = 2
            let c = 3
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 5),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func typeBodyMarksPreserved() {
        let input = """
        class Foo {

            // MARK: Unexpected comment

            var bar: String = "bar"

            // MARK: Some other comment

            func baz() {}

            // MARK: Lifecycle
            init() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            // MARK: Unexpected comment

            var bar: String = "bar"

            // MARK: Some other comment

            func baz() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .preserve),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .blankLinesAroundMark],
        )
    }

    @Test func typeBodyMarksRemoved() {
        let input = """
        class Foo {

            // MARK: Unexpected comment

            var bar: String = "bar"

            // MARK: Some other comment

            func baz() {}

            // MARK: Lifecycle

            init() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            var bar: String = "bar"

            func baz() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .remove),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func typeBodyMarksPreserveValidMarks() {
        let input = """
        class Foo {

            // MARK: Some unexpected comment

            var bar: String = "bar"

            // MARK: Internal

            func validComment() {}

            init() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            var bar: String = "bar"

            func validComment() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .remove),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func typeBodyMarksWithTypeMode() {
        let input = """
        class Foo {

            // MARK: Unexpected section

            var bar: String = "bar"

            // MARK: Not a function category
            func baz() {}

            init() {}

        }
        """

        let output = """
        class Foo {

            // MARK: Properties

            var bar: String = "bar"

            // MARK: Lifecycle

            init() {}

            // MARK: Functions

            func baz() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                categoryMarkComment: "MARK: %c",
                organizationMode: .type,
                typeBodyMarks: .remove,
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func removesAllUnnecessaryMarkAfterStandardMark() {
        let input = """
        public class Foo {

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            // MARK: Implementation

            func method() {}

            // MARK: Testing

            func testMethod() {}

        }
        """

        let output = """
        public class Foo {

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func method() {}

            func testMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .remove),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func organizesProtocolWithAsync() {
        // Async variables are not allowed in protocols
        let input = """
        protocol Foo {
            func foo() async
            var bar: Bar { get }

            func baaz()
                async
            var quux: Quux { get }
        }
        """

        let output = """
        protocol Foo {
            var bar: Bar { get }

            var quux: Quux { get }

            func foo() async
            func baaz()
                async
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["protocol"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func handlesMalformedPropertyType() {
        let input = """
        extension Foo {
            /// Invalid type, should still get handled properly
            private var foo: FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }
        }

        extension Foo {
            /// Invalid type, should still get handled properly
            func foo() -> FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["extension"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func movesInternalPropertyOutOfPrivateSection() {
        // Internal property `placement` should be moved from Private section to Internal section
        let input = """
        private struct Foo: View {

            // MARK: Internal

            var body: some View {
                EmptyView()
            }

            // MARK: Private

            @Environment(\\.bar) private var bar
            @Environment(\\.baz) private var baz

            let placement: Placement

        }
        """

        let output = """
        private struct Foo: View {

            // MARK: Internal

            let placement: Placement

            var body: some View {
                EmptyView()
            }

            // MARK: Private

            @Environment(\\.bar) private var bar
            @Environment(\\.baz) private var baz

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func privateVarWithDefaultValuePreventsReordering() {
        // private var with default value is still part of memberwise init (optional param),
        // so reordering stored properties would break the init.
        // Section headers can be added, but the order must be preserved (bar before baz).
        let input = """
        struct Foo {
            let bar: Bar
            private var baz = Baz()
        }
        """

        let output = """
        struct Foo {

            // MARK: Internal

            let bar: Bar

            // MARK: Private

            private var baz = Baz()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .propertyTypes],
        )
    }

    @Test func privateLetWithDefaultValueAllowsReordering() {
        // `private let` with default value, or `@State private var` with default value,
        // is NOT part of memberwise init so it can be freely reordered (baz moves after bar)
        let input = """
        struct Foo {
            private let baz = Baz()
            @State private var foo: Foo?
            let bar: Bar
        }
        """

        let output = """
        struct Foo {

            // MARK: Internal

            let bar: Bar

            // MARK: Private

            @State private var foo: Foo?

            private let baz = Baz()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .propertyTypes],
        )
    }
}
