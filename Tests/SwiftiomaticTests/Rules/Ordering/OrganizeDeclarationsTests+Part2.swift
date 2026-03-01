import Testing
@testable import Swiftiomatic

extension OrganizeDeclarationsTests {
    @Test func customCategoryNamesInTypeOrder() {
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

            // MARK: Bar_Bar

            public var bar: Bar

            // MARK: Init

            init(bar: Bar) {
                self.bar = bar
            }

            // MARK: Buuuz Lightyeeeaaar

            func baaz() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                customTypeMarks: [
                    "instanceLifecycle:Init", "instanceProperty:Bar_Bar",
                    "instanceMethod:Buuuz Lightyeeeaaar",
                ],
            ),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func classNestedInClassIsOrganized() {
        let input = """
        public class Foo {
            public class Bar {
                fileprivate func baz() {}
                public var quux: Int
                init() {}
                deinit {}
            }
        }
        """

        let output = """
        public class Foo {
            public class Bar {

                // MARK: Lifecycle

                init() {}
                deinit {}

                // MARK: Public

                public var quux: Int

                // MARK: Fileprivate

                fileprivate func baz() {}
            }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .enumNamespaces],
        )
    }

    @Test func structNestedInExtensionIsOrganized() {
        let input = """
        public extension Foo {
            struct Bar {
                private var foo: Int
                private let bar: Int

                public var foobar: (Int, Int) {
                    (foo, bar)
                }

                public init(foo: Int, bar: Int) {
                    self.foo = foo
                    self.bar = bar
                }
            }
        }
        """

        let output = """
        public extension Foo {
            struct Bar {

                // MARK: Lifecycle

                public init(foo: Int, bar: Int) {
                    self.foo = foo
                    self.bar = bar
                }

                // MARK: Public

                public var foobar: (Int, Int) {
                    (foo, bar)
                }

                // MARK: Private

                private var foo: Int
                private let bar: Int

            }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func organizePrivateSet() {
        let input = """
        public class Foo {
            public private(set) var bar: Int
            private(set) var baz: Int
            internal private(set) var baz: Int
        }
        """

        let output = """
        public class Foo {

            // MARK: Public

            public private(set) var bar: Int

            // MARK: Internal

            private(set) var baz: Int
            internal private(set) var baz: Int
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .redundantInternal],
        )
    }

    @Test func sortDeclarationTypes() {
        let input = """
        class Foo {
            static var a1: Int = 1
            static var a2: Int = 2
            var d1: CGFloat {
                3.141592653589
            }

            class var b2: String {
                "class computed property"
            }

            func g() -> Int {
                10
            }

            let c: String = String {
                "closure body"
            }()

            static func e() {}

            typealias Bar = Int

            static var b1: String {
                "static computed property"
            }

            class func f() -> Foo {
                Foo()
            }

            enum NestedEnum {}

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }
        }
        """

        let output = """
        class Foo {
            typealias Bar = Int

            enum NestedEnum {}

            static var a1: Int = 1
            static var a2: Int = 2

            static var b1: String {
                "static computed property"
            }

            class var b2: String {
                "class computed property"
            }

            let c: String = String {
                "closure body"
            }()

            var d1: CGFloat {
                3.141592653589
            }

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }

            static func e() {}

            class func f() -> Foo {
                Foo()
            }

            func g() -> Int {
                10
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtEndOfScope, .redundantType, .redundantClosure],
        )
    }

    @Test func sortDeclarationTypesByType() {
        let input = """
        class Foo {
            var a: Int
            init(a: Int) {
                self.a = a
            }
            private convenience init() {
                self.init(a: 0)
            }

            static var a1: Int = 1
            static var a2: Int = 2
            var d1: CGFloat {
                3.141592653589
            }

            class var b2: String {
                "class computed property"
            }

            func g() -> Int {
                10
            }

            let c: String = String {
                "closure body"
            }()

            static func e() {}

            typealias Bar = Int

            static var b1: String {
                "static computed property"
            }

            class func f() -> Foo {
                Foo()
            }

            enum NestedEnum {}

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }
        }
        """

        let output = """
        class Foo {

            // MARK: Nested Types

            typealias Bar = Int

            enum NestedEnum {}

            // MARK: Static Properties

            static var a1: Int = 1
            static var a2: Int = 2

            // MARK: Static Computed Properties

            static var b1: String {
                "static computed property"
            }

            // MARK: Class Properties

            class var b2: String {
                "class computed property"
            }

            // MARK: Properties

            var a: Int
            let c: String = String {
                "closure body"
            }()

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }

            // MARK: Computed Properties

            var d1: CGFloat {
                3.141592653589
            }

            // MARK: Lifecycle

            init(a: Int) {
                self.a = a
            }

            private convenience init() {
                self.init(a: 0)
            }

            // MARK: Static Functions

            static func e() {}

            // MARK: Class Functions

            class func f() -> Foo {
                Foo()
            }

            // MARK: Functions

            func g() -> Int {
                10
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [
                .blankLinesAtEndOfScope, .blankLinesAtStartOfScope, .redundantType,
                .redundantClosure,
            ],
        )
    }

    @Test func organizeEnumCasesFirst() {
        let input = """
        enum Foo {
            init?(rawValue: String) {
                return nil
            }

            case bar
            case baz
            case quux
        }
        """

        let output = """
        enum Foo {
            case bar
            case baz
            case quux

            // MARK: Lifecycle

            init?(rawValue: String) {
                return nil
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtEndOfScope, .unusedArguments],
        )
    }

    @Test func placingCustomDeclarationsBeforeMarks() {
        let input = """
        public struct Foo {

            public init() {}

            public typealias Bar = Int

            public struct Baz {}

        }
        """

        let output = """
        public struct Foo {

            public typealias Bar = Int

            public struct Baz {}

            // MARK: Lifecycle

            public init() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(beforeMarks: ["typealias", "struct"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func customLifecycleMethods() {
        let input = """
        public class ViewController: UIViewController {

            public init() {
                super.init(nibName: nil, bundle: nil)
            }

            func viewDidLoad() {
                super.viewDidLoad()
            }

            func internalInstanceMethod() {}

            func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
            }

        }
        """

        let output = """
        public class ViewController: UIViewController {

            // MARK: Lifecycle

            public init() {
                super.init(nibName: nil, bundle: nil)
            }

            func viewDidLoad() {
                super.viewDidLoad()
            }

            func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
            }

            // MARK: Internal

            func internalInstanceMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(lifecycleMethods: [
                "viewDidLoad",
                "viewWillAppear",
                "viewDidAppear",
            ]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func customCategoryMarkTemplate() {
        let input = """
        public struct Foo {
            public init() {}
            public func publicInstanceMethod() {}
        }
        """

        let output = """
        public struct Foo {

            // - Lifecycle

            public init() {}

            // - Public

            public func publicInstanceMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "- %c"),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func belowCustomStructOrganizationThreshold() {
        let input = """
        struct StructBelowThreshold {
            init() {}
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 2),
        )
    }

    @Test func aboveCustomStructOrganizationThreshold() {
        let input = """
        public struct StructAboveThreshold {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        public struct StructAboveThreshold {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 2),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func customClassOrganizationThreshold() {
        let input = """
        class ClassBelowThreshold {
            init() {}
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeClassThreshold: 2),
        )
    }

    @Test func customEnumOrganizationThreshold() {
        let input = """
        enum EnumBelowThreshold {
            case enumCase
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeEnumThreshold: 2),
        )
    }

    @Test func belowCustomExtensionOrganizationThreshold() {
        let input = """
        extension FooBelowThreshold {
            func bar() {}
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["class", "struct", "enum", "extension"],
                organizeExtensionThreshold: 2,
            ),
        )
    }

    @Test func aboveCustomExtensionOrganizationThreshold() {
        let input = """
        extension FooBelowThreshold {
            public func bar() {}
            func baz() {}
            private func quux() {}
        }
        """

        let output = """
        extension FooBelowThreshold {

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func baz() {}

            // MARK: Private

            private func quux() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["class", "struct", "enum", "extension"],
                organizeExtensionThreshold: 2,
            ), exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func preservesExistingMarks() {
        let input = """
        actor Foo {

            // MARK: Lifecycle

            init(json: JSONObject) throws {
                bar = try json.value(for: "bar")
                baz = try json.value(for: "baz")
            }

            // MARK: Internal

            let bar: String
            let baz: Int?
        }
        """
        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func updatesMalformedMarks() {
        let input = """
        public actor Foo {

            // MARK: lifecycle

            // MARK: Lifeycle

            init() {}

            // mark: Public

            // mark - Public

            public func bar() {}

            // MARK: - Internal

            func baz() {}

            // mrak: privat

            // Pulse

            private func quux() {}
        }
        """

        let output = """
        public actor Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func baz() {}

            // MARK: Private

            // Pulse

            private func quux() {}
        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func doesNotAttemptToUpdateMarksNotAtTopLevel() {
        let input = """
        public class Foo {

            // MARK: Lifecycle

            public init() {
                foo = ["foo"]
            }

            // Comment at bottom of lifecycle category

            // MARK: Private

            @annotation // Private
            /// Private
            private var foo: [String] = []

            private func bar() {
                // Private
                guard let baz = bar else {
                    return
                }
            }
        }
        """

        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .docCommentsBeforeModifiers],
        )
    }

    @Test func handlesTrailingCommentCorrectly() {
        let input = """
        public class Foo {
            var bar = "bar"
            /// Leading comment
            public var baz = "baz" // Trailing comment
            var quux = "quux"
        }
        """

        let output = """
        public class Foo {

            // MARK: Public

            /// Leading comment
            public var baz = "baz" // Trailing comment

            // MARK: Internal

            var bar = "bar"
            var quux = "quux"
        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func doesNotInsertMarkWhenOnlyOneCategory() {
        let input = """
        class Foo {
            var bar: Int
            var baz: Int
            func instanceMethod() {}
        }
        """

        let output = """
        class Foo {
            var bar: Int
            var baz: Int

            func instanceMethod() {}
        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations)
    }

    @Test func organizesTypesWithinConditionalCompilationBlock() {
        let input = """
        #if DEBUG
        public struct DebugFoo {
            init() {}
            public func instanceMethod() {}
        }
        #else
        public struct ProductionFoo {
            init() {}
            public func instanceMethod() {}
        }
        #endif
        """

        let output = """
        #if DEBUG
        public struct DebugFoo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        #else
        public struct ProductionFoo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        #endif
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations,
            options: FormatOptions(ifdefIndent: .noIndent),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

    @Test func organizesTypesBelowConditionalCompilationBlock() {
        let input = """
        #if canImport(UIKit)
        import UIKit
        #endif

        public struct Foo {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        #if canImport(UIKit)
        import UIKit
        #endif

        public struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations,
            options: FormatOptions(ifdefIndent: .noIndent),
            exclude: [.blankLinesAtStartOfScope],
        )
    }

}
