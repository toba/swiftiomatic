import Testing

@testable import Swiftiomatic

// MARK: - AcronymsRule

@Suite(.rulesRegistered)
struct AcronymsRuleTests {
  @Test func noViolationForCorrectAcronyms() async {
    await assertNoViolation(AcronymsRule.self, "let destinationURL: URL")
  }

  @Test func detectsLowercasedAcronym() async {
    await assertViolates(AcronymsRule.self, "let destinationUrl: URL")
  }
}

// MARK: - EnumNamespacesRule

@Suite(.rulesRegistered)
struct EnumNamespacesRuleTests {
  @Test func noViolationForEnum() async {
    await assertNoViolation(EnumNamespacesRule.self, "enum Constants { static let foo = 1 }")
  }

  @Test func noViolationForStructWithInstance() async {
    await assertNoViolation(EnumNamespacesRule.self, "struct Foo { let bar: Int }")
  }

  @Test func detectsStructNamespace() async {
    await assertViolates(
      EnumNamespacesRule.self,
      """
      struct Constants {
          static let foo = "foo"
          static let bar = "bar"
      }
      """)
  }
}

// MARK: - NumberFormattingRule

@Suite(.rulesRegistered)
struct NumberFormattingRuleTests {
  @Test func noViolationForFormattedNumbers() async {
    await assertNoViolation(NumberFormattingRule.self, "let x = 1_000_000")
  }

  @Test func noViolationForSmallNumbers() async {
    await assertNoViolation(NumberFormattingRule.self, "let x = 100")
  }

  @Test func detectsUnformattedLargeNumber() async {
    await assertViolates(NumberFormattingRule.self, "let x = 1000000")
  }
}

// MARK: - SinglePropertyPerLineRule

@Suite(.rulesRegistered)
struct SinglePropertyPerLineRuleTests {
  @Test func noViolationForSingleProperty() async {
    await assertNoViolation(SinglePropertyPerLineRule.self, "let a: Int")
  }

  @Test func detectsMultiplePropertiesOnOneLine() async {
    await assertViolates(SinglePropertyPerLineRule.self, "let a, b, c: Int")
  }
}
