import Testing
@testable import Swiftiomatic

@Suite struct SortDeclarationsTests {
    @Test func sortEnumBody() {
        let input = """
        // sm:sort
        enum FeatureFlags {
            case upsellB
            case fooFeature(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            case barFeature // Trailing comment -- bar feature
            /// Leading comment -- upsell A
            case upsellA(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
        }

        enum NextType {
            case foo
            case bar
        }
        """

        let output = """
        // sm:sort
        enum FeatureFlags {
            case barFeature // Trailing comment -- bar feature
            case fooFeature(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            /// Leading comment -- upsell A
            case upsellA(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            case upsellB
        }

        enum NextType {
            case foo
            case bar
        }
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    @Test func sortEnumBodyWithOnlyOneCase() {
        let input = """
        // sm:sort
        enum FeatureFlags {
            case upsellB
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    @Test func sortEnumBodyWithoutCase() {
        let input = """
        // sm:sort
        enum FeatureFlags {}
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    @Test func noSortUnannotatedType() {
        let input = """
        enum FeatureFlags {
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    @Test func preservesSortedBody() {
        let input = """
        // sm:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    @Test func sortsTypeBody() {
        let input = """
        // sm:sort
        enum FeatureFlags {
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
        }
        """

        let output = """
        // sm:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
        }
        """

        testFormatting(
            for: input, output, rule: .sortDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
        )
    }

    @Test func sortClassWithMixedDeclarationTypes() {
        let input = """
        // sm:sort
        class Foo {
            let quuxProperty = Quux()
            let barProperty = Bar()

            var fooComputedProperty: Foo {
                Foo()
            }

            func baazFunction() -> Baaz {
                Baaz()
            }
        }
        """

        let output = """
        // sm:sort
        class Foo {
            func baazFunction() -> Baaz {
                Baaz()
            }
            let barProperty = Bar()

            var fooComputedProperty: Foo {
                Foo()
            }

            let quuxProperty = Quux()
        }
        """

        testFormatting(
            for: input, [output],
            rules: [.sortDeclarations, .consecutiveBlankLines],
            exclude: [.blankLinesBetweenScopes, .propertyTypes],
        )
    }

    @Test func sortBetweenDirectiveCommentsInType() {
        let input = """
        enum FeatureFlags {
            // sm:sort:begin
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
            // sm:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        let output = """
        enum FeatureFlags {
            // sm:sort:begin
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
            // sm:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    @Test func sortTopLevelDeclarations() {
        let input = """
        let anUnsortedGlobal = 0

        // sm:sort:begin
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        // sm:sort:end

        let anotherUnsortedGlobal = 9
        """

        let output = """
        let anUnsortedGlobal = 0

        // sm:sort:begin
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        // sm:sort:end

        let anotherUnsortedGlobal = 9
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    @Test func sortDeclarationsSortsByNamePattern() {
        let input = """
        enum Namespace {}

        extension Namespace {
            static let foo = "foo"
            public static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        let output = """
        enum Namespace {}

        extension Namespace {
            static let baaz = "baaz"
            public static let bar = "bar"
            static let foo = "foo"
        }
        """

        let options = FormatOptions(alphabeticallySortedDeclarationPatterns: ["Namespace"])
        testFormatting(
            for: input, [output], rules: [.sortDeclarations, .blankLinesBetweenScopes],
            options: options,
            exclude: [.redundantPublic],
        )
    }

    @Test func sortDeclarationsWontSortByNamePatternInComment() {
        let input = """
        enum Namespace {}

        /// Constants
        /// enum Constants
        extension Namespace {
            static let foo = "foo"
            public static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        let options = FormatOptions(alphabeticallySortedDeclarationPatterns: ["Constants"])
        testFormatting(
            for: input, rules: [.sortDeclarations, .blankLinesBetweenScopes], options: options,
            exclude: [.redundantPublic],
        )
    }

    @Test func sortDeclarationsUsesLocalizedCompare() {
        let input = """
        // sm:sort
        enum FeatureFlags {
            case upsella
            case upsellA
            case upsellb
            case upsellB
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    @Test func sortEnumNamespaceSmallerThanOrganizeDeclarationsEnumThreshold() {
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

        let options = FormatOptions(organizeEnumThreshold: 20)
        testFormatting(
            for: input, [output], rules: [.sortDeclarations, .organizeDeclarations],
            options: options,
        )
    }

    @Test func sortStructSmallerThanOrganizeDeclarationsEnumThreshold() {
        let input = """
        // sm:sort
        public struct Foo {
            public let foo = "foo"
            public let bar = "bar"
            public let baaz = "baaz"
        }
        """

        let output = """
        // sm:sort
        public struct Foo {
            public let baaz = "baaz"
            public let bar = "bar"
            public let foo = "foo"
        }
        """

        let options = FormatOptions(organizeStructThreshold: 20)
        testFormatting(
            for: input, [output], rules: [.sortDeclarations, .organizeDeclarations],
            options: options,
        )
    }
}
