import Testing
@testable import Swiftiomatic

extension RedundantClosureTests {
    @Test func redundantClosureDoesNotLeaveInvalidSwitchExpressionInOperatorChain() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes: Int {
                {
                    switch self {
                    case .uint8: UInt8.bitWidth
                    case .uint16: UInt16.bitWidth
                    }
                }() / 8
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func redundantClosureDoesNotLeaveInvalidIfExpressionInOperatorChain() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes: Int {
                {
                    if self == .uint8 {
                        UInt8.bitWidth
                    } else {
                        UInt16.bitWidth
                    }
                }() / 8
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func redundantClosureDoesNotLeaveInvalidIfExpressionInOperatorChain2() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes: Int {
                8 / {
                    if self == .uint8 {
                        UInt8.bitWidth
                    } else {
                        UInt16.bitWidth
                    }
                }()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func redundantClosureDoesNotLeaveInvalidIfExpressionInOperatorChain3() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes = 8 / {
                if self == .uint8 {
                    UInt8.bitWidth
                } else {
                    UInt16.bitWidth
                }
            }()
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func redundantClosureDoesRemoveRedundantIfStatementClosureInAssignmentPosition() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes = {
                if self == .uint8 {
                    UInt8.bitWidth
                } else {
                    UInt16.bitWidth
                }
            }()
        }
        """

        let output = """
        private enum Format {
            case uint8
            case uint16

            var bytes = if self == .uint8 {
                    UInt8.bitWidth
                } else {
                    UInt16.bitWidth
                }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.indent, .wrapMultilineConditionalAssignment],
        )
    }

    @Test func redundantClosureDoesNotLeaveInvalidSwitchExpressionInArray() {
        let input = """
        private func constraint() -> [Int] {
            [
                1,
                2,
                {
                    if Bool.random() {
                        3
                    } else {
                        4
                    }
                }(),
            ]
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func redundantClosureRemovesClosureAsReturnTryStatement() {
        let input = """
        func method() -> Int {
            return {
              return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.indent],
        )
    }

    @Test func redundantClosureRemovesClosureAsReturnTryStatement2() {
        let input = """
        func method() throws -> Int {
            return try {
              return try if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
            }()
        }
        """

        let output = """
        func method() throws -> Int {
            return try if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.indent],
        )
    }

    @Test func redundantClosureRemovesClosureAsReturnTryStatement3() {
        let input = """
        func method() async throws -> Int {
            return try await {
              return try await if Bool.random() {
                  randomAsyncThrows()
              } else {
                  randomAsyncThrows()
              }
            }()
        }
        """

        let output = """
        func method() async throws -> Int {
            return try await if Bool.random() {
                  randomAsyncThrows()
              } else {
                  randomAsyncThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.indent],
        )
    }

    @Test func redundantClosureRemovesClosureAsReturnTryStatement4() {
        let input = """
        func method() -> Int {
            return {
              return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.indent],
        )
    }

    @Test func redundantClosureRemovesClosureAsReturnStatement() {
        let input = """
        func method() -> Int {
            return {
              return if Bool.random() {
                  42
              } else {
                  43
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            return if Bool.random() {
                  42
              } else {
                  43
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output], rules: [.redundantClosure],
            options: options, exclude: [.indent],
        )
    }

    @Test func redundantClosureRemovesClosureAsImplicitReturnStatement() {
        let input = """
        func method() -> Int {
            {
              if Bool.random() {
                  42
              } else {
                  43
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            if Bool.random() {
                  42
              } else {
                  43
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options, exclude: [.indent],
        )
    }

    @Test func closureNotRemovedAroundIfExpressionInGuard() {
        let input = """
        guard let foo = {
            if condition {
                bar()
            }
        }() else {
            return
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func closureNotRemovedInMethodCall() {
        let input = """
        XCTAssert({
            if foo {
                bar
            } else {
                baaz
            }
        }())
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func closureNotRemovedInMethodCall2() {
        let input = """
        method("foo", {
            if foo {
                bar
            } else {
                baaz
            }
        }())
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func closureNotRemovedInMethodCall3() {
        let input = """
        XCTAssert({
            if foo {
                bar
            } else {
                baaz
            }
        }(), "message")
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func closureNotRemovedInMethodCall4() {
        let input = """
        method(
            "foo",
            {
                if foo {
                    bar
                } else {
                    baaz
                }
            }(),
            "bar"
        )
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func doesNotRemoveClosureWithIfExpressionConditionalCastInSwift5_9() {
        // The following code doesn't compile in Swift 5.9 due to this issue:
        // https://github.com/apple/swift/issues/68764
        //
        //  let result = if condition {
        //    foo as? String
        //  } else {
        //    "bar"
        //  }
        //
        let input = """
        let result1: String? = {
            if condition {
                return foo as? String
            } else {
                return "bar"
            }
        }()

        let result1: String? = {
            switch condition {
            case true:
                return foo as! String
            case false:
                return "bar"
            }
        }()
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    @Test func doesRemoveClosureWithIfExpressionConditionalCastInSwift5_10() {
        let input = """
        let result1: String? = {
            if condition {
                foo as? String
            } else {
                "bar"
            }
        }()

        let result2: String? = {
            switch condition {
            case true:
                foo as? String
            case false:
                "bar"
            }
        }()
        """

        let output = """
        let result1: String? = if condition {
                foo as? String
            } else {
                "bar"
            }

        let result2: String? = switch condition {
            case true:
                foo as? String
            case false:
                "bar"
            }
        """

        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.indent, .wrapMultilineConditionalAssignment],
        )
    }

    @Test func redundantClosureDoesNotBreakBuildWithRedundantReturnRuleDisabled() {
        let input = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = {
            return 0
        }()
        """

        let output = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = 0
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, output, rule: .redundantClosure, options: options,
            exclude: [.blankLinesBetweenScopes, .propertyTypes],
        )
    }

    @Test func redundantClosureWithSwitchExpressionDoesNotBreakBuildWithRedundantReturnRuleDisabled(
    ) {
        // From https://github.com/nicklockwood/SwiftFormat/issues/1565
        let input = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = {
            switch myEnum {
            case .a:
                return 0
            case .b:
                return 1
            }
        }()
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input,
            rules: [
                .conditionalAssignment,
                .redundantClosure,
            ],
            options: options,
            exclude: [
                .indent, .blankLinesBetweenScopes, .wrapMultilineConditionalAssignment,
                .propertyTypes,
            ],
        )
    }

    @Test func removesRedundantClosureWithGenericExistentialTypes() {
        let input = """
        let foo: Foo<Bar> = { DefaultFoo<Bar>() }()
        let foo: any Foo = { DefaultFoo() }()
        let foo: any Foo<Bar> = { DefaultFoo<Bar>() }()
        """

        let output = """
        let foo: Foo<Bar> = DefaultFoo<Bar>()
        let foo: any Foo = DefaultFoo()
        let foo: any Foo<Bar> = DefaultFoo<Bar>()
        """

        testFormatting(for: input, output, rule: .redundantClosure)
    }
}
