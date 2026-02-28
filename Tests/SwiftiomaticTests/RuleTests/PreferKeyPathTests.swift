import Testing
@testable import Swiftiomatic

@Suite struct PreferKeyPathTests {
    @Test func mapPropertyToKeyPath() {
        let input = """
        let foo = bar.map { $0.foo }
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .preferKeyPath,
            options: options,
        )
    }

    @Test func compactMapPropertyToKeyPath() {
        let input = """
        let foo = bar.compactMap { $0.foo }
        """
        let output = """
        let foo = bar.compactMap(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .preferKeyPath,
            options: options,
        )
    }

    @Test func flatMapPropertyToKeyPath() {
        let input = """
        let foo = bar.flatMap { $0.foo }
        """
        let output = """
        let foo = bar.flatMap(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .preferKeyPath,
            options: options,
        )
    }

    @Test func mapNestedPropertyWithSpacesToKeyPath() {
        let input = """
        let foo = bar.map { $0 . foo . bar }
        """
        let output = """
        let foo = bar.map(\\ . foo . bar)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .preferKeyPath,
            options: options, exclude: [.spaceAroundOperators],
        )
    }

    @Test func multilineMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map {
            $0.foo
        }
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .preferKeyPath,
            options: options,
        )
    }

    @Test func parenthesizedMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map({ $0.foo })
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .preferKeyPath,
            options: options,
        )
    }

    @Test func noMapSelfToKeyPath() {
        let input = """
        let foo = bar.map { $0 }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func noMapPropertyToKeyPathForSwiftLessThan5_2() {
        let input = """
        let foo = bar.map { $0.foo }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func noMapPropertyToKeyPathForFunctionCalls() {
        let input = """
        let foo = bar.map { $0.foo() }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func noMapPropertyToKeyPathForCompoundExpressions() {
        let input = """
        let foo = bar.map { $0.foo || baz }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func noMapPropertyToKeyPathForOptionalChaining() {
        let input = """
        let foo = bar.map { $0?.foo }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func noMapPropertyToKeyPathForTrailingContains() {
        let input = """
        let foo = bar.contains { $0.foo }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func mapPropertyToKeyPathForContainsWhere() {
        let input = """
        let foo = bar.contains(where: { $0.foo })
        """
        let output = """
        let foo = bar.contains(where: \\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath, options: options)
    }

    @Test func multipleTrailingClosuresNotConvertedToKeyPath() {
        let input = """
        foo.map { $0.bar } reverse: { $0.bar }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func selfNotConvertedToKeyPathBeforeSwift6() {
        // https://bugs.swift.org/browse/SR-12897
        let input = """
        let foo = bar.compactMap { $0 }
        """
        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    @Test func selfConvertedToKeyPath() {
        let input = """
        let foo = bar.compactMap { $0 }
        """
        let output = """
        let foo = bar.compactMap(\\.self)
        """
        let options = FormatOptions(swiftVersion: "6")
        testFormatting(for: input, output, rule: .preferKeyPath, options: options)
    }
}
