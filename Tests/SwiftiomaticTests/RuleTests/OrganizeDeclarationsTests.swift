import Testing
@testable import Swiftiomatic

@Suite struct OrganizeDeclarationsTests {
    @Test func organizeClassDeclarationsIntoCategories() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            package func packageMethod() {}
            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            /*
             * Block comment
             */

            init() {}

            /// Doc comment
            public func publicMethod() {}

            #if DEBUG
                private var foo: Foo? { nil }
            #endif
        }

        enum Bar {
            private var bar: Bar { Bar() }
            case enumCase
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            /*
             * Block comment
             */

            init() {}

            // MARK: Open

            open var quack = 2

            // MARK: Public

            public let baz = 1

            /// Doc comment
            public func publicMethod() {}

            // MARK: Package

            package func packageMethod() {}

            // MARK: Internal

            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            // MARK: Private

            private let bar = 1

            #if DEBUG
                private var foo: Foo? { nil }
            #endif

            private func privateMethod() {}

        }

        enum Bar {
            case enumCase

            // MARK: Private

            private var bar: Bar { Bar() }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .wrapPropertyBodies],
        )
    }

    @Test func organizeClassDeclarationsIntoCategoriesWithCustomTypeOrder() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            package func packageMethod() {}
            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            /*
             * Block comment
             */

            init() {}

            /// Doc comment
            public func publicMethod() {}

            #if DEBUG
                private var foo: Foo? { nil }
            #endif
        }

        enum Bar {
            private var bar: Bar { Bar() }
            case enumCase
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            /*
             * Block comment
             */

            init() {}

            // MARK: Open

            open var quack = 2

            // MARK: Public

            public let baz = 1

            /// Doc comment
            public func publicMethod() {}

            // MARK: Package

            package func packageMethod() {}

            // MARK: Internal

            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            // MARK: Private

            private let bar = 1

            #if DEBUG
                private var foo: Foo? { nil }
            #endif

            private func privateMethod() {}

        }

        enum Bar {
            case enumCase

            // MARK: Private

            private var bar: Bar { Bar() }
        }
        """

        // The configuration used in Airbnb's Swift Style Guide,
        // as defined here: https://github.com/airbnb/swift#subsection-organization
        let airbnbVisibilityOrder = """
        beforeMarks,instanceLifecycle,open,public,package,internal,private,fileprivate
        """
        let airbnbTypeOrder = """
        nestedType,staticProperty,staticPropertyWithBody,classPropertyWithBody,instanceProperty,instancePropertyWithBody,staticMethod,classMethod,instanceMethod
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                visibilityOrder: airbnbVisibilityOrder.components(separatedBy: ","),
                typeOrder: airbnbTypeOrder.components(separatedBy: ","),
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .wrapPropertyBodies],
        )
    }

    @Test func organizeClassDeclarationsIntoCategoriesInTypeOrder() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            package func packageMethod() {}
            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            /*
             * Block comment
             */

            init() {}

            /// Doc comment
            public func publicMethod() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Properties

            open var quack = 2

            public let baz = 1

            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            private let bar = 1

            // MARK: Lifecycle

            /*
             * Block comment
             */

            init() {}

            // MARK: Functions

            /// Doc comment
            public func publicMethod() {}

            package func packageMethod() {}

            private func privateMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func organizeTypeWithOverridenFieldsInVisibilityOrder() {
        let input = """
        class Test {

            override var b: Any? { nil }

            var a = ""

            override func bar() -> Bar {
                Bar()
            }

            func foo() -> Foo {
                Foo()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [
                .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .sortImports,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func organizeTypeWithOverridenFieldsInTypeOrder() {
        let input = """
        class Test {

            var a = ""

            override var b: Any? { nil }

            func foo() -> Foo {
                Foo()
            }

            override func bar() -> Bar {
                Bar()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        let output = """
        class Test {

            // MARK: Overridden Properties

            override var b: Any? { nil }

            // MARK: Properties

            var a = ""

            // MARK: Overridden Functions

            override func bar() -> Bar {
                Bar()
            }

            // MARK: Functions

            func foo() -> Foo {
                Foo()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizationMode: .type),
            exclude: [
                .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .sortImports,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func organizeTypeWithSwiftUIMethodInVisibilityOrder() {
        let input = """
        class Test {

            func bar() -> some View {
                EmptyView()
            }

            func foo() -> Foo {
                Foo()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .sortImports],
        )
    }

    @Test func organizeSwiftUIViewInTypeOrder() {
        let input = """
        struct ContentView: View {

            private var label: String

            @State
            var isOn: Bool = false

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

            init(label: String) {
                self.label = label
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: SwiftUI Properties

            @State
            var isOn: Bool = false

            // MARK: Properties

            private var label: String

            // MARK: Lifecycle

            init(label: String) {
                self.label = label
            }

            // MARK: Content Properties

            @ViewBuilder
            var body: some View {
                toggle
            }

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [
                .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
                .redundantViewBuilder,
            ],
        )
    }

    @Test func organizeSwiftUIViewModifierInTypeOrder() {
        let input = """
        struct Modifier: ViewModifier {

            private var label: String

            @State
            var isOn: Bool = false

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

            func body(content: Content) -> some View {
                content
                    .overlay {
                        toggle
                    }
            }

            init(label: String) {
                self.label = label
            }
        }
        """

        let output = """
        struct Modifier: ViewModifier {

            // MARK: SwiftUI Properties

            @State
            var isOn: Bool = false

            // MARK: Properties

            private var label: String

            // MARK: Lifecycle

            init(label: String) {
                self.label = label
            }

            // MARK: Content Properties

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

            // MARK: Content Methods

            func body(content: Content) -> some View {
                content
                    .overlay {
                        toggle
                    }
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [
                .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
                .redundantViewBuilder,
            ],
        )
    }

    @Test func customOrganizationInVisibilityOrder() {
        let input = """
        public class Foo {
            public func bar() {}
            func baz() {}
            private func quux() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Private

            private func quux() {}

            // MARK: Internal

            func baz() {}

            // MARK: Public

            public func bar() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                visibilityOrder: ["private", "internal", "public"],
                typeOrder: DeclarationType.allCases.map(\.rawValue),
            ),
            exclude: [.blankLinesAtStartOfScope, .privateStateVariables],
        )
    }

    @Test func customOrganizationInVisibilityOrderWithParametrizedTypeOrder() {
        let input = """
        public class Foo {

            // MARK: Private

            private func quux() {}

            // MARK: Internal

            var baaz: Baaz

            func baz() {}

            // MARK: Public

            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Private

            private func quux() {}

            // MARK: Internal

            func baz() {}

            var baaz: Baaz

            // MARK: Public

            public func bar() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                visibilityOrder: ["private", "internal", "public"],
                typeOrder: [
                    "beforeMarks", "nestedType", "instanceLifecycle", "instanceMethod",
                    "instanceProperty",
                ],
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func customOrganizationInTypeOrder() {
        let input = """
        public class Foo {
            private func quux() {}
            var baaz: Baaz
            func baz() {}
            init()
            override public func baar()
            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            init()

            // MARK: Functions

            public func bar() {}

            func baz() {}

            private func quux() {}

            // MARK: Properties

            var baaz: Baaz

            // MARK: Overridden Functions

            override public func baar()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                typeOrder: [
                    "beforeMarks", "instanceLifecycle", "instanceMethod", "nestedType",
                    "instanceProperty",
                    "overriddenMethod",
                ],
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func organizeDeclarationsIgnoresNotDefinedCategories() {
        let input = """
        public class Foo {
            private func quux() {}
            var baaz: Baaz
            func baz() {}
            init()
            override public func baar()
            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            init()

            // MARK: Functions

            override public func baar()
            public func bar() {}

            func baz() {}

            private func quux() {}

            // MARK: Properties

            var baaz: Baaz
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                typeOrder: [
                    "beforeMarks", "nestedType", "instanceLifecycle", "instanceMethod",
                    "instanceProperty",
                ],
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func customOrganizationInTypeOrderWithParametrizedVisibilityOrder() {
        let input = """
        public class Foo {
            private func quux() {}
            var baaz: Baaz
            private var fooo: Fooo
            func baz() {}
            init()
            override public func baar()
            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            init()

            // MARK: Functions

            private func quux() {}

            func baz() {}

            public func bar() {}

            // MARK: Properties

            private var fooo: Fooo

            var baaz: Baaz

            // MARK: Overridden Functions

            override public func baar()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                visibilityOrder: ["private", "internal", "public"],
                typeOrder: [
                    "beforeMarks", "nestedType", "instanceLifecycle", "instanceMethod",
                    "instanceProperty",
                    "overriddenMethod",
                ],
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func customDeclarationTypeUsedAsTopLevelCategory() {
        let input = """
        class Test {
            private let foo = "foo"
            func bar() {}
        }
        """

        let output = """
        class Test {

            // MARK: Functions

            func bar() {}

            // MARK: Private

            private let foo = "foo"
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .visibility,
                visibilityOrder: ["instanceMethod"] + Visibility.allCases.map(\.rawValue),
                typeOrder: DeclarationType.allCases.map(\.rawValue)
                    .filter { $0 != "instanceMethod" },
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func visibilityModeWithoutInstanceLifecycle() {
        let input = """
        class Test {
            init() {}
            private func bar() {}
        }
        """

        let output = """
        class Test {

            // MARK: Internal

            init() {}

            // MARK: Private

            private func bar() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .visibility,
                visibilityOrder: Visibility.allCases.map(\.rawValue),
                typeOrder: DeclarationType.allCases.map(\.rawValue),
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func customCategoryNamesInVisibilityOrder() {
        let input = """
        public class Foo {
            public var bar: Bar
            init(bar: Bar) {
                self.bar = bar
            }
            func baaz() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Init

            init(bar: Bar) {
                self.bar = bar
            }

            // MARK: Public_Group

            public var bar: Bar

            // MARK: Internal

            func baaz() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .visibility,
                customVisibilityMarks: ["instanceLifecycle:Init", "public:Public_Group"],
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

}
