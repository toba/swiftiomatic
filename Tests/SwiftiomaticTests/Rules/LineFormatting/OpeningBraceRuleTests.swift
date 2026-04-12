import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct OpeningBraceRuleTests {
  // MARK: - Non-triggering (default)

  @Test func funcWithSpaceBeforeBraceDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "func abc() {\n}")
  }

  @Test func closureMapDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "[].map() { $0 }")
  }

  @Test func closureMapWithParensDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "[].map({ })")
  }

  @Test func ifLetDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "if let a = b { }")
  }

  @Test func whileDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "while a == b { }")
  }

  @Test func guardDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "guard let a = b else { }")
  }

  @Test func structDoesNotTrigger() async {
    await assertNoViolation(OpeningBraceRule.self, "struct Rule {}")
  }

  @Test func nestedStructDoesNotTrigger() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}")
  }

  @Test func closureInFuncDoesNotTrigger() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      func f(rect: CGRect) {
          {
              let centre = CGPoint(x: rect.midX, y: rect.midY)
              print(centre)
          }()
      }
      """)
  }

  @Test func regexPatternDoesNotTrigger() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      ##"let pattern = #/(\{(?<key>\w+)\})/#"##)
  }

  @Test func ifElseOnSeparateLineDoesNotTrigger() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      if c {}
      else {}
      """)
  }

  @Test func ifWithBlockCommentDoesNotTrigger() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
          if c /* comment */ {
              return
          }
      """)
  }

  // MARK: - Triggering (default)

  @Test func funcMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "func abc()1️⃣{\n}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func funcBraceOnNewLineTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "func abc()\n\t1️⃣{ }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mapMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "[].map()1️⃣{ $0 }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifLetMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "if let a = b1️⃣{ }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func whileMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "while a == b1️⃣{ }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func guardMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "guard let a = b else1️⃣{ }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func structMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "struct Rule1️⃣{}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func structBraceOnNewLineTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "struct Rule\n1️⃣{\n}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func switchMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "switch a1️⃣{}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func classMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "class Rule1️⃣{}\n",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func actorMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "actor Rule1️⃣{}\n",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func enumMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "enum Rule1️⃣{}\n",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func protocolMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "protocol Rule1️⃣{}\n",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func extensionMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      "extension Rule1️⃣{}\n",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func computedPropertyMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      class Rule {
        var a: String1️⃣{
          return ""
        }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func willSetDidSetMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      class Rule {
        var a: String {
          willSet1️⃣{

          }
          didSet  2️⃣{

          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  @Test func precedenceGroupMissingSpaceTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      precedencegroup Group1️⃣{
        assignment: true
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifConditionBraceOnNewLineTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      if
          "test".isEmpty
      1️⃣{
          // code here
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func multilineIfLetBraceOnNewLineTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      func fooFun() {
          let foo: String? = "foo"
          let bar: String? = "bar"

          if
              let foo = foo,
              let bar = bar
          1️⃣{
              print(foo + bar)
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifElseExtraSpacesAndCommentTriggers() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      if c  1️⃣{}
      else /* comment */  2️⃣{}
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  // MARK: - Corrections

  @Test func correctsStructMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: "struct Rule1️⃣{}",
      expected: "struct Rule {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsStructBraceOnNewLine() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: "struct Rule\n1️⃣{\n}",
      expected: "struct Rule {\n}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsClassMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: "class Rule1️⃣{}",
      expected: "class Rule {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsActorMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: "actor Rule1️⃣{}",
      expected: "actor Rule {}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsMapMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: "[].map()1️⃣{ $0 }",
      expected: "[].map() { $0 }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsIfMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: "if a == b1️⃣{ }",
      expected: "if a == b { }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsGuardBraceOnNewLine() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: """
        guard a == b else
        1️⃣{
          return ""
        }
        """,
      expected: """
        guard a == b else {
          return ""
        }
        """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsWillSetMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: """
        class Rule {
          var a: String {
            willSet1️⃣{

            }
          }
        }
        """,
      expected: """
        class Rule {
          var a: String {
            willSet {

            }
          }
        }
        """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsDidSetExtraSpaces() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: """
        class Rule {
          var a: String {
            didSet  1️⃣{

            }
          }
        }
        """,
      expected: """
        class Rule {
          var a: String {
            didSet {

            }
          }
        }
        """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsPrecedenceGroupMissingSpace() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: """
        precedencegroup Group1️⃣{
          assignment: true
        }
        """,
      expected: """
        precedencegroup Group {
          assignment: true
        }
        """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsIfBraceOnNewLineWithComment() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: """
            if c    // A comment
            1️⃣{
                return
            }
        """,
      expected: """
            if c { // A comment
                return
            }
        """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsIfElseBracesOnNewLines() async {
    await assertFormatting(
      OpeningBraceRule.self,
      input: """
        func foo() {
            if q1, q2
            1️⃣{
                do1()
            } else if q3, q4
            2️⃣{
                do2()
            }
        }
        """,
      expected: """
        func foo() {
            if q1, q2 {
                do1()
            } else if q3, q4 {
                do2()
            }
        }
        """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  // MARK: - ignore_multiline_type_headers

  @Test func multilineExtensionWhereDoesNotTriggerWithTypeHeaders() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      extension A
          where B: Equatable
      {}
      """,
      configuration: ["ignore_multiline_type_headers": true])
  }

  @Test func multilineStructConformanceDoesNotTriggerWithTypeHeaders() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      struct S: Comparable,
                Identifiable
      {
          init() {}
      }
      """,
      configuration: ["ignore_multiline_type_headers": true])
  }

  @Test func singleLineStructBraceOnNewLineTriggersWithTypeHeaders() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      struct S
      1️⃣{}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_type_headers": true])
  }

  @Test func singleLineExtensionWhereTriggersWithTypeHeaders() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      extension A where B: Equatable
      1️⃣{

      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_type_headers": true])
  }

  @Test func classWithCommentTriggersWithTypeHeaders() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      class C
          // with comments
      1️⃣{}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_type_headers": true])
  }

  // MARK: - ignore_multiline_statement_conditions

  @Test func multilineWhileDoesNotTriggerWithStatementConditions() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      while
          abc
      {}
      """,
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  @Test func multilineIfElseDoesNotTriggerWithStatementConditions() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      if x {

      } else if
          y,
          z
      {

      }
      """,
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  @Test func multilineIfLetDoesNotTriggerWithStatementConditions() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      if
          condition1,
          let var1 = var1
      {}
      """,
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  @Test func singleLineIfTriggersWithStatementConditions() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      if x
      1️⃣{}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  @Test func singleLineIfElseTriggersWithStatementConditions() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      if x {

      } else if y, z
      1️⃣{}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  @Test func elseWithoutConditionTriggersWithStatementConditions() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      if x {

      } else
      1️⃣{}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  @Test func whileWithCommentTriggersWithStatementConditions() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      while abc
          // comments
      1️⃣{
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_statement_conditions": true])
  }

  // MARK: - ignore_multiline_function_signatures

  @Test func multilineFuncParamsDoesNotTriggerWithFunctionSignatures() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      func abc(
      )
      {}
      """,
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func multilineFuncParamsWithBodyDoesNotTriggerWithFunctionSignatures() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      func abc(a: Int,
               b: Int)

      {

      }
      """,
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func multilineInitDoesNotTriggerWithFunctionSignatures() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      struct S {
          init(
          )
          {}
      }
      """,
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func multilineInitWithParamsDoesNotTriggerWithFunctionSignatures() async {
    await assertNoViolation(
      OpeningBraceRule.self,
      """
      class C {
          init(a: Int,
               b: Int)

        {

          }
      }
      """,
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func singleLineFuncTriggersWithFunctionSignatures() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      func abc()
      1️⃣{}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func singleLineParamsFuncTriggersWithFunctionSignatures() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      func abc(a: Int,        b: Int)

      1️⃣{

      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func singleLineInitTriggersWithFunctionSignatures() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      struct S {
          init()
          1️⃣{}
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func singleLineInitParamsTriggersWithFunctionSignatures() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      class C {
          init(a: Int,       b: Int)

                  1️⃣{

          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_function_signatures": true])
  }

  @Test func initWithCommentTriggersWithFunctionSignatures() async {
    await assertLint(
      OpeningBraceRule.self,
      """
      class C {
          init(a: Int)
              // with comments
          1️⃣{}
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_multiline_function_signatures": true])
  }
}
