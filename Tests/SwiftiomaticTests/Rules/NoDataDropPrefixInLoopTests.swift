@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoDataDropPrefixInLoopTests: RuleTesting {
  @Test func dropFirstInWhile() {
    assertLint(
      NoDataDropPrefixInLoop.self,
      """
      while !data.isEmpty {
        let head = data.first ?? 0
        data = 1️⃣data.dropFirst()
        process(head)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'.dropFirst' inside a loop copies the collection on every iteration — use index advancement or a single slice"),
      ]
    )
  }

  @Test func prefixInForLoop() {
    assertLint(
      NoDataDropPrefixInLoop.self,
      """
      for chunk in chunks {
        let head = 1️⃣chunk.prefix(8)
        process(head)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'.prefix' inside a loop copies the collection on every iteration — use index advancement or a single slice"),
      ]
    )
  }

  @Test func dropLastInLoop() {
    assertLint(
      NoDataDropPrefixInLoop.self,
      """
      while keep {
        buffer = 1️⃣buffer.dropLast()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'.dropLast' inside a loop copies the collection on every iteration — use index advancement or a single slice"),
      ]
    )
  }

  @Test func dropFirstOutsideLoopNotFlagged() {
    assertLint(
      NoDataDropPrefixInLoop.self,
      """
      let rest = data.dropFirst()
      """,
      findings: []
    )
  }

  @Test func dropFirstInClosureBodyOfLoopNotFlagged() {
    assertLint(
      NoDataDropPrefixInLoop.self,
      """
      for item in items {
        item.transform { value in
          let _ = value.dropFirst()
        }
      }
      """,
      findings: []
    )
  }
}
