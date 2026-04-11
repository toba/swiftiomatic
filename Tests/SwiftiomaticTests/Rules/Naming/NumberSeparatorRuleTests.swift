import SwiftParser
import SwiftSyntax
import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct NumberSeparatorRuleTests {
  // MARK: - Minimum length

  @Test func separatedFourDigitsDoesNotViolateWithMinLength5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 10_000",
      configuration: ["minimum_length": 5])
  }

  @Test func unseparatedFourDigitsDoesNotViolateWithMinLength5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1000",
      configuration: ["minimum_length": 5])
  }

  @Test func unseparatedFractionDoesNotViolateWithMinLength5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1000.0001",
      configuration: ["minimum_length": 5])
  }

  @Test func separatedIntegerWithUnseparatedFractionDoesNotViolateWithMinLength5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 10_000.0001",
      configuration: ["minimum_length": 5])
  }

  @Test func fiveDigitFractionDoesNotViolateWithMinLength5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1000.00001",
      configuration: ["minimum_length": 5])
  }

  @Test func wrongSeparatorPositionViolatesWithMinLength5() async {
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1_000",
      expected: "let foo = 1000",
      findings: [FindingSpec("1️⃣")],
      configuration: ["minimum_length": 5])
  }

  @Test func wrongFractionSeparatorViolatesWithMinLength5() async {
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1.000_1",
      expected: "let foo = 1.0001",
      findings: [FindingSpec("1️⃣")],
      configuration: ["minimum_length": 5])
  }

  @Test func bothPartsWrongWithMinLength5() async {
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1_000.000_1",
      expected: "let foo = 1000.0001",
      findings: [FindingSpec("1️⃣")],
      configuration: ["minimum_length": 5])
  }

  // MARK: - Minimum fraction length

  @Test func longFractionSeparatedDoesNotViolateWithMinFraction5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1_000.000_000_1",
      configuration: ["minimum_fraction_length": 5])
  }

  @Test func sixDigitFractionSeparatedDoesNotViolateWithMinFraction5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1.000_001",
      configuration: ["minimum_fraction_length": 5])
  }

  @Test func fourDigitFractionUnseparatedDoesNotViolateWithMinFraction5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 100.0001",
      configuration: ["minimum_fraction_length": 5])
  }

  @Test func fiveDigitFractionUnseparatedDoesNotViolateWithMinFraction5() async {
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1_000.000_01",
      configuration: ["minimum_fraction_length": 5])
  }

  @Test func missingIntegerSeparatorViolatesWithMinFraction5() async {
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1000",
      expected: "let foo = 1_000",
      findings: [FindingSpec("1️⃣")],
      configuration: ["minimum_fraction_length": 5])
  }

  @Test func wrongFractionSeparatorViolatesWithMinFraction5() async {
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1.000_1",
      expected: "let foo = 1.0001",
      findings: [FindingSpec("1️⃣")],
      configuration: ["minimum_fraction_length": 5])
  }

  @Test func bothPartsWrongWithMinFraction5() async {
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1_000.000_1",
      expected: "let foo = 1_000.0001",
      findings: [FindingSpec("1️⃣")],
      configuration: ["minimum_fraction_length": 5])
  }

  // MARK: - Exclude ranges

  @Test func numberInExcludedRangeDoesNotViolate() async {
    let config: [String: any Sendable] = [
      "exclude_ranges": [
        ["min": 1900, "max": 2030],
        ["min": 2.0, "max": 3.0],
      ],
      "minimum_fraction_length": 3,
    ]
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1950",
      configuration: config)
  }

  @Test func separatedNumberInExcludedRangeDoesNotViolate() async {
    let config: [String: any Sendable] = [
      "exclude_ranges": [
        ["min": 1900, "max": 2030],
        ["min": 2.0, "max": 3.0],
      ],
      "minimum_fraction_length": 3,
    ]
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 1_985",
      configuration: config)
  }

  @Test func fractionInExcludedRangeDoesNotViolate() async {
    let config: [String: any Sendable] = [
      "exclude_ranges": [
        ["min": 1900, "max": 2030],
        ["min": 2.0, "max": 3.0],
      ],
      "minimum_fraction_length": 3,
    ]
    await assertNoViolation(
      NumberSeparatorRule.self,
      "let foo = 2.10042",
      configuration: config)
  }

  @Test func numberOutsideExcludedRangeViolates() async {
    let config: [String: any Sendable] = [
      "exclude_ranges": [
        ["min": 1900, "max": 2030],
        ["min": 2.0, "max": 3.0],
      ],
      "minimum_fraction_length": 3,
    ]
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣1000",
      expected: "let foo = 1_000",
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func fractionOutsideExcludedRangeViolates() async {
    let config: [String: any Sendable] = [
      "exclude_ranges": [
        ["min": 1900, "max": 2030],
        ["min": 2.0, "max": 3.0],
      ],
      "minimum_fraction_length": 3,
    ]
    await assertFormatting(
      NumberSeparatorRule.self,
      input: "let foo = 1️⃣3.343434",
      expected: "let foo = 3.343_434",
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  // MARK: - Specific violation reasons

  @Test func correctlySeparatedNumberHasNoViolation() async {
    #expect(
      await violations(in: "1_000") == [])
  }

  @Test func missingSeparatorsReportsCorrectReason() async {
    #expect(
      await violations(in: "1000") == [NumberSeparatorRule.missingSeparatorsReason])
  }

  @Test func missingSeparatorsInFractionReportsCorrectReason() async {
    #expect(
      await violations(in: "1.000000", config: ["minimum_fraction_length": 5]) == [
        NumberSeparatorRule.missingSeparatorsReason
      ])
  }

  @Test func misplacedSeparatorsReportsCorrectReason() async {
    #expect(
      await violations(in: "10_00") == [NumberSeparatorRule.misplacedSeparatorsReason])
  }

  @Test func misplacedSeparatorsWithExtraDigitReportsCorrectReason() async {
    #expect(
      await violations(in: "1_000_0") == [NumberSeparatorRule.misplacedSeparatorsReason])
  }

  @Test func misplacedFractionSeparatorsReportsCorrectReason() async {
    #expect(
      await violations(in: "1000.0_00") == [NumberSeparatorRule.misplacedSeparatorsReason])
  }

  @Test func misplacedSeparatorsWithMinLengthReportsCorrectReason() async {
    #expect(
      await violations(in: "10_00", config: ["minimum_length": 5]) == [
        NumberSeparatorRule.misplacedSeparatorsReason
      ])
  }

  @Test func misplacedFractionSeparatorsWithMinFractionLengthReportsCorrectReason() async {
    #expect(
      await violations(in: "1000.0_00", config: ["minimum_fraction_length": 5]) == [
        NumberSeparatorRule.misplacedSeparatorsReason
      ])
  }

  private func violations(in code: String, config: [String: Any] = [:]) -> [String] {
    var rule = NumberSeparatorRule()
    try? rule.options.apply(configuration: config)
    let visitor = rule.makeVisitor(file: SwiftSource(contents: ""))
    visitor.walk(Parser.parse(source: "let a = " + code))
    return visitor.violations.compactMap { $0.reason?.text }
  }
}
