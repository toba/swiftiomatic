import Testing

@testable import Swiftiomatic

// MARK: - RedundantClosureRule

@Suite(.rulesRegistered)
struct RedundantClosureRuleTests {
    @Test func noViolationForClosureWithParams() async {
        await assertNoViolation(RedundantClosureRule.self, "let x = { (a: Int) in a + 1 }(5)")
    }

    @Test func detectsRedundantClosure() async {
        await assertViolates(RedundantClosureRule.self, "let x: Int = { return 42 }()")
    }
}

// MARK: - RedundantParensRule

@Suite(.rulesRegistered)
struct RedundantParensRuleTests {
    @Test func noViolationForNecessaryParens() async {
        await assertNoViolation(RedundantParensRule.self, "if foo == true {}")
    }

    @Test func noViolationForTuple() async {
        await assertNoViolation(RedundantParensRule.self, "let x = (a, b)")
    }

    @Test func detectsRedundantParensInIf() async {
        await assertViolates(RedundantParensRule.self, "if (foo == true) {}")
    }

    @Test func detectsRedundantParensInWhile() async {
        await assertViolates(RedundantParensRule.self, "while (flag) {}")
    }

    @Test func correctsRedundantParens() async {
        await assertFormatting(RedundantParensRule.self,
            input: "if (foo == true) {}",
            expected: "if foo == true {}")
    }
}

// MARK: - RedundantBackticksRule

@Suite(.rulesRegistered)
struct RedundantBackticksRuleTests {
    // RedundantBackticksRule is aggressive — most backtick uses are flagged.
    // See the rule's nonTriggeringExamples for valid cases.

    @Test func detectsRedundantBackticks() async {
        await assertViolates(RedundantBackticksRule.self, "let `foo` = bar")
    }

    @Test func correctsRedundantBackticks() async {
        await assertFormatting(RedundantBackticksRule.self,
            input: "let `foo` = bar",
            expected: "let foo = bar")
    }
}

// MARK: - RedundantStaticSelfRule

@Suite(.rulesRegistered)
struct RedundantStaticSelfRuleTests {
    @Test func detectsRedundantStaticSelf() async {
        await assertViolates(RedundantStaticSelfRule.self, """
            struct Foo {
                static let bar = "bar"
                static func baz() -> String {
                    return Self.bar
                }
            }
            """)
    }
}

// MARK: - RedundantViewBuilderRule

@Suite(.rulesRegistered)
struct RedundantViewBuilderRuleTests {
    @Test func detectsRedundantViewBuilder() async {
        await assertViolates(RedundantViewBuilderRule.self, """
            import SwiftUI
            struct MyView: View {
                @ViewBuilder
                var body: some View {
                    Text("Hello")
                }
            }
            """)
    }
}

// MARK: - RedundantPropertyRule

@Suite(.rulesRegistered)
struct RedundantPropertyRuleTests {
    @Test func noViolationForDirectReturn() async {
        await assertNoViolation(RedundantPropertyRule.self, """
            func foo() -> Int {
                return 42
            }
            """)
    }

    @Test func detectsRedundantProperty() async {
        await assertViolates(RedundantPropertyRule.self, """
            func foo() -> Int {
                let result = 42
                return result
            }
            """)
    }
}

// MARK: - EmptyBracesRule

@Suite(.rulesRegistered)
struct EmptyBracesRuleTests {
    @Test func noViolationForEmptyBraces() async {
        await assertNoViolation(EmptyBracesRule.self, "func foo() {}")
    }

    @Test func detectsSpaceInEmptyBraces() async {
        await assertViolates(EmptyBracesRule.self, "func foo() { }")
    }

    @Test func correctsSpaceInEmptyBraces() async {
        await assertFormatting(EmptyBracesRule.self,
            input: "func foo() { }",
            expected: "func foo() {}")
    }
}

// MARK: - RedundantGetRule

@Suite(.rulesRegistered)
struct RedundantGetRuleTests {
    @Test func noViolationForComputedPropertyWithoutGet() async {
        await assertNoViolation(RedundantGetRule.self, """
            var foo: Int {
                return 5
            }
            """)
    }

    @Test func noViolationForGetterWithSetter() async {
        await assertNoViolation(RedundantGetRule.self, """
            var foo: Int {
                get { return 5 }
                set { _foo = newValue }
            }
            """)
    }

    @Test func noViolationForAsyncThrowingGetter() async {
        await assertNoViolation(RedundantGetRule.self, """
            var foo: Int {
                get async throws {
                    try await getFoo()
                }
            }
            """)
    }

    @Test func detectsRedundantGet() async {
        await assertViolates(RedundantGetRule.self, """
            var foo: Int {
                get {
                    return 5
                }
            }
            """)
    }

    @Test func detectsRedundantGetInline() async {
        await assertViolates(RedundantGetRule.self, "var foo: Int { get { return 5 } }")
    }

    @Test func detectsRedundantGetInSubscript() async {
        await assertViolates(RedundantGetRule.self, """
            subscript(_ index: Int) {
                get {
                    return lookup(index)
                }
            }
            """)
    }
}

// MARK: - EmptyExtensionsRule

@Suite(.rulesRegistered)
struct EmptyExtensionsRuleTests {
    @Test func noViolationForConformanceExtension() async {
        await assertNoViolation(EmptyExtensionsRule.self, "extension String: Equatable {}")
    }

    @Test func detectsEmptyExtension() async {
        await assertViolates(EmptyExtensionsRule.self, "extension String {}")
    }
}

// MARK: - RedundantEquatableRule

@Suite(.rulesRegistered)
struct RedundantEquatableRuleTests {
    @Test func detectsRedundantEquatable() async {
        await assertViolates(RedundantEquatableRule.self, """
            struct Foo: Equatable {
                let bar: Int
                let baz: String
                static func == (lhs: Foo, rhs: Foo) -> Bool {
                    lhs.bar == rhs.bar && lhs.baz == rhs.baz
                }
            }
            """)
    }
}

// MARK: - RedundantMemberwiseInitRule

@Suite(.rulesRegistered)
struct RedundantMemberwiseInitRuleTests {
    @Test func noViolationForCustomInit() async {
        await assertNoViolation(RedundantMemberwiseInitRule.self, """
            struct Foo {
                let bar: Int
                init(bar: Int) {
                    self.bar = bar + 1
                }
            }
            """)
    }
}

// MARK: - CaseIterableUsageRule

@Suite(.rulesRegistered)
struct CaseIterableUsageRuleTests {
    @Test func noViolationWhenAllCasesUsed() async {
        await assertNoViolation(CaseIterableUsageRule.self, """
            enum Direction: CaseIterable { case north, south }
            let all = Direction.allCases
            """)
    }
}
