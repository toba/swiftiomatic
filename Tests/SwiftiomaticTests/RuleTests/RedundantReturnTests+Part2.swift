import Testing
@testable import Swiftiomatic

extension RedundantReturnTests {
    @Test func redundantIfStatementReturnInClosure() {
        let input = """
        let closure: (Bool) -> String = { condition in
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }
        """
        let output = """
        let closure: (Bool) -> String = { condition in
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func noRemoveRedundantIfStatementReturnInClosure() {
        let input = """
        let closure: (Bool) -> String = { condition in
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, rule: .redundantReturn, options: options,
            exclude: [.conditionalAssignment],
        )
    }

    @Test func noRemoveReturnInConsecutiveIfStatements() {
        let input = """
        func foo() -> String? {
            if bar {
                return nil
            }
            if baz {
                return "baz"
            } else {
                return "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func redundantIfStatementReturnInRedundantClosure() {
        let input = """
        let value = {
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }()
        """
        let output = """
        let value = if condition {
            "foo"
        } else {
            "bar"
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [
                .redundantReturn, .conditionalAssignment,
                .redundantClosure, .indent,
            ],
            options: options, exclude: [.wrapMultilineConditionalAssignment],
        )
    }

    @Test func redundantSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            case false:
                return "bar"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                "foo"
            case false:
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func noRemoveRedundantSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            case false:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, rule: .redundantReturn, options: options,
            exclude: [.conditionalAssignment],
        )
    }

    @Test func nonRedundantSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            case false:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func redundantSwitchStatementReturnInFunctionWithDefault() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            default:
                return "bar"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                "foo"
            default:
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func redundantSwitchStatementReturnInFunctionWithComment() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                // foo
                return "foo"

            default:
                /* bar */
                return "bar"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                // foo
                "foo"

            default:
                /* bar */
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func nonRedundantSwitchStatementReturnInFunctionWithDefault() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            default:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func nonRedundantSwitchStatementReturnInFunctionWithFallthrough() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                fallthrough
            case false:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func voidReturnNotStrippedFromSwitch() {
        let input = """
        func foo(condition: Bool) {
            switch condition {
            case true:
                print("foo")
            case false:
                return
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func redundantNestedSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                switch condition {
                case true:
                    return "foo"
                case false:
                    if condition {
                        return "bar"
                    } else {
                        return "baaz"
                    }
                }

            case false:
                return "quux"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                switch condition {
                case true:
                    "foo"
                case false:
                    if condition {
                        "bar"
                    } else {
                        "baaz"
                    }
                }

            case false:
                "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func redundantSwitchStatementReturnWithAssociatedValueMatchingInFunction() {
        let input = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case let .first(str):
                return "first \\(str)"
            case .second("str"):
                return "second"
            default:
                return "default"
            }
        }
        """
        let output = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case let .first(str):
                "first \\(str)"
            case .second("str"):
                "second"
            default:
                "default"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func redundantReturnDoesNotFailToTerminateOnLongSwitch() {
        let input = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case .one:
                return ""
            case .two:
                return ""
            case .three:
                return ""
            case .four:
                return ""
            case .five:
                return ""
            case .six:
                return ""
            case .seven:
                return ""
            case .eight:
                return ""
            case .nine:
                return ""
            case .ten:
                return ""
            case .eleven:
                return ""
            case .twelve:
                return ""
            case .thirteen:
                return ""
            case .fourteen:
                return ""
            case .fifteen:
                return ""
            case .sixteen:
                return ""
            case .seventeen:
                return ""
            case .eighteen:
                return ""
            case .nineteen:
                return ""
            }
        }
        """
        let output = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case .one:
                ""
            case .two:
                ""
            case .three:
                ""
            case .four:
                ""
            case .five:
                ""
            case .six:
                ""
            case .seven:
                ""
            case .eight:
                ""
            case .nine:
                ""
            case .ten:
                ""
            case .eleven:
                ""
            case .twelve:
                ""
            case .thirteen:
                ""
            case .fourteen:
                ""
            case .fifteen:
                ""
            case .sixteen:
                ""
            case .seventeen:
                ""
            case .eighteen:
                ""
            case .nineteen:
                ""
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func noRemoveDebugReturnFollowedBySwitch() {
        let input = """
        func swiftFormatBug() -> Foo {
            return .foo

            switch state {
            case .foo, .bar:
                return state
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, rule: .redundantReturn, options: options,
            exclude: [.wrapSwitchCases, .sortSwitchCases],
        )
    }

    @Test func doesNotRemoveReturnFromIfExpressionConditionalCastInSwift5_9() {
        // The following code doesn't compile in Swift 5.9 due to this issue:
        // https://github.com/apple/swift/issues/68764
        //
        //  var result: String {
        //    if condition {
        //      foo as? String
        //    } else {
        //      "bar"
        //    }
        //  }
        //
        let input = """
        var result1: String {
            if condition {
                return foo as? String
            } else {
                return "bar"
            }
        }

        var result2: String {
            switch condition {
            case true:
                return foo as? String
            case false:
                return "bar"
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func removseReturnFromIfExpressionNestedConditionalCastInSwift5_9() {
        let input = """
        var result1: String {
            if condition {
                return method(foo as? String)
            } else {
                return "bar"
            }
        }
        """

        let output = """
        var result1: String {
            if condition {
                method(foo as? String)
            } else {
                "bar"
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func removesReturnFromIfExpressionConditionalCastInSwift5_10() {
        let input = """
        var result: String {
            if condition {
                return foo as? String
            } else {
                return "bar"
            }
        }
        """

        let output = """
        var result: String {
            if condition {
                foo as? String
            } else {
                "bar"
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func removesRedundantReturnBeforeIfExpression() {
        let input = """
        func foo() -> Foo {
            return if condition {
                Foo.foo()
            } else {
                Foo.bar()
            }
        }
        """

        let output = """
        func foo() -> Foo {
            if condition {
                Foo.foo()
            } else {
                Foo.bar()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    @Test func removesRedundantReturnBeforeSwitchExpression() {
        let input = """
        func foo() -> Foo {
            return switch condition {
            case true:
                Foo.foo()
            case false:
                Foo.bar()
            }
        }
        """

        let output = """
        func foo() -> Foo {
            switch condition {
            case true:
                Foo.foo()
            case false:
                Foo.bar()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    @Test func redundantSwitchStatementReturnInFunctionWithMultipleWhereClauses() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1554
        let input = """
        func foo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                return "foo"
            case .fooCase2 where count < 100,
                 .fooCase3 where count < 100,
                 .fooCase4:
                return "bar"
            default:
                return nil
            }
        }
        """
        let output = """
        func foo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                "foo"
            case .fooCase2 where count < 100,
                 .fooCase3 where count < 100,
                 .fooCase4:
                "bar"
            default:
                nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func redundantSwitchStatementReturnInFunctionWithSingleWhereClause() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1554
        let input = """
        func anotherFoo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                return "foo"
            case .fooCase2 where count < 100,
                 .fooCase4:
                return "bar"
            default:
                return nil
            }
        }
        """
        let output = """
        func anotherFoo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                "foo"
            case .fooCase2 where count < 100,
                 .fooCase4:
                "bar"
            default:
                nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func returnNotRemovedFromSwitchBodyWithOpaqueReturnType() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1819
        let input = """
        extension View {
            func foo() -> some View {
                if #available(iOS 16.0, *) {
                    return self.scrollIndicators(.hidden)
                } else {
                    return self
                }
            }

            func bar() -> (some View) {
                if #available(iOS 16.0, *) {
                    return self.scrollIndicators(.hidden)
                } else {
                    return self
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input,
            rules: [.redundantReturn, .conditionalAssignment],
            options: options, exclude: [.redundantSelf],
        )
    }

    @Test func returnNotRemovedFromCatchWhere() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1843
        let input = """
        func decodeError(from data: Data, urlResponse: HTTPURLResponse) -> Error {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch where urlResponse.statusCode >= 400 {
                return CustomError() // <- return removed here, introducing a compile time error.
            } catch {
                return error
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input,
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func forLoopReturnAfterSwitch() {
        let input = """
        func foo() -> Bool {
            switch bar {
            case .baz:
                break
            }

            for i in quux where quux[i].foo {
                return i > 0
            }

            return false
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    @Test func issue1974() {
        let input = """
        func selectedRow() -> Int? {
            var selectedItem: NSManagedObjectID?

            guard let selection = selectedFilterSourceBlock?() as? UserDataSourceSelection else {
                return nil
            }

            switch selection {
            case .user(let managedObjectID):
                selectedItem = managedObjectID
            case .noValue:
                return nil
            }

            if includeEveryone && selectedItem == nil {
                return 0
            }

            for (i, item) in _items.enumerated() where item.objectID == selectedItem {
                return i >= _limit ? _limit : i + (includeEveryone ? 1 : 0)
            }

            return nil
        }
        """
        testFormatting(
            for: input,
            rule: .redundantReturn,
            exclude: [.hoistPatternLet, .andOperator],
        )
    }

    @Test func issue2263() {
        let input = """
        func firstNonNilValue<O>() async -> O where V == O? {
            var it = values.makeAsyncIterator()
            repeat {
                if let value = await it.next(), let value {
                    return value
                }
            }
            while true
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input,
            rule: .redundantReturn,
            options: options,
            exclude: [.elseOnSameLine],
        )
    }
}
