@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferLazyForLongChainTests: RuleTesting {
  @Test func threeLinkChainFlagged() {
    assertLint(
      PreferLazyForLongChain.self,
      """
      let result = 1️⃣items.map(\\.id).filter { $0 > 0 }.compactMap(format)
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  @Test func fourLinkChainFlagged() {
    assertLint(
      PreferLazyForLongChain.self,
      """
      let result = 1️⃣items.map(\\.id).filter { $0 > 0 }.compactMap(format).prefix(10)
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 4 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  @Test func twoLinkChainNotFlagged() {
    assertLint(
      PreferLazyForLongChain.self,
      """
      let result = items.map(\\.id).filter { $0 > 0 }
      """,
      findings: []
    )
  }

  @Test func nonChainCallsNotFlagged() {
    assertLint(
      PreferLazyForLongChain.self,
      """
      foo(items)
      """,
      findings: []
    )
  }

  @Test func twoChainsAdjacentEachReportedOnce() {
    assertLint(
      PreferLazyForLongChain.self,
      """
      let a = 1️⃣x.map(f).filter(p).compactMap(g)
      let b = 2️⃣y.map(f).filter(p).compactMap(g)
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
        FindingSpec("2️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }
}
