import Testing
@testable import Swiftiomatic

extension WrapArgumentsTests {
    // MARK: wrapConditions before-first

    @Test func wrapConditionsBeforeFirstPreservesMultilineStatements() {
        let input = """
        if
            let unwrappedFoo = Foo(
                bar: bar,
                baz: baz),
            unwrappedFoo.elements
                .compactMap({ $0 })
                .filter({
                    if $0.matchesCondition {
                        return true
                    } else {
                        return false
                    }
                })
                .isEmpty,
            let bar = unwrappedFoo.bar,
            let baz = unwrappedFoo.bar?
                .first(where: { $0.isBaz }),
            let unwrappedFoo2 = Foo(
                bar: bar2,
                baz: baz2),
            let quux = baz.quux
        {}
        """
        testFormatting(
            for: input, rules: [.wrapArguments, .indent],
            options: FormatOptions(closingParenPosition: .sameLine, wrapConditions: .beforeFirst),
            exclude: [.propertyTypes],
        )
    }

    @Test func wrapConditionsBeforeFirst() {
        let input = """
        if let foo = foo,
           let bar = bar,
           foo == bar {}

        else if foo != bar,
                let quux = quux {}

        if let baz = baz {}

        guard baz.filter({ $0 == foo }),
              let bar = bar else {}

        while let foo = foo,
              let bar = bar {}
        """
        let output = """
        if
          let foo = foo,
          let bar = bar,
          foo == bar {}

        else if
          foo != bar,
          let quux = quux {}

        if let baz = baz {}

        guard
          baz.filter({ $0 == foo }),
          let bar = bar else {}

        while
          let foo = foo,
          let bar = bar {}
        """
        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func wrapConditionsBeforeFirstWhereShouldPreserveExisting() {
        let input = """
        else {}

        else
        {}

        if foo == bar
        {}

        guard let foo = bar else
        {}

        guard let foo = bar
        else {}
        """
        testFormatting(
            for: input, rule: .wrapArguments,
            options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
            exclude: [.elseOnSameLine, .wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }

    @Test func wrapConditionsAfterFirst() {
        let input = """
        if
          let foo = foo,
          let bar = bar,
          foo == bar {}

        else if
          foo != bar,
          let quux = quux {}

        else {}

        if let baz = baz {}

        guard
          baz.filter({ $0 == foo }),
          let bar = bar else {}

        while
          let foo = foo,
          let bar = bar {}
        """
        let output = """
        if let foo = foo,
           let bar = bar,
           foo == bar {}

        else if foo != bar,
                let quux = quux {}

        else {}

        if let baz = baz {}

        guard baz.filter({ $0 == foo }),
              let bar = bar else {}

        while let foo = foo,
              let bar = bar {}
        """
        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(indent: "  ", wrapConditions: .afterFirst),
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func wrapConditionsAfterFirstWhenFirstLineIsComment() {
        let input = """
        guard
            // Apply this rule to any function-like declaration
            ["func", "init", "subscript"].contains(keyword.string),
            // Opaque generic parameter syntax is only supported in Swift 5.7+
            formatter.options.swiftVersion >= "5.7",
            // Validate that this is a generic method using angle bracket syntax,
            // and find the indices for all of the key tokens
            let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
            let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
            let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
            let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
            genericSignatureStartIndex < paramListStartIndex,
            genericSignatureEndIndex < paramListStartIndex,
            let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
            let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
        else { return }
        """
        let output = """
        guard // Apply this rule to any function-like declaration
            ["func", "init", "subscript"].contains(keyword.string),
            // Opaque generic parameter syntax is only supported in Swift 5.7+
            formatter.options.swiftVersion >= "5.7",
            // Validate that this is a generic method using angle bracket syntax,
            // and find the indices for all of the key tokens
            let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
            let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
            let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
            let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
            genericSignatureStartIndex < paramListStartIndex,
            genericSignatureEndIndex < paramListStartIndex,
            let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
            let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
        else { return }
        """
        testFormatting(
            for: input, [output], rules: [.wrapArguments, .indent],
            options: FormatOptions(wrapConditions: .afterFirst),
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func wrapPartiallyWrappedFunctionCall() {
        let input = """
        func foo(
            bar: Bar, baaz: Baaz,
            quux: Quux,
        ) {
            print(
                bar, baaz,
            )
        }
        """

        let output = """
        func foo(
            bar: Bar,
            baaz: Baaz,
            quux: Quux,
        ) {
            print(
                bar,
                baaz,
            )
        }
        """

        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false),
            exclude: [.unusedArguments, .trailingCommas],
        )
    }

    @Test func wrapPartiallyWrappedFunctionCallTwoLines() {
        let input = """
        func foo(
            foo: Foo, bar: Bar,
            baaz: Baaz, quux: Quux
        ) {
            print(
                foo, bar,
                baaz, quux
            )
        }
        """

        let output = """
        func foo(
            foo: Foo,
            bar: Bar,
            baaz: Baaz,
            quux: Quux
        ) {
            print(
                foo,
                bar,
                baaz,
                quux
            )
        }
        """

        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false),
        )
    }

    @Test func wrapPartiallyWrappedArray() {
        let input = """
        let foo = [
            foo, bar,
            baaz, quux,
        ]
        """

        let output = """
        let foo = [
            foo,
            bar,
            baaz,
            quux,
        ]
        """

        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false),
        )
    }

    @Test func arrayWithBlankLine() {
        let input = """
        let foo = [
            foo,
            bar,

            baaz,
            quux,
        ]
        """

        testFormatting(
            for: input, rule: .wrapArguments,
            options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false),
        )
    }

    @Test func partiallyWrappedArrayWithBlankLine() {
        let input = """
        let foo = [
            foo, bar,

            baaz, quux,
        ]
        """

        let output = """
        let foo = [
            foo,
            bar,

            baaz,
            quux,
        ]
        """

        testFormatting(
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(wrapArguments: .beforeFirst, allowPartialWrapping: false),
        )
    }

    @Test func wrapArgumentsBeforeFirstDoesNotWrapClosingParenIfFirstArgumentNotWrapped() {
        let input = """
        return .tuple(string
            .split { $0.isNewline }
            .map { .string("\\($0)") })
        """

        testFormatting(
            for: input, rule: .wrapArguments,
            options: FormatOptions(
                wrapArguments: .beforeFirst, closingParenPosition: .balanced, maxWidth: 1000,
            ),
        )
    }
}
