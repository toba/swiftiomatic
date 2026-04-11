import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct MultilineArgumentsRuleTests {
  // MARK: - Default configuration (any_line)

  @Test func singleLineCallDoesNotTrigger() async {
    await assertNoViolation(MultilineArgumentsRule.self, "foo(0)")
  }

  @Test func singleLineWithLabelDoesNotTrigger() async {
    await assertNoViolation(MultilineArgumentsRule.self, "foo(0, param1: 1)")
  }

  @Test func allArgumentsOnSeparateLinesDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      """
      foo(param1: 1,
          param2: true,
          param3: [3])
      """)
  }

  @Test func allArgumentsOnNextLineDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      """
      foo(
          param1: 1, param2: true, param3: [3]
      )
      """)
  }

  @Test func eachArgumentOnOwnLineDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      """
      foo(
          param1: 1,
          param2: true,
          param3: [3]
      )
      """)
  }

  @Test func trailingClosureLabelDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      """
      UIView.animate(withDuration: 1, delay: 0) {
          print("a")
      } completion: { _ in
          print("b")
      }
      """)
  }

  @Test func trailingCommaDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      """
      f(
          foo: 1,
          bar: false,
      )
      """)
  }

  @Test func mixedSameAndNextLineViolates() async {
    await assertLint(
      MultilineArgumentsRule.self,
      """
      foo(0,
          param1: 1, 1️⃣param2: true, 2️⃣param3: [3])
      """,
      findings: [
        FindingSpec("1️⃣"),
        FindingSpec("2️⃣"),
      ])
  }

  @Test func firstArgSameLineRestMixedViolates() async {
    await assertLint(
      MultilineArgumentsRule.self,
      """
      foo(0, 1️⃣param1: 1,
          param2: true, 2️⃣param3: [3])
      """,
      findings: [
        FindingSpec("1️⃣"),
        FindingSpec("2️⃣"),
      ])
  }

  @Test func multipleOnSameLineBeforeSplitViolates() async {
    await assertLint(
      MultilineArgumentsRule.self,
      """
      foo(0, 1️⃣param1: 1, 2️⃣param2: true,
          param3: [3])
      """,
      findings: [
        FindingSpec("1️⃣"),
        FindingSpec("2️⃣"),
      ])
  }

  @Test func wrappedFirstArgMixedViolates() async {
    await assertLint(
      MultilineArgumentsRule.self,
      """
      foo(
          0, 1️⃣param1: 1,
          param2: true, 2️⃣param3: [3]
      )
      """,
      findings: [
        FindingSpec("1️⃣"),
        FindingSpec("2️⃣"),
      ])
  }

  // MARK: - first_argument_location: next_line

  @Test func nextLineEmptyCallDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo()",
      configuration: ["first_argument_location": "next_line"])
  }

  @Test func nextLineSingleArgDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(0)",
      configuration: ["first_argument_location": "next_line"])
  }

  @Test func nextLineSingleLineWithClosureDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(1, bar: baz) { }",
      configuration: ["first_argument_location": "next_line"])
  }

  @Test func nextLineMultilineBodyDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(2, bar: baz) {\n}",
      configuration: ["first_argument_location": "next_line"])
  }

  @Test func nextLineWrappedArgsDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(\n    3,\n    bar: baz) { }",
      configuration: ["first_argument_location": "next_line"])
  }

  @Test func nextLineMixedWrappedDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(\n    4, bar: baz) { }",
      configuration: ["first_argument_location": "next_line"])
  }

  @Test func nextLineFirstArgOnSameLineViolates() async {
    await assertViolates(
      MultilineArgumentsRule.self,
      "foo(1,\n    bar: baz) { }",
      configuration: ["first_argument_location": "next_line"])
  }

  // MARK: - first_argument_location: same_line

  @Test func sameLineEmptyCallDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo()",
      configuration: ["first_argument_location": "same_line"])
  }

  @Test func sameLineSingleArgDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(0)",
      configuration: ["first_argument_location": "same_line"])
  }

  @Test func sameLineSingleLineWithClosureDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(1, bar: 1) { }",
      configuration: ["first_argument_location": "same_line"])
  }

  @Test func sameLineMultilineBodyDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(2, bar: 2) {\n    bar()\n}",
      configuration: ["first_argument_location": "same_line"])
  }

  @Test func sameLineWrappedSecondArgDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(3,\n    bar: 3) { }",
      configuration: ["first_argument_location": "same_line"])
  }

  @Test func sameLineFirstArgOnNextLineViolates() async {
    await assertViolates(
      MultilineArgumentsRule.self,
      "foo(\n    1, bar: baz) { }",
      configuration: ["first_argument_location": "same_line"])
  }

  @Test func sameLineFirstArgOnNextLineSplitViolates() async {
    await assertViolates(
      MultilineArgumentsRule.self,
      "foo(\n    2,\n    bar: baz) { }",
      configuration: ["first_argument_location": "same_line"])
  }

  // MARK: - only_enforce_after_first_closure_on_first_line

  @Test func closureOnFirstLineTrailingClosuresDoNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(a: a, b: {\n}, c: {\n})",
      configuration: ["only_enforce_after_first_closure_on_first_line": true])
  }

  @Test func closureOnFirstLineWrappedTrailingClosuresDoNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(\n    a: a, b: {\n    }, c: {\n})",
      configuration: ["only_enforce_after_first_closure_on_first_line": true])
  }

  @Test func closureOnFirstLineMultipleArgsAndClosuresDoNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(a: a, b: b, c: {\n}, d: {\n})",
      configuration: ["only_enforce_after_first_closure_on_first_line": true])
  }

  @Test func closureOnFirstLineWeakSelfCaptureDoesNotTrigger() async {
    await assertNoViolation(
      MultilineArgumentsRule.self,
      "foo(a: a, b: { [weak self] in\n}, c: { flag in\n})",
      configuration: ["only_enforce_after_first_closure_on_first_line": true])
  }

  @Test func closureOnFirstLineSplitBeforeClosureViolates() async {
    await assertViolates(
      MultilineArgumentsRule.self,
      "foo(a: a,\n    b: b, c: {\n})",
      configuration: ["only_enforce_after_first_closure_on_first_line": true])
  }

  @Test func closureOnFirstLineMultipleSplitsViolate() async {
    await assertViolates(
      MultilineArgumentsRule.self,
      "foo(a: a, b: b,\n    c: c, d: {\n    }, d: {\n})",
      configuration: ["only_enforce_after_first_closure_on_first_line": true])
  }
}
