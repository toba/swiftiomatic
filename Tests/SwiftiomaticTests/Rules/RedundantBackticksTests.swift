@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantBackticksTests: RuleTesting {
  @Test func nonKeywordBackticks() {
    assertLint(
      RedundantBackticks.self,
      """
      let 1️⃣`name` = "hello"
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'name'"),
      ]
    )
  }

  @Test func keywordBackticksNotFlagged() {
    assertLint(
      RedundantBackticks.self,
      """
      let `class` = "hello"
      """,
      findings: []
    )
  }

  @Test func noBackticksNotFlagged() {
    assertLint(
      RedundantBackticks.self,
      """
      let name = "hello"
      """,
      findings: []
    )
  }

  @Test func contextualKeywordBackticks() {
    assertLint(
      RedundantBackticks.self,
      """
      let 1️⃣`async` = true
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'async'"),
      ]
    )
  }

  @Test func functionName() {
    assertLint(
      RedundantBackticks.self,
      """
      func 1️⃣`myFunc`() {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'myFunc'"),
      ]
    )
  }

  @Test func reservedReturn() {
    assertLint(
      RedundantBackticks.self,
      """
      let `return` = 42
      """,
      findings: []
    )
  }

  @Test func reservedSelf() {
    assertLint(
      RedundantBackticks.self,
      """
      let `self` = instance
      """,
      findings: []
    )
  }
}
