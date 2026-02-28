import Testing
@testable import Swiftiomatic

@Suite struct WrapMultilineFunctionChainsTests {
    @Test func wrapIfExpressionAssignment() {
        let input = """
        let evenSquaresSum = [20, 17, 35, 4]
            .filter { $0 % 2 == 0 }.map { $0 * $0 }
            .reduce(0, +)
        """

        let output = """
        let evenSquaresSum = [20, 17, 35, 4]
            .filter { $0 % 2 == 0 }
            .map { $0 * $0 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapMultipleFunctionCalls() {
        let input = """
        let result = array
            .first?.map { $0 * 2 }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .first?
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapSingleFunctionCall() {
        let input = """
        let result = array.map { $0 * 2 }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapNestedFunctionCallsWithTrailingClosures() {
        let input = """
        let result = array
            .map { $0.filter { $1 > 10 } }.flatMap { $0 }
        """

        let output = """
        let result = array
            .map { $0.filter { $1 > 10 } }
            .flatMap { $0 }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapNestedFunctionCallsWithClosureParameters() {
        let input = """
        let result = array
            .map { $0.reduce(0, +) }.flatMap { $0 }
        """

        let output = """
        let result = array
            .map { $0.reduce(0, +) }
            .flatMap { $0 }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapFunctionCallsWithComments() {
        let input = """
        let result = array
            .map { $0 * 2 } // multiply by 2
            .filter { $0 > 10 } // filter greater than 10
            .reduce(0, +) // sum up
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapFunctionCallsWithPropertyAccess() {
        let input = """
        let result = array
            .first?.property.map { $0 * 2 }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .first?
            .property
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapFunctionCallsWithMultiplePropertyAccesses() {
        let input = """
        let result = array
            .first?.property.anotherProperty.map { $0 * 2 }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .first?
            .property
            .anotherProperty
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapFunctionCallsWithChainsOnEndOfClosures() {
        let input = """
        let result = array
            .map { item in
                item.property
            }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .map { item in
                item.property
            }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func wrapFunctionCallsWithChainsOnEndOfParameters() {
        let input = """
        let result = array
            .function(
                arg1: item.property,
                arg2: item.property
            ).reduce(0, +)
        """

        let output = """
        let result = array
            .function(
                arg1: item.property,
                arg2: item.property
            )
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func multilineOperatorStatementsNotWrapped() {
        let input = """
        formatter.currentIndentForLine(at: conditionBeginIndex)
            .count < indent.count + formatter.options.indent.count
        """

        testFormatting(for: input, rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func namespacedAccessNotWrapped() {
        let input = """
        Namespace.NestedNamespace.property
            .map { $0 * 2 }
        """

        testFormatting(for: input, rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func nestedNamespacedAccessNotWrapped() {
        let input = """
        Namespace.NestedNamespace.DeeplyNestedNamespace.property
            .function()
        """

        testFormatting(for: input, rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func multilineTypesNotWrapped() {
        let input = """
        func tableCellSelection(for selection: Selection?) -> Selection
            .TableSelection.CellSelection?
        {
            selection.tableCellSelection
        }
        """

        testFormatting(for: input, rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func singleFunctionChainNotWrapped() {
        let input = """
        let result = array.map { $0 * 2 }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func multipleFunctionChainsOnOneLineNotWrapped() {
        let input = """
        let result = array.map { $0 * 2 }.filter { $0 > 10 }.reduce(0, +)
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func functionChainWithOptionalChaining() {
        let input = """
        let result = array?
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func consecutiveDeclarations() {
        let input = """
        let sequence = [42].async
        let sequence = [43].async
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func consecutiveStatements() {
        let input = """
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func adjacentChainsChainsShouldNotWrap() {
        let input = """
        value.property.map { $0 * 2 }
        value.property.map { $0 * 2 }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func adjacentChainsInViewBuildersWithDifferentWraps() {
        let input = """
        Text("S")
            .padding(10)
        Color.blue.frame(maxWidth: 1, maxHeight: .infinity).fixedSize()
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func nonFunctionChains() {
        let input = """
        let adjusted: CGPoint = .init(
            x: rect.origin.x + insets.left,
            y: rect.origin.y + insets.top
        )
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func adjacentChainsInConditions() {
        let input = """
        let hexSanitized = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var hex: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&hex) else {
            return nil
        }
        """
        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func adjacentChainsInIfConditionWhereStatement() {
        let input = """
        let xcTestCaseInstanceMethods = Set(["expectation"])
            .union(options.additionalXCTestSymbols)

        for index in tokens.indices where tokens[index].isIdentifier {
            let identifier = tokens[index].string
        }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func trailingClosureNotWrapped() {
        let input = """
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.hideKeyboard.send()
        }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    @Test func parenthesisInSingleLineDoNoWrap() {
        let input = """
        MainActor.assumeIsolated {
            let value = try await someFunction()
        }

        (invoke() as Value).method()
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent], exclude: [.hoistTry])
    }
}
