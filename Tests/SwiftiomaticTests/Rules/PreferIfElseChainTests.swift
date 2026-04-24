@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferIfElseChainTests: RuleTesting {
  @Test func basicEarlyReturns() {
    // Indentation in the expected output is intentionally incorrect because
    // this formatting rule does not fix it — the pretty printer handles it.
    assertFormatting(
      PreferIfElseChain.self,
      input: """
        func f(_ x: Int) -> Bool {
          1️⃣if x > 0 { return true }
          if x < 0 { return false }
          return false
        }
        """,
      expected: """
        func f(_ x: Int) -> Bool {
          if x > 0 {
          true
        } else if x < 0 {
          false
        } else {
          false
        }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace early-return chain with if/else expression"),
      ]
    )
  }

  @Test func twoIfsPlusFinalReturn() {
    assertFormatting(
      PreferIfElseChain.self,
      input: """
        1️⃣if case .spaces = $0 { return true }
        if case .tabs = $0 { return true }
        return false
        """,
      expected: """
        if case .spaces = $0 {
          true
        } else if case .tabs = $0 {
          true
        } else {
          false
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace early-return chain with if/else expression"),
      ]
    )
  }

  @Test func singleIfDoesNotMatch() {
    // A single if + return is not a "chain" — leave it alone
    let input = """
      if x > 0 { return true }
      return false
      """
    assertFormatting(PreferIfElseChain.self, input: input, expected: input, findings: [])
  }

  @Test func multiLineIfBodies() {
    // If any if body has more than a single return, skip it
    let input = """
      if x > 0 {
        print("positive")
        return true
      }
      if x < 0 { return false }
      return false
      """
    assertFormatting(PreferIfElseChain.self, input: input, expected: input, findings: [])
  }

  @Test func ifWithElseDoesNotMatch() {
    // If an if already has an else branch, skip the whole chain
    let input = """
      if x > 0 { return true } else { return false }
      if x < 0 { return false }
      return false
      """
    assertFormatting(PreferIfElseChain.self, input: input, expected: input, findings: [])
  }

  @Test func nonReturnBodiesDoNotMatch() {
    // The if body must be a single return statement
    let input = """
      if x > 0 { print("yes") }
      if x < 0 { print("no") }
      return false
      """
    assertFormatting(PreferIfElseChain.self, input: input, expected: input, findings: [])
  }

  @Test func threeIfsPlusFinalReturn() {
    assertFormatting(
      PreferIfElseChain.self,
      input: """
        1️⃣if x == 1 { return "one" }
        if x == 2 { return "two" }
        if x == 3 { return "three" }
        return "other"
        """,
      expected: """
        if x == 1 {
          "one"
        } else if x == 2 {
          "two"
        } else if x == 3 {
          "three"
        } else {
          "other"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace early-return chain with if/else expression"),
      ]
    )
  }

  @Test func interruptedChainDoesNotMatch() {
    // A non-if statement breaks the chain
    let input = """
      if x > 0 { return true }
      let y = x + 1
      if y > 0 { return true }
      return false
      """
    assertFormatting(PreferIfElseChain.self, input: input, expected: input, findings: [])
  }
}
