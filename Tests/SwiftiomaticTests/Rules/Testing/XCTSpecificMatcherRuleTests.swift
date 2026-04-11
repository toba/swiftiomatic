import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct XCTSpecificMatcherRuleTests {
  @Test func equalTrue() async throws {
    let example = Example("XCTAssertEqual(a, true)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
  }

  @Test func equalFalse() async throws {
    let example = Example("XCTAssertEqual(a, false)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
  }

  @Test func equalNil() async throws {
    let example = Example("XCTAssertEqual(a, nil)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(allViolations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
  }

  @Test func notEqualTrue() async throws {
    let example = Example("XCTAssertNotEqual(a, true)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
  }

  @Test func notEqualFalse() async throws {
    let example = Example("XCTAssertNotEqual(a, false)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
  }

  @Test func notEqualNil() async throws {
    let example = Example("XCTAssertNotEqual(a, nil)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
  }

  // MARK: - Additional Tests

  @Test func equalOptionalFalse() async throws {
    let example = Example("XCTAssertEqual(a?.b, false)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.isEmpty)
  }

  @Test func equalUnwrappedOptionalFalse() async throws {
    let example = Example("XCTAssertEqual(a!.b, false)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
  }

  @Test func equalNilNil() async throws {
    let example = Example("XCTAssertEqual(nil, nil)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(allViolations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
  }

  @Test func equalTrueTrue() async throws {
    let example = Example("XCTAssertEqual(true, true)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
  }

  @Test func equalFalseFalse() async throws {
    let example = Example("XCTAssertEqual(false, false)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
  }

  @Test func notEqualNilNil() async throws {
    let example = Example("XCTAssertNotEqual(nil, nil)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
  }

  @Test func notEqualTrueTrue() async throws {
    let example = Example("XCTAssertNotEqual(true, true)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
  }

  @Test func notEqualFalseFalse() async throws {
    let example = Example("XCTAssertNotEqual(false, false)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
  }

  @Test func assertEqual() async throws {
    let example = Example("XCTAssert(foo == bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
  }

  @Test func assertFalseNotEqual() async throws {
    let example = Example("XCTAssertFalse(bar != foo)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
  }

  @Test func assertTrueEqual() async throws {
    let example = Example("XCTAssertTrue(foo == 1)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
  }

  @Test func assertNotEqual() async throws {
    let example = Example("XCTAssert(foo != bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead",
    )
  }

  @Test func assertFalseEqual() async throws {
    let example = Example("XCTAssertFalse(bar == foo)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead",
    )
  }

  @Test func assertTrueNotEqual() async throws {
    let example = Example("XCTAssertTrue(foo != 1)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead",
    )
  }

  @Test func multipleComparisons() async throws {
    let example = Example("XCTAssert(foo == (bar == baz))")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
  }

  @Test func equalInCommentNotConsidered() async throws {
    #expect(
      try await ruleViolations(
        Example("XCTAssert(foo, \"a == b\")"), rule: XCTSpecificMatcherRule.identifier
      ).isEmpty)
  }

  @Test func equalInFunctionCall() async throws {
    #expect(
      try await ruleViolations(
        Example("XCTAssert(foo(bar == baz))"), rule: XCTSpecificMatcherRule.identifier
      ).isEmpty)
    #expect(
      try await ruleViolations(
        Example("XCTAssertTrue(foo(bar == baz), \"toto\")"), rule: XCTSpecificMatcherRule.identifier
      ).isEmpty)
  }

  // MARK: - Identity Operator Tests

  @Test func assertIdentical() async throws {
    let example = Example("XCTAssert(foo === bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertIdentical' instead",
    )
  }

  @Test func assertNotIdentical() async throws {
    let example = Example("XCTAssert(foo !== bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead",
    )
  }

  @Test func assertTrueIdentical() async throws {
    let example = Example("XCTAssertTrue(foo === bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertIdentical' instead",
    )
  }

  @Test func assertTrueNotIdentical() async throws {
    let example = Example("XCTAssertTrue(foo !== bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead",
    )
  }

  @Test func assertFalseIdentical() async throws {
    let example = Example("XCTAssertFalse(foo === bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead",
    )
  }

  @Test func assertFalseNotIdentical() async throws {
    let example = Example("XCTAssertFalse(foo !== bar)")
    let allViolations = try await ruleViolations(example, rule: XCTSpecificMatcherRule.identifier)

    #expect(allViolations.count == 1)
    #expect(
      allViolations.first?
        .reason == "Prefer the specific matcher 'XCTAssertIdentical' instead",
    )
  }
}
