import Testing
@testable import Swiftiomatic

@Suite struct PreferForLoopTests {
    @Test func convertSimpleForEachToForLoop() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach { string in
            print(string)
        }

        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach { (string: String) in
            print(string)
        }
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for string in placeholderStrings {
            print(string)
        }

        let placeholderStrings = ["foo", "bar", "baaz"]
        for string in placeholderStrings {
            print(string)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func convertAnonymousForEachToForLoop() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            print($0)
        }

        potatoes.forEach({ $0.bake() })
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for placeholderString in placeholderStrings {
            print(placeholderString)
        }

        potatoes.forEach({ $0.bake() })
        """

        testFormatting(for: input, output, rule: .preferForLoop, exclude: [.trailingClosures])
    }

    @Test func noConvertAnonymousForEachToForLoop() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            print($0)
        }

        potatoes.forEach({ $0.bake() })
        """

        let options = FormatOptions(
            preserveAnonymousForEach: true,
            preserveSingleLineForEach: false,
        )
        testFormatting(
            for: input,
            rule: .preferForLoop,
            options: options,
            exclude: [.trailingClosures],
        )
    }

    @Test func convertSingleLineForEachToForLoop() {
        let input = """
        potatoes.forEach({ item in item.bake() })
        """
        let output = """
        for item in potatoes { item.bake() }
        """

        let options = FormatOptions(preserveSingleLineForEach: false)
        testFormatting(
            for: input, output, rule: .preferForLoop, options: options,
            exclude: [.wrapLoopBodies],
        )
    }

    @Test func convertSingleLineAnonymousForEachToForLoop() {
        let input = """
        potatoes.forEach({ $0.bake() })
        """
        let output = """
        for potato in potatoes { potato.bake() }
        """

        let options = FormatOptions(preserveSingleLineForEach: false)
        testFormatting(
            for: input, output, rule: .preferForLoop, options: options,
            exclude: [.wrapLoopBodies],
        )
    }

    @Test func convertNestedForEach() {
        let input = """
        let nestedArrays = [[1, 2], [3, 4]]
        nestedArrays.forEach {
            $0.forEach {
                $0.forEach {
                    print($0)
                }
            }
        }
        """

        let output = """
        let nestedArrays = [[1, 2], [3, 4]]
        for nestedArray in nestedArrays {
            for item in nestedArray {
                for item in item {
                    print(item)
                }
            }
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func defaultNameAlreadyUsedInLoopBody() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            let placeholderString = $0.uppercased()
            print(placeholderString, $0)
        }
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for item in placeholderStrings {
            let placeholderString = item.uppercased()
            print(placeholderString, item)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func ignoreLoopsWithCaptureListForNow() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach { [someCapturedValue = fooBar] in
            print($0, someCapturedValue)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    @Test func removeAllPrefixFromLoopIdentifier() {
        let input = """
        allWindows.forEach {
            print($0)
        }
        """

        let output = """
        for window in allWindows {
            print(window)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func convertsReturnToContinue() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            func capitalize(_ value: String) -> String {
                return value.uppercased()
            }

            if $0 == "foo" {
                return
            } else {
                print(capitalize($0))
            }
        }
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for placeholderString in placeholderStrings {
            func capitalize(_ value: String) -> String {
                return value.uppercased()
            }

            if placeholderString == "foo" {
                continue
            } else {
                print(capitalize(placeholderString))
            }
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func handlesForEachOnChainedProperties() {
        let input = """
        let bar = foo.bar
        bar.baaz.quux.strings.forEach {
            print($0)
        }
        """

        let output = """
        let bar = foo.bar
        for string in bar.baaz.quux.strings {
            print(string)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func handlesForEachOnFunctionCallResult() {
        let input = """
        let bar = foo.bar
        foo.item().bar[2].baazValues(option: true).forEach {
            print($0)
        }
        """

        let output = """
        let bar = foo.bar
        for baazValue in foo.item().bar[2].baazValues(option: true) {
            print(baazValue)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func handlesForEachOnSubscriptResult() {
        let input = """
        let bar = foo.bar
        foo.item().bar[2].dictionary["myValue"].forEach {
            print($0)
        }
        """

        let output = """
        let bar = foo.bar
        for item in foo.item().bar[2].dictionary["myValue"] {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func handlesForEachOnArrayLiteral() {
        let input = """
        let quux = foo.bar.baaz.quux
        ["foo", "bar", "baaz", quux].forEach {
            print($0)
        }
        """

        let output = """
        let quux = foo.bar.baaz.quux
        for item in ["foo", "bar", "baaz", quux] {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func handlesForEachOnCurriedFunctionWithSubscript() {
        let input = """
        let quux = foo.bar.baaz.quux
        foo(bar)(baaz)["item"].forEach {
            print($0)
        }
        """

        let output = """
        let quux = foo.bar.baaz.quux
        for item in foo(bar)(baaz)["item"] {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func handlesForEachOnArrayLiteralInParens() {
        let input = """
        let quux = foo.bar.baaz.quux
        (["foo", "bar", "baaz", quux]).forEach {
            print($0)
        }
        """

        let output = """
        let quux = foo.bar.baaz.quux
        for item in (["foo", "bar", "baaz", quux]) {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop, exclude: [.redundantParens])
    }

    @Test func preservesForEachAfterMultilineChain() {
        let input = """
        placeholderStrings
            .filter { $0.style == .fooBar }
            .map { $0.uppercased() }
            .forEach { print($0) }

        placeholderStrings
            .filter({ $0.style == .fooBar })
            .map({ $0.uppercased() })
            .forEach({ print($0) })
        """
        testFormatting(for: input, rule: .preferForLoop, exclude: [.trailingClosures])
    }

    @Test func preservesChainWithClosure() {
        let input = """
        // Converting this to a for loop would result in unusual looking syntax like
        // `for string in strings.map { $0.uppercased() } { print($0) }`
        // which causes a warning to be emitted: "trailing closure in this context is
        // confusable with the body of the statement; pass as a parenthesized argument
        // to silence this warning".
        strings.map { $0.uppercased() }.forEach { print($0) }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    @Test func forLoopVariableNotUsedIfClashesWithKeyword() {
        let input = """
        Foo.allCases.forEach {
            print($0)
        }
        """
        let output = """
        for item in Foo.allCases {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func tryNotRemovedInThrowingForEach() {
        let input = """
        try list().forEach {
            print($0)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    @Test func optionalTryNotRemovedInThrowingForEach() {
        let input = """
        try? list().forEach {
            print($0)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    @Test func awaitNotRemovedInAsyncForEach() {
        let input = """
        await list().forEach {
            print($0)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    @Test func forEachOverDictionary() {
        let input = """
        let dict = ["a": "b"]

        dict.forEach { (header: (key: String, value: String)) in
            print(header.key)
            print(header.value)
        }
        """

        let output = """
        let dict = ["a": "b"]

        for header in dict {
            print(header.key)
            print(header.value)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    @Test func convertsForEachWithGuardElseReturn() {
        let input = """
        strings.forEach { string in
            guard !string.isEmpty else { return }
            print(string)
        }
        """

        let output = """
        for string in strings {
            guard !string.isEmpty else { continue }
            print(string)
        }
        """

        testFormatting(
            for: input, output, rule: .preferForLoop,
            exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
        )
    }
}
