@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct CollapseSimpleIfElseTests: RuleTesting {

  @Test func collapsesIfLetElse() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        1️⃣if let defaultValue = last?.defaultValue {
            defaultValue
        } else {
            last?.type
        }
        """,
      expected: """
        if let defaultValue = last?.defaultValue { defaultValue } else { last?.type }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple if/else onto a single line"),
      ])
  }

  @Test func collapsesSimpleReturnPair() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        1️⃣if cond {
            return a
        } else {
            return b
        }
        """,
      expected: """
        if cond { return a } else { return b }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple if/else onto a single line"),
      ])
  }

  @Test func collapsesIfElseIfElseChain() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        1️⃣if a {
            x
        } else if b {
            y
        } else {
            z
        }
        """,
      expected: """
        if a { x } else if b { y } else { z }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple if/else onto a single line"),
      ])
  }

  @Test func skipsIfWithoutElse() {
    // Bare `if` is the responsibility of WrapSingleLineBodies (inline mode).
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if cond {
            doThing()
        }
        """,
      expected: """
        if cond {
            doThing()
        }
        """)
  }

  @Test func skipsMultiStatementBranch() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if cond {
            doA()
            doB()
        } else {
            doC()
        }
        """,
      expected: """
        if cond {
            doA()
            doB()
        } else {
            doC()
        }
        """)
  }

  @Test func skipsMultiStatementInElse() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if cond {
            doA()
        } else {
            doB()
            doC()
        }
        """,
      expected: """
        if cond {
            doA()
        } else {
            doB()
            doC()
        }
        """)
  }

  @Test func skipsBranchWithComment() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if cond {
            // important
            a
        } else {
            b
        }
        """,
      expected: """
        if cond {
            // important
            a
        } else {
            b
        }
        """)
  }

  @Test func skipsWhenTooLongForOneLine() {
    var config = Configuration.forTesting(enabledRule: CollapseSimpleIfElse.key)
    config[LineLength.self] = 40

    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if let value = somethingReallyLong {
            value.transformedIntoSomething
        } else {
            fallbackValueExpression
        }
        """,
      expected: """
        if let value = somethingReallyLong {
            value.transformedIntoSomething
        } else {
            fallbackValueExpression
        }
        """,
      configuration: config)
  }

  @Test func alreadyInlineUnchanged() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if cond { a } else { b }
        """,
      expected: """
        if cond { a } else { b }
        """)
  }

  @Test func collapsesNestedInsideFunction() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        func value() -> Int {
            1️⃣if let n = optional {
                n
            } else {
                0
            }
        }
        """,
      expected: """
        func value() -> Int {
            if let n = optional { n } else { 0 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple if/else onto a single line"),
      ])
  }

  @Test func skipsEmptyBranch() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        if cond {
        } else {
            b
        }
        """,
      expected: """
        if cond {
        } else {
            b
        }
        """)
  }

  @Test func collapsesIfCaseElse() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        1️⃣if case .some(let x) = optional {
            x
        } else {
            0
        }
        """,
      expected: """
        if case .some(let x) = optional { x } else { 0 }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple if/else onto a single line"),
      ])
  }

  @Test func collapsesElseIfWithoutTrailingElse() {
    assertFormatting(
      CollapseSimpleIfElse.self,
      input: """
        1️⃣if a {
            x
        } else if b {
            y
        }
        """,
      expected: """
        if a { x } else if b { y }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple if/else onto a single line"),
      ])
  }
}
