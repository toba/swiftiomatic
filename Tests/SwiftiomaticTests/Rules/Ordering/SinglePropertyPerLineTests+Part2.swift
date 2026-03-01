import Testing
@testable import Swiftiomatic

extension SinglePropertyPerLineTests {
    @Test func sharedComplexTypeAnnotation() {
        let input = """
        let first, second, third: [String: Int]
        """
        let output = """
        let first: [String: Int]
        let second: [String: Int]
        let third: [String: Int]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func mixedDeclarationsWithAndWithoutTypes() {
        let input = """
        let a = 5, b: Int, c = 10
        """
        let output = """
        let a = 5
        let b: Int
        let c = 10
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func guardWithMultipleConditions() {
        let input = """
        guard let user = user,
              user.isActive,
              let token = user.token else {
            return
        }
        """
        let output = """
        guard let user = user,
              user.isActive,
              let token = user.token
        else {
            return
        }
        """
        testFormatting(
            for: input, [output],
            rules: [.singlePropertyPerLine, .elseOnSameLine, .wrapMultilineStatementBraces],
        )
    }

    @Test func ifWithMultipleConditions() {
        let input = """
        if let data = data,
           let result = process(data),
           result.isValid {
            handle(result)
        }
        """
        let output = """
        if let data = data,
           let result = process(data),
           result.isValid
        {
            handle(result)
        }
        """
        testFormatting(
            for: input, [output], rules: [.singlePropertyPerLine, .wrapMultilineStatementBraces],
        )
    }

    @Test func whileWithMultipleConditions() {
        let input = """
        while let item = iterator.next(),
              item.isValid {
            process(item)
        }
        """
        let output = """
        while let item = iterator.next(),
              item.isValid
        {
            process(item)
        }
        """
        testFormatting(
            for: input, [output], rules: [.singlePropertyPerLine, .wrapMultilineStatementBraces],
        )
    }

    @Test func switchCaseWithMultipleBindings() {
        let input = """
        switch value {
        case let (a, b, c):
            return
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func sharedTypeAnnotationDuplication() {
        let input = """
        let itemPosition, itemSize, viewportSize, minContentOffset, maxContentOffset: CGFloat
        """
        let output = """
        let itemPosition: CGFloat
        let itemSize: CGFloat
        let viewportSize: CGFloat
        let minContentOffset: CGFloat
        let maxContentOffset: CGFloat
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func switchCaseWithOptionalBindings() {
        let input = """
        switch value {
        case (let leading?, nil, nil):
            return
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func switchCaseWithMultipleConditions() {
        let input = """
        let fromFrame, toFrame: CGRect
        switch (containerType, destinationContentMode) {
        case (.source, _), (_, .fill):
            break
        }
        """
        let output = """
        let fromFrame: CGRect
        let toFrame: CGRect
        switch (containerType, destinationContentMode) {
        case (.source, _), (_, .fill):
            break
        }
        """
        testFormatting(
            for: input, output, rule: .singlePropertyPerLine,
            exclude: [.sortSwitchCases, .wrapSwitchCases],
        )
    }

    // TODO: Fix tuple parsing - parseExpressionRange doesn't handle tuples correctly
    // @Test func simpleTupleValues() {
    //     let input = "let a = (1, 2), b = (3, 4)"
    //     let output = """
    //     let a = (1, 2)
    //     let b = (3, 4)
    //     """
    //     testFormatting(for: input, output, rule: .singlePropertyPerLine)
    // }

    @Test func basicCommaDetection() {
        // Test if parseExpressionRange is working correctly for simple cases
        let input = """
        let x = 5, y = 10
        """
        let output = """
        let x = 5
        let y = 10
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func simpleSharedType() {
        let input = """
        let a, b: Int
        """
        let output = """
        let a: Int
        let b: Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func enumDeclarationWithConformances() {
        let input = """
        enum DiagnosticFailure: Error, CustomStringConvertible { }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.emptyBraces])
    }

    @Test func ifLetWithTupleDestructuring() {
        let input = """
        if let (cacheKey, cachedHeight) = cachedHeight, cacheKey == newCacheKey {
            return cachedHeight
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func guardCaseWithBinding() {
        let input = """
        guard case .link(let url, _) = tappableContent else {
            return
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet])
    }

    @Test func ifLetWithMultipleConditions() {
        let input = """
        if let (cacheKey, cachedHeight) = cachedHeight, cacheKey == newCacheKey {
            return cachedHeight
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func classDeclarationWithMultipleInheritance() {
        let input = """
        public final class PrimaryButton: BaseMarginView, ConstellationView, PrimaryActionLoggable { }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.emptyBraces])
    }

    @Test func switchCaseWithMultipleLetBindings() {
        let input = """
        switch value {
        case .remote(url: let url, placeholder: let placeholder, aspectRatio: let aspectRatio):
            break
        }
        """
        testFormatting(
            for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet, .wrapSwitchCases],
        )
    }

    @Test func switchCaseWithMixedPatterns() {
        let input = """
        switch content {
        case .link(let title, _, _), .text(let title, _):
            return title
        }
        """
        testFormatting(
            for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet, .wrapSwitchCases],
        )
    }

    @Test func casePatternWithParentheses() {
        let input = """
        switch value {
        case .remote(let url, placeholder):
            break
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet])
    }

    @Test func enumWithProtocolConformanceListFollowingProperty() {
        let input = """
        public let foo = "bar"

        enum MyEnum: Error, CustomStringConvertible {
            case foo
            case bar
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func simpleTupleDestructuring() {
        let input = """
        let (foo, bar, baaz) = (1, 2, 3)
        """
        let output = """
        let foo = 1
        let bar = 2
        let baaz = 3
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithVarKeyword() {
        let input = """
        var (x, y, z) = (10, 20, 30)
        """
        let output = """
        var x = 10
        var y = 20
        var z = 30
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithSpaces() {
        let input = """
        let ( a , b , c ) = ( 1 , 2 , 3 )
        """
        let output = """
        let a = 1
        let b = 2
        let c = 3
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithComplexValues() {
        let input = """
        let (name, age, active) = (\"John\", 25, true)
        """
        let output = """
        let name = "John"
        let age = 25
        let active = true
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithModifiers() {
        let input = """
        private let (width, height) = (100.0, 200.0)
        """
        let output = """
        private let width = 100.0
        private let height = 200.0
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithAttributes() {
        let input = """
        @available(iOS 15, *) let (feature1, feature2) = (true, false)
        """
        let output = """
        @available(iOS 15, *) let feature1 = true
        @available(iOS 15, *) let feature2 = false
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithNestedValues() {
        let input = """
        let (array, dict) = ([1, 2, 3], [\"key\": \"value\"])
        """
        let output = """
        let array = [1, 2, 3]
        let dict = ["key": "value"]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithFunctionCalls() {
        let input = """
        let (min, max) = (calculateMin(), calculateMax())
        """
        let output = """
        let min = calculateMin()
        let max = calculateMax()
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringInsideFunction() {
        let input = """
        func process() {
            let (result, error) = (try? getData(), nil)
        }
        """
        let output = """
        func process() {
            let result = try? getData()
            let error = nil
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithSingleValue() {
        let input = """
        let (result) = (42)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.redundantParens])
    }

    @Test func preserveTupleDestructuringWithNonTupleRHS() {
        let input = """
        let (foo, bar, baz) = someFunction()
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithMethodCall() {
        let input = """
        let (x, y) = point.coordinates()
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithPropertyAccess2() {
        let input = """
        let (width, height) = view.size
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithIndentation() {
        let input = """
        class Example {
            func test() {
                let (a, b, c) = (1, 2, 3)
            }
        }
        """
        let output = """
        class Example {
            func test() {
                let a = 1
                let b = 2
                let c = 3
            }
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithSwitchTuple() {
        let input = """
        switch value {
        case let (x, y, z):
            break
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithTypeAnnotation() {
        let input = """
        let (a, b): (Int, Bool)
        """
        let output = """
        let a: Int
        let b: Bool
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithTypeAnnotationAndValues() {
        let input = """
        let (c, d): (String, Bool) = ("hello", false)
        """
        let output = """
        let c: String = \"hello\"
        let d: Bool = false
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithComplexTypes() {
        let input = """
        let (items, count): ([String], Int)
        """
        let output = """
        let items: [String]
        let count: Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithOptionalTypes() {
        let input = """
        var (name, age): (String?, Int?)
        """
        let output = """
        var name: String?
        var age: Int?
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithModifiersAndTypeAnnotation() {
        let input = """
        private let (width, height): (Double, Double)
        """
        let output = """
        private let width: Double
        private let height: Double
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithAttributesAndTypeAnnotation() {
        let input = """
        @available(iOS 15, *) let (x, y): (CGFloat, CGFloat)
        """
        let output = """
        @available(iOS 15, *) let x: CGFloat
        @available(iOS 15, *) let y: CGFloat
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithFunctionTypes() {
        let input = """
        let (handler, validator): ((String) -> Void, (Int) -> Bool)
        """
        let output = """
        let handler: (String) -> Void
        let validator: (Int) -> Bool
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithNestedTupleTypes() {
        let input = """
        let (point, size): ((Int, Int), (Int, Int))
        """
        let output = """
        let point: (Int, Int)
        let size: (Int, Int)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func tupleDestructuringWithTypeAnnotationAndPartialValues() {
        let input = """
        let (result, error): (String?, Error?) = (getValue(), nil)
        """
        let output = """
        let result: String? = getValue()
        let error: Error? = nil
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithConditionalExpression() {
        let input = """
        let (foo, bar) =
            if baaz {
                (true, false)
            } else {
                (false, true)
            }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithFunctionCall() {
        let input = """
        let (result, _): DecodedResponseWithContextCompletionArgument<Response> = castQueryResponse(from: query)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithClosureLiteral() {
        let input = """
        let (_, observers): (Value?, Observers<Value>) = storage.mutate { storage in (nil, storage.observers) }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithPropertyAccess() {
        let input = """
        let (width, height) = view.bounds.size
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func preserveTupleDestructuringWithComplexExpression() {
        let input = """
        let (min, max) = array.isEmpty ? (0, 0) : (array.min()!, array.max()!)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    @Test func asyncLetPreserved() {
        let input = """
        async let (one, two) = (performOne(), performTwo())
        let (oneResult, twoResult) = await (one, two)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }
}
