import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ColonRuleTests {

  // MARK: - Default Configuration (no violations)

  @Test func noViolationForCorrectTypeAnnotation() async {
    await assertNoViolation(ColonRule.self, "let abc: Void")
  }

  @Test func noViolationForDictionaryType() async {
    await assertNoViolation(ColonRule.self, "let abc: [Void: Void]")
  }

  @Test func noViolationForTupleType() async {
    await assertNoViolation(ColonRule.self, "let abc: (Void, Void)")
  }

  @Test func noViolationForFunctionParameter() async {
    await assertNoViolation(ColonRule.self, "func abc(def: Void) {}")
  }

  @Test func noViolationForDictionaryLiteral() async {
    await assertNoViolation(ColonRule.self, "let abc = [Void: Void]()")
  }

  @Test func noViolationForNestedDictionary() async {
    await assertNoViolation(ColonRule.self, "let abc = [1: [3: 2], 3: 4]")
  }

  @Test func noViolationForClassInheritance() async {
    await assertNoViolation(ColonRule.self, "class Foo: Bar {}")
  }

  @Test func noViolationForGenericConstraint() async {
    await assertNoViolation(ColonRule.self, "class Foo<T: Equatable> {}")
  }

  @Test func noViolationForGenericInheritance() async {
    await assertNoViolation(ColonRule.self, "class Foo<T: Equatable>: Bar {}")
  }

  @Test func noViolationForSwitchCase() async {
    await assertNoViolation(
      ColonRule.self,
      """
      switch foo {
      case .bar:
          _ = something()
      }
      """)
  }

  @Test func noViolationForMethodCallWithComment() async {
    await assertNoViolation(ColonRule.self, "object.method(x: /* comment */ 5)")
  }

  @Test func noViolationForPrecedenceGroup() async {
    await assertNoViolation(
      ColonRule.self,
      """
      precedencegroup PipelinePrecedence {
        associativity: left
      }
      infix operator |> : PipelinePrecedence
      """)
  }

  @Test func noViolationForSwitchCaseAligned() async {
    await assertNoViolation(
      ColonRule.self,
      #"""
      switch str {
      case "adlm", "adlam":             return .adlam
      case "aghb", "caucasianalbanian": return .caucasianAlbanian
      default:                          return nil
      }
      """#)
  }

  @Test func noViolationForSwitchCaseWithComments() async {
    await assertNoViolation(
      ColonRule.self,
      """
      switch scalar {
        case 0x000A...0x000D /* LF ... CR */: return true
        case 0x0085 /* NEXT LINE (NEL) */: return true
        case 0x2028 /* LINE SEPARATOR */: return true
        case 0x2029 /* PARAGRAPH SEPARATOR */: return true
        default: return false
      }
      """)
  }

  // MARK: - Default Configuration (violations + corrections)

  @Test func correctsMissingSpaceAfterColonInTypeAnnotation() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣:Void",
      expected: "let abc: Void",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsExtraSpaceAfterColonInTypeAnnotation() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣:  Void",
      expected: "let abc: Void",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsSpaceBeforeColonInTypeAnnotation() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣ :Void",
      expected: "let abc: Void",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsSpaceBeforeAndAfterColonInTypeAnnotation() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣ : Void",
      expected: "let abc: Void",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsSpaceBeforeColonInFunctionParam() async {
    await assertFormatting(
      ColonRule.self,
      input: "func abc(def1️⃣ : Void) {}",
      expected: "func abc(def: Void) {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsMissingSpaceInFunctionParam() async {
    await assertFormatting(
      ColonRule.self,
      input: "func abc(def1️⃣:Void) {}",
      expected: "func abc(def: Void) {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsSecondParamWithSpaceBeforeColon() async {
    await assertFormatting(
      ColonRule.self,
      input: "func abc(def: Void, ghi1️⃣ :Void) {}",
      expected: "func abc(def: Void, ghi: Void) {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsDictionaryLiteralWithMissingSpace() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [Void1️⃣:Void]()",
      expected: "let abc = [Void: Void]()",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsDictionaryLiteralWithExtraSpaces() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [Void1️⃣ : Void]()",
      expected: "let abc = [Void: Void]()",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsDictionaryTypeWithExtraSpaces() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc: [String1️⃣ : Int]",
      expected: "let abc: [String: Int]",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsDictionaryTypeWithMissingSpace() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc: [String1️⃣:Int]",
      expected: "let abc: [String: Int]",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsClassInheritanceWithExtraSpaces() async {
    await assertFormatting(
      ColonRule.self,
      input: "class Foo1️⃣ : Bar {}",
      expected: "class Foo: Bar {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsClassInheritanceWithMissingSpace() async {
    await assertFormatting(
      ColonRule.self,
      input: "class Foo1️⃣:Bar {}",
      expected: "class Foo: Bar {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsGenericConstraintSpacing() async {
    await assertFormatting(
      ColonRule.self,
      input: "class Foo<T1️⃣ : Equatable> {}",
      expected: "class Foo<T: Equatable> {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsGenericConstraintMissingSpace() async {
    await assertFormatting(
      ColonRule.self,
      input: "class Foo<T1️⃣:Equatable> {}",
      expected: "class Foo<T: Equatable> {}",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsMethodCallArgSpacing() async {
    await assertFormatting(
      ColonRule.self,
      input: "object.method(x1️⃣:5, y: \"string\")",
      expected: "object.method(x: 5, y: \"string\")",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsSwitchCaseSpaceBeforeColon() async {
    await assertFormatting(
      ColonRule.self,
      input: """
        switch foo {
        case .bar1️⃣ : return baz
        }
        """,
      expected: """
        switch foo {
        case .bar: return baz
        }
        """,
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsClosureTypeAnnotation() async {
    await assertFormatting(
      ColonRule.self,
      input: "private var action1️⃣:(() -> Void)?",
      expected: "private var action: (() -> Void)?",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsNestedDictionaryViolation() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [1: [31️⃣ : 2], 3: 4]",
      expected: "let abc = [1: [3: 2], 3: 4]",
      findings: [FindingSpec("1️⃣", message: "")])
  }

  @Test func correctsMultipleViolationsInOneLine() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [1: [31️⃣ : 2], 32️⃣:  4]",
      expected: "let abc = [1: [3: 2], 3: 4]",
      findings: [
        FindingSpec("1️⃣", message: ""),
        FindingSpec("2️⃣", message: ""),
      ])
  }

  @Test func correctsIfDefDictionary() async {
    await assertFormatting(
      ColonRule.self,
      input: """
        class Foo {
            #if false
            #else
                let bar = ["key"1️⃣   : "value"]
            #endif
        }
        """,
      expected: """
        class Foo {
            #if false
            #else
                let bar = ["key": "value"]
            #endif
        }
        """,
      findings: [FindingSpec("1️⃣", message: "")])
  }

  // MARK: - Flexible Right Spacing

  @Test func flexibleRightSpacingAllowsExtraSpaceAfterColon() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc:  Void\n",
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingAllowsExtraSpaceInTupleType() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc:  (Void, String, Int)\n",
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingAllowsExtraSpaceInFuncParam() async {
    await assertNoViolation(
      ColonRule.self,
      "func abc(def:  Void) {}\n",
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingAllowsExtraSpaceInDictLiteral() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc = [Void:  Void]()\n",
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingStillDetectsSpaceBeforeColon() async {
    await assertViolates(
      ColonRule.self,
      "let abc : Void\n",
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingStillDetectsMissingSpaceAfterColon() async {
    await assertViolates(
      ColonRule.self,
      "let abc:Void\n",
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingCorrectsMissingSpace() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣:Void\n",
      expected: "let abc: Void\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingCorrectsSpaceBeforeColon() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣ : Void\n",
      expected: "let abc: Void\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingCorrectsFuncParamSpaceBeforeColon() async {
    await assertFormatting(
      ColonRule.self,
      input: "func abc(def1️⃣ : Void) {}\n",
      expected: "func abc(def: Void) {}\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingCorrectsDictSpaceBeforeColon() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [Void1️⃣ : Void]()\n",
      expected: "let abc = [Void: Void]()\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingCorrectsDictSpaceBeforeAndExtraAfter() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [Void1️⃣ :  Void]()\n",
      expected: "let abc = [Void: Void]()\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["flexible_right_spacing": true])
  }

  @Test func flexibleRightSpacingNestedDictKeepsExtraSpaceOnOuter() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc = [1: [31️⃣ : 2], 3:  4]\n",
      expected: "let abc = [1: [3: 2], 3:  4]\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["flexible_right_spacing": true])
  }

  // MARK: - Disable Dictionary Checking

  @Test func noDictionaryCheckAllowsDictMissingSpace() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc = [Void:Void]()\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckAllowsDictExtraSpaces() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc = [Void : Void]()\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckAllowsDictExtraSpaceAfter() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc = [Void:  Void]()\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckAllowsNestedDictExtraSpaces() async {
    await assertNoViolation(
      ColonRule.self,
      "let abc = [1: [3 : 2], 3: 4]\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckStillDetectsTypeAnnotationViolation() async {
    await assertViolates(
      ColonRule.self,
      "let abc :Void\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckStillDetectsExtraSpaceInTypeAnnotation() async {
    await assertViolates(
      ColonRule.self,
      "let abc:  Void\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckStillDetectsFuncParamViolation() async {
    await assertViolates(
      ColonRule.self,
      "func abc(def:  Void) {}\n",
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckCorrectsTypeAnnotation() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣ :Void\n",
      expected: "let abc: Void\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckCorrectsFuncParam() async {
    await assertFormatting(
      ColonRule.self,
      input: "func abc(def1️⃣ : Void) {}\n",
      expected: "func abc(def: Void) {}\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckCorrectsExtraSpaceAfter() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣:  Void\n",
      expected: "let abc: Void\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["apply_to_dictionaries": false])
  }

  @Test func noDictionaryCheckCorrectsEnumAssignment() async {
    await assertFormatting(
      ColonRule.self,
      input: "let abc1️⃣:Enum=Enum.Value\n",
      expected: "let abc: Enum=Enum.Value\n",
      findings: [FindingSpec("1️⃣", message: "")],
      configuration: ["apply_to_dictionaries": false])
  }
}
