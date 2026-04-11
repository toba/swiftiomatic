import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct TrailingCommaRuleTests {
  // MARK: - Non-triggering (default: no trailing commas)

  @Test func emptyArrayDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, "let foo = []")
  }

  @Test func emptyDictionaryDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, "let foo = [:]")
  }

  @Test func singleLineArrayDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, "let foo = [1, 2, 3]")
  }

  @Test func singleLineDictionaryDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, "let foo = [1: 2, 2: 3]")
  }

  @Test func typeConstructorDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, "let foo = [Void]()")
  }

  @Test func intTypeConstructorDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, "let foo = [Int]()")
  }

  @Test func stringInterpolationInDictDoesNotTrigger() async {
    await assertNoViolation(TrailingCommaRule.self, #"foo([1: "\(error)"])"#)
  }

  @Test func multilineWithCommentDoesNotTrigger() async {
    await assertNoViolation(
      TrailingCommaRule.self,
      "let example = [ 1,\n 2\n // 3,\n]")
  }

  // MARK: - Triggering (default: no trailing commas)

  @Test func singleLineTrailingCommaTriggers() async {
    await assertViolates(TrailingCommaRule.self, "let foo = [1, 2, 3,]")
  }

  @Test func singleLineTrailingCommaWithSpaceTriggers() async {
    await assertViolates(TrailingCommaRule.self, "let foo = [1, 2, 3, ]")
  }

  @Test func singleLineDictTrailingCommaTriggers() async {
    await assertViolates(TrailingCommaRule.self, "let foo = [1: 2, 2: 3, ]")
  }

  @Test func nestedStructTrailingCommaTriggers() async {
    await assertViolates(TrailingCommaRule.self, "struct Bar {\n let foo = [1: 2, 2: 3, ]\n}")
  }

  @Test func multipleTrailingCommasTrigger() async {
    await assertLint(
      TrailingCommaRule.self,
      "let foo = [1, 2, 3,] + [4, 5, 61️⃣,]",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func stringInterpolationTrailingCommaTriggers() async {
    await assertViolates(TrailingCommaRule.self, #"foo([1: "\(error)",])"#)
  }

  @Test func multilineWithCommentTrailingCommaTriggers() async {
    await assertViolates(TrailingCommaRule.self, "let example = [ 1,\n2,\n // 3,\n]")
  }

  @Test func conditionalCompilationTrailingCommaTriggers() async {
    await assertViolates(
      TrailingCommaRule.self,
      "class C {\n #if true\n func f() {\n let foo = [1, 2, 3,]\n }\n #endif\n}")
  }

  // MARK: - Corrections (default: remove trailing commas)

  @Test func correctsRemoveTrailingComma() async {
    await assertFormatting(
      TrailingCommaRule.self,
      input: "let foo = [1, 2, 31️⃣,]",
      expected: "let foo = [1, 2, 3]",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsRemoveTrailingCommaWithSpace() async {
    await assertFormatting(
      TrailingCommaRule.self,
      input: "let foo = [1, 2, 31️⃣, ]",
      expected: "let foo = [1, 2, 3 ]",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsRemoveDictTrailingComma() async {
    await assertFormatting(
      TrailingCommaRule.self,
      input: "let foo = [1: 2, 2: 31️⃣, ]",
      expected: "let foo = [1: 2, 2: 3 ]",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsRemoveStringInterpolationTrailingComma() async {
    await assertFormatting(
      TrailingCommaRule.self,
      input: #"foo([1: "\(error)"1️⃣,])"#,
      expected: #"foo([1: "\(error)"])"#,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Violation messages (default)

  @Test func violationMessageForDefault() async {
    await assertLint(
      TrailingCommaRule.self,
      "let array = [\n\t1,\n\t2,\n1️⃣]\n",
      findings: [
        FindingSpec("1️⃣", message: "Collection literals should not have trailing commas")
      ])
  }

  // MARK: - Mandatory comma configuration

  @Test func multilineWithoutTrailingCommaTriggersWhenMandatory() async {
    await assertViolates(
      TrailingCommaRule.self,
      "let foo = [1, 2,\n 3]\n",
      configuration: ["mandatory_comma": true])
  }

  @Test func multilineDictWithoutTrailingCommaTriggersWhenMandatory() async {
    await assertViolates(
      TrailingCommaRule.self,
      "let foo = [1: 2,\n 2: 3]\n",
      configuration: ["mandatory_comma": true])
  }

  @Test func singleLineWithoutCommaDoesNotTriggerWhenMandatory() async {
    await assertNoViolation(
      TrailingCommaRule.self,
      "let foo = [1, 2, 3]\n",
      configuration: ["mandatory_comma": true])
  }

  @Test func singleLineDictWithoutCommaDoesNotTriggerWhenMandatory() async {
    await assertNoViolation(
      TrailingCommaRule.self,
      "let foo = [1: 2, 2: 3]\n",
      configuration: ["mandatory_comma": true])
  }

  @Test func multilineWithTrailingCommaDoesNotTriggerWhenMandatory() async {
    await assertNoViolation(
      TrailingCommaRule.self,
      "let foo = [1, 2,\n 3,]\n",
      configuration: ["mandatory_comma": true])
  }

  @Test func unicodeMultilineWithoutTrailingCommaTriggersWhenMandatory() async {
    await assertViolates(
      TrailingCommaRule.self,
      "let foo = [\"אבג\", \"αβγ\",\n\"🇺🇸\"]\n",
      configuration: ["mandatory_comma": true])
  }

  // MARK: - Corrections (mandatory comma)

  @Test func correctsAddsMandatoryComma() async {
    await assertFormatting(
      TrailingCommaRule.self,
      input: "let foo = [1, 2,\n 31️⃣]\n",
      expected: "let foo = [1, 2,\n 3,]\n",
      findings: [FindingSpec("1️⃣")],
      configuration: ["mandatory_comma": true])
  }

  @Test func correctsAddsMandatoryCommaToDict() async {
    await assertFormatting(
      TrailingCommaRule.self,
      input: "let foo = [1: 2,\n 2: 31️⃣]\n",
      expected: "let foo = [1: 2,\n 2: 3,]\n",
      findings: [FindingSpec("1️⃣")],
      configuration: ["mandatory_comma": true])
  }

  // MARK: - Violation messages (mandatory)

  @Test func violationMessageForMandatory() async {
    await assertLint(
      TrailingCommaRule.self,
      "let array = [\n\t1,\n\t21️⃣\n]\n",
      findings: [
        FindingSpec(
          "1️⃣", message: "Multi-line collection literals should have trailing commas")
      ],
      configuration: ["mandatory_comma": true])
  }
}
