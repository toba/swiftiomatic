import Testing
@testable import Swiftiomatic

@Suite struct WrapEnumCasesTests {
    @Test func multilineEnumCases() {
        let input = """
        enum Enum1: Int {
            case a = 0, p = 2, c, d
            case e, k
            case m(String, String)
        }
        """
        let output = """
        enum Enum1: Int {
            case a = 0
            case p = 2
            case c
            case d
            case e
            case k
            case m(String, String)
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    @Test func multilineEnumCasesWithNestedEnumsDoesNothing() {
        let input = """
        public enum SearchTerm: Decodable, Equatable {
            case term(name: String)
            case category(category: Category)

            enum CodingKeys: String, CodingKey {
                case name
                case type
                case categoryID = "category_id"
                case attributes
            }
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases)
    }

    @Test func enumCaseSplitOverMultipleLines() {
        let input = """
        enum Foo {
            case bar(
                x: String,
                y: Int
            ), baz
        }
        """
        let output = """
        enum Foo {
            case bar(
                x: String,
                y: Int
            )
            case baz
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    @Test func enumCasesAlreadyWrappedOntoMultipleLines() {
        let input = """
        enum Foo {
            case bar,
                 baz,
                 quux
        }
        """
        let output = """
        enum Foo {
            case bar
            case baz
            case quux
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    @Test func enumCasesIfValuesWithoutValuesDoesNothing() {
        let input = """
        enum Foo {
            case bar, baz, quux
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapEnumCases: .withValues))
    }

    @Test func enumCasesIfValuesWithRawValuesAndNestedEnum() {
        let input = """
        enum Foo {
            case bar = 1, baz, quux

            enum Foo2 {
                case bar, baz, quux
            }
        }
        """
        let output = """
        enum Foo {
            case bar = 1
            case baz
            case quux

            enum Foo2 {
                case bar, baz, quux
            }
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .wrapEnumCases,
            options: FormatOptions(wrapEnumCases: .withValues)
        )
    }

    @Test func enumCasesIfValuesWithAssociatedValues() {
        let input = """
        enum Foo {
            case bar(a: Int), baz, quux
        }
        """
        let output = """
        enum Foo {
            case bar(a: Int)
            case baz
            case quux
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .wrapEnumCases,
            options: FormatOptions(wrapEnumCases: .withValues)
        )
    }

    @Test func enumCasesWithCommentsAlreadyWrappedOntoMultipleLines() {
        let input = """
        enum Foo {
            case bar, // bar
                 baz, // baz
                 quux // quux
        }
        """
        let output = """
        enum Foo {
            case bar // bar
            case baz // baz
            case quux // quux
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    @Test func noWrapEnumStatementAllOnOneLine() {
        let input = """
        enum Foo { bar, baz }
        """
        testFormatting(for: input, rule: .wrapEnumCases)
    }

    @Test func noConfuseIfCaseWithEnum() {
        let input = """
        enum Foo {
            case foo
            case bar(value: [Int])
        }

        func baz() {
            if case .foo = foo,
               case .bar(let value) = bar,
               value.isEmpty
            {
                print("")
            }
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       exclude: [.hoistPatternLet])
    }

    @Test func noMangleUnindentedEnumCases() {
        let input = """
        enum Foo {
        case foo, bar
        }
        """
        let output = """
        enum Foo {
        case foo
        case bar
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases, exclude: [.indent])
    }

    @Test func noMangleEnumCaseOnOpeningLine() {
        let input = """
        enum SortOrder { case
            asc(String), desc(String)
        }
        """
        // TODO: improve formatting here
        let output = """
        enum SortOrder { case
            asc(String)
        case desc(String)
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases, exclude: [.indent])
    }

    @Test func noWrapSingleLineEnumCases() {
        let input = """
        enum Foo { case foo, bar }
        """
        testFormatting(for: input, rule: .wrapEnumCases)
    }

    @Test func noMangleSequentialEnums() {
        let input = """
        // enums

        @objc public enum TestType: Int {
            case value1 = 0, value2 = 1
        }

        public struct TestStruct: Equatable, Comparable {
            public enum TestEnum {
                case value1, value2, value3
            }

            public enum TestEnumAnother {
                case value4, value5, value6
            }
        }
        """
        let output = """
        // enums

        @objc public enum TestType: Int {
            case value1 = 0
            case value2 = 1
        }

        public struct TestStruct: Equatable, Comparable {
            public enum TestEnum {
                case value1
                case value2
                case value3
            }

            public enum TestEnumAnother {
                case value4
                case value5
                case value6
            }
        }
        """

        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    @Test func packageEnumWithProtocolConformances() {
        let input = """
        enum Outer {
            case outerCase, otherOuterCase

            package enum Inner: String, CaseIterable, Codable {
                case innerCase
            }
        }
        """
        let output = """
        enum Outer {
            case outerCase
            case otherOuterCase

            package enum Inner: String, CaseIterable, Codable {
                case innerCase
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }
}
