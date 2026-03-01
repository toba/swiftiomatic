import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct XCTSpecificMatcherRuleTests {
    @Test func equalTrue() async {
        let example = Example("XCTAssertEqual(a, true)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test func equalFalse() async {
        let example = Example("XCTAssertEqual(a, false)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test func equalNil() async {
        let example = Example("XCTAssertEqual(a, nil)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    @Test func notEqualTrue() async {
        let example = Example("XCTAssertNotEqual(a, true)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test func notEqualFalse() async {
        let example = Example("XCTAssertNotEqual(a, false)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test func notEqualNil() async {
        let example = Example("XCTAssertNotEqual(a, nil)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    // MARK: - Additional Tests

    @Test func equalOptionalFalse() async {
        let example = Example("XCTAssertEqual(a?.b, false)")
        let allViolations = await violations(example)

        #expect(allViolations.isEmpty)
    }

    @Test func equalUnwrappedOptionalFalse() async {
        let example = Example("XCTAssertEqual(a!.b, false)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test func equalNilNil() async {
        let example = Example("XCTAssertEqual(nil, nil)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    @Test func equalTrueTrue() async {
        let example = Example("XCTAssertEqual(true, true)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test func equalFalseFalse() async {
        let example = Example("XCTAssertEqual(false, false)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test func notEqualNilNil() async {
        let example = Example("XCTAssertNotEqual(nil, nil)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    @Test func notEqualTrueTrue() async {
        let example = Example("XCTAssertNotEqual(true, true)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test func notEqualFalseFalse() async {
        let example = Example("XCTAssertNotEqual(false, false)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test func assertEqual() async {
        let example = Example("XCTAssert(foo == bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test func assertFalseNotEqual() async {
        let example = Example("XCTAssertFalse(bar != foo)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test func assertTrueEqual() async {
        let example = Example("XCTAssertTrue(foo == 1)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test func assertNotEqual() async {
        let example = Example("XCTAssert(foo != bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead",
        )
    }

    @Test func assertFalseEqual() async {
        let example = Example("XCTAssertFalse(bar == foo)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead",
        )
    }

    @Test func assertTrueNotEqual() async {
        let example = Example("XCTAssertTrue(foo != 1)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead",
        )
    }

    @Test func multipleComparisons() async {
        let example = Example("XCTAssert(foo == (bar == baz))")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(allViolations.first?
            .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test func equalInCommentNotConsidered() async {
        #expect(await noViolation(in: "XCTAssert(foo, \"a == b\")"))
    }

    @Test func equalInFunctionCall() async {
        #expect(await noViolation(in: "XCTAssert(foo(bar == baz))"))
        #expect(await noViolation(in: "XCTAssertTrue(foo(bar == baz), \"toto\")"))
    }

    // MARK: - Identity Operator Tests

    @Test func assertIdentical() async {
        let example = Example("XCTAssert(foo === bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertIdentical' instead",
        )
    }

    @Test func assertNotIdentical() async {
        let example = Example("XCTAssert(foo !== bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead",
        )
    }

    @Test func assertTrueIdentical() async {
        let example = Example("XCTAssertTrue(foo === bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertIdentical' instead",
        )
    }

    @Test func assertTrueNotIdentical() async {
        let example = Example("XCTAssertTrue(foo !== bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead",
        )
    }

    @Test func assertFalseIdentical() async {
        let example = Example("XCTAssertFalse(foo === bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead",
        )
    }

    @Test func assertFalseNotIdentical() async {
        let example = Example("XCTAssertFalse(foo !== bar)")
        let allViolations = await violations(example)

        #expect(allViolations.count == 1)
        #expect(
            allViolations.first?
                .reason == "Prefer the specific matcher 'XCTAssertIdentical' instead",
        )
    }

    private func violations(_ example: Example) async -> [RuleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.identifier) else { return [] }
        return await SwiftiomaticTests.violations(example, config: config)
    }

    private func noViolation(in example: String) async -> Bool {
        await violations(Example(example)).isEmpty
    }
}
