import Testing

@testable import Swiftiomatic

// MARK: - AndOperatorRule

@Suite(.rulesRegistered)
struct AndOperatorRuleTests {
    @Test func noViolationForCommaConditions() async {
        await assertNoViolation(AndOperatorRule.self, "if a, b {}")
    }

    @Test func noViolationForOrOperator() async {
        await assertNoViolation(AndOperatorRule.self, "if a || b {}")
    }

    @Test func noViolationForAssignment() async {
        await assertNoViolation(AndOperatorRule.self, "let x = a && b")
    }

    // AndOperator is a .suggest rule — detection depends on context analysis
}

// MARK: - ConditionalAssignmentRule

@Suite(.rulesRegistered)
struct ConditionalAssignmentRuleTests {
    @Test func noViolationForIfExpression() async {
        await assertNoViolation(ConditionalAssignmentRule.self,
            "let x = if condition { 1 } else { 2 }")
    }

    // ConditionalAssignment requires specific binding/assignment pattern analysis
}

// MARK: - StrongifiedSelfRule

@Suite(.rulesRegistered)
struct StrongifiedSelfRuleTests {
    @Test func noViolationForShorthandSelf() async {
        await assertNoViolation(StrongifiedSelfRule.self, "guard let self else { return }")
    }

    // StrongifiedSelf requires closure context to trigger
}

// MARK: - HoistAwaitRule

@Suite(.rulesRegistered)
struct HoistAwaitRuleTests {
    @Test func noViolationForOuterAwait() async {
        await assertNoViolation(HoistAwaitRule.self, "let result = await foo(bar)")
    }

    @Test func detectsInnerAwait() async {
        await assertViolates(HoistAwaitRule.self, "let result = foo(await bar())")
    }
}

// MARK: - HoistTryRule

@Suite(.rulesRegistered)
struct HoistTryRuleTests {
    @Test func noViolationForOuterTry() async {
        await assertNoViolation(HoistTryRule.self, "let result = try foo(bar)")
    }

    @Test func detectsInnerTry() async {
        await assertViolates(HoistTryRule.self, "let result = foo(try bar())")
    }
}

// MARK: - PreferForLoopRule

@Suite(.rulesRegistered)
struct PreferForLoopRuleTests {
    @Test func noViolationForForLoop() async {
        await assertNoViolation(PreferForLoopRule.self, """
            for item in items {
                process(item)
            }
            """)
    }

    @Test func detectsForEach() async {
        await assertViolates(PreferForLoopRule.self, """
            items.forEach { item in
                process(item)
            }
            """)
    }
}
