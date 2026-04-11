import Testing

@testable import Swiftiomatic

// MARK: - TypedThrowsRule

@Suite(.rulesRegistered)
struct TypedThrowsRuleTests {
    @Test func noViolationForTypedThrows() async {
        await assertNoViolation(TypedThrowsRule.self,
            "func parse() throws(ParseError) { throw ParseError.invalid }")
    }

    @Test func noViolationForMultipleErrorTypes() async {
        await assertNoViolation(TypedThrowsRule.self, """
            func work() throws {
                throw ErrorA.a
                throw ErrorB.b
            }
            """)
    }

    @Test func detectsUntypedThrows() async {
        await assertViolates(TypedThrowsRule.self,
            "func parse() throws { throw ParseError.invalid }")
    }
}

// MARK: - AnyEliminationRule

@Suite(.rulesRegistered)
struct AnyEliminationRuleTests {
    @Test func noViolationForSpecificTypes() async {
        await assertNoViolation(AnyEliminationRule.self, #"var name: String = """#)
    }

    @Test func detectsAnyType() async {
        await assertViolates(AnyEliminationRule.self, "var value: Any = 0")
    }

    @Test func detectsAnyDictionary() async {
        await assertViolates(AnyEliminationRule.self, "func process(_ dict: [String: Any]) {}")
    }
}

// MARK: - AnyObjectProtocolRule

@Suite(.rulesRegistered)
struct AnyObjectProtocolRuleTests {
    @Test func noViolationForAnyObject() async {
        await assertNoViolation(AnyObjectProtocolRule.self, "protocol Foo: AnyObject {}")
    }

    // `class` constraint syntax produces parser errors in Swift 6
}

// MARK: - GenericConsolidationRule

@Suite(.rulesRegistered)
struct GenericConsolidationRuleTests {
    @Test func noViolationForSomeType() async {
        await assertNoViolation(GenericConsolidationRule.self,
            "func process(_ items: some Sequence) { }")
    }

    // GenericConsolidation requires type usage analysis to suggest `some` over `any`
}
