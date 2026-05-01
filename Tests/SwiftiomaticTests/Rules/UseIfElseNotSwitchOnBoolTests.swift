@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseIfElseNotSwitchOnBoolTests: RuleTesting {
  @Test func basicEarlyReturns() {
    // Indentation in the expected output is intentionally incorrect because
    // this formatting rule does not fix it — the pretty printer handles it.
    assertFormatting(
      UseIfElseNotSwitchOnBool.self,
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
      UseIfElseNotSwitchOnBool.self,
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

  @Test func singleIfPlusFinalReturn() {
    assertFormatting(
      UseIfElseNotSwitchOnBool.self,
      input: """
        func f(_ x: Int) -> Bool {
          1️⃣if x > 0 { return true }
          return false
        }
        """,
      expected: """
        func f(_ x: Int) -> Bool {
          if x > 0 {
          true
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

  @Test func singleIfCaseLetPlusFinalReturn() {
    assertFormatting(
      UseIfElseNotSwitchOnBool.self,
      input: """
        func f(_ storage: Storage) -> Int {
          1️⃣if case let .array(arr) = storage.value { return arr.count }
          return 0
        }
        """,
      expected: """
        func f(_ storage: Storage) -> Int {
          if case let .array(arr) = storage.value {
          arr.count
        } else {
          0
        }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace early-return chain with if/else expression"),
      ]
    )
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
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func ifWithElseDoesNotMatch() {
    // If an if already has an else branch, skip the whole chain
    let input = """
      if x > 0 { return true } else { return false }
      if x < 0 { return false }
      return false
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func nonReturnBodiesDoNotMatch() {
    // The if body must be a single return statement
    let input = """
      if x > 0 { print("yes") }
      if x < 0 { print("no") }
      return false
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func threeIfsPlusFinalReturn() {
    assertFormatting(
      UseIfElseNotSwitchOnBool.self,
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
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func chainInsideSwitchCaseDoesNotMatch() {
    // The bare-expression branches would silently drop the original `return`
    // statements that exit the enclosing function from a switch case body.
    let input = """
      func f(_ x: Int) -> Bool {
        switch x {
        case 0:
          if x > 0 { return true }
          if x < 0 { return false }
          return false
        default:
          return false
        }
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func chainInsideIfBodyDoesNotMatch() {
    // Inside an if body that isn't itself the implicit-return position, the
    // rewrite would discard the explicit returns.
    let input = """
      func f(_ x: Int) -> Bool {
        if x > 100 {
          if x > 0 { return true }
          if x < 0 { return false }
          return false
        }
        return false
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func chainInsideLoopBodyDoesNotMatch() {
    let input = """
      func f(_ items: [Int]) -> Bool {
        for x in items {
          if x > 0 { return true }
          if x < 0 { return false }
          return false
        }
        return false
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func chainNotAtStartOfFunctionBodyDoesNotMatch() {
    // The chain doesn't occupy the entire body — the bare if/else expression
    // would be a discarded value rather than the function's return.
    let input = """
      func f(_ x: Int) -> Bool {
        let scaled = x * 2
        if scaled > 0 { return true }
        if scaled < 0 { return false }
        return false
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func guardPlusFinalReturnInClosure() {
    assertFormatting(
      UseIfElseNotSwitchOnBool.self,
      input: """
        let f: (Int?) -> Int = { x in
          1️⃣guard let y = x else { return 0 }
          return y * 2
        }
        """,
      expected: """
        let f: (Int?) -> Int = { x in
          if let y = x {
          y * 2
        } else {
          0
        }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace early-return chain with if/else expression"),
      ]
    )
  }

  @Test func guardPlusFinalReturnInFunctionBody() {
    assertFormatting(
      UseIfElseNotSwitchOnBool.self,
      input: """
        func f(_ x: Int?) -> Int {
          1️⃣guard let y = x else { return -1 }
          return y * 2
        }
        """,
      expected: """
        func f(_ x: Int?) -> Int {
          if let y = x {
          y * 2
        } else {
          -1
        }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace early-return chain with if/else expression"),
      ]
    )
  }

  @Test func guardWithIntermediateStatementDoesNotFire() {
    let input = """
      func f(_ x: Int?) -> Int {
        guard let y = x else { return -1 }
        let z = y * 2
        return z
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func guardElseWithMultipleStatementsDoesNotFire() {
    let input = """
      func f(_ x: Int?) -> Int {
        guard let y = x else {
          print("nope")
          return -1
        }
        return y * 2
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func guardInsideSwitchCaseDoesNotFire() {
    let input = """
      func f(_ x: Int?) -> Int {
        switch x {
        case .some:
          guard let y = x else { return -1 }
          return y * 2
        default:
          return 0
        }
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }

  @Test func chainWithFollowingStatementDoesNotMatch() {
    // Statements after the chain mean the if/else expression's value would be
    // discarded rather than implicitly returned.
    let input = """
      func f(_ x: Int) -> Bool {
        if x > 0 { return true }
        if x < 0 { return false }
        return false
        let unreachable = 1
        _ = unreachable
      }
      """
    assertFormatting(UseIfElseNotSwitchOnBool.self, input: input, expected: input, findings: [])
  }
}
