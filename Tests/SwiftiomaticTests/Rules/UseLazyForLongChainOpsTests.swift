@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseLazyForLongChainOpsTests: RuleTesting {
  @Test func threeLinkChainFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
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
      UseLazyForLongChainOps.self,
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
      UseLazyForLongChainOps.self,
      """
      let result = items.map(\\.id).filter { $0 > 0 }
      """,
      findings: []
    )
  }

  @Test func nonChainCallsNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      foo(items)
      """,
      findings: []
    )
  }

  @Test func chainAlreadyLazyNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let result = items.lazy.map(\\.id).filter { $0 > 0 }.compactMap(format)
      """,
      findings: []
    )
  }

  @Test func multilineChainAlreadyLazyNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let suffix = OrdinalTerm.suffixPreference(for: number)
          .lazy
          .compactMap { self[$0] }
          .filter { $0.matches(number) }
          .compactMap { $0.prefer(gender: gender) }
          .first
      """,
      findings: []
    )
  }

  @Test func eagerCallsBeforeLazyStillCounted() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let result = 1️⃣items.map(f).filter(p).compactMap(g).lazy.map(h).filter(q)
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  @Test func mapOnlyChainReturnedAsOptionalNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      func export() throws -> ExportProject? {
        return try fetch(id: configuration.projectID, from: db)
          .map { $0.excludingStatuses(excludedStatuses) }
          .map { configuration.includeNotes ? $0 : $0.strippingNotes() }
          .map { configuration.styling.map($0.pruningHiddenElements) ?? $0 }
      }
      """,
      findings: []
    )
  }

  @Test func mapOnlyChainWithNilCoalescingNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let result = value.map(f).map(g).map(h) ?? fallback
      """,
      findings: []
    )
  }

  @Test func mapOnlyChainBoundToOptionalNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let result: ExportProject? = value.map(f).map(g).flatMap(h)
      """,
      findings: []
    )
  }

  @Test func mapOnlyChainInOptionalBindingNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      func run() {
        guard let result = value.map(f).map(g).map(h) else { return }
      }
      """,
      findings: []
    )
  }

  @Test func mapOnlyChainReturnedAsArrayFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      func export() -> [Item] {
        return 1️⃣items.map(f).map(g).map(h)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  @Test func chainWithSequenceOnlyMethodReturnedAsOptionalFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      func export() -> [Item]? {
        return 1️⃣items.map(f).filter(p).map(h)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  @Test func mapOnlyChainWithNoOptionalSignalFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let result = 1️⃣items.map(f).map(g).map(h)
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  // MARK: - Single-pass consumers

  @Test func oneLinkChainBeforeSinglePassConsumerFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let minY = 1️⃣vertices.map { $0.y }.min()
      let hasEmpty = 2️⃣rows.map { $0.title }.contains(where: { $0.isEmpty })
      let total = 3️⃣items.compactMap(price).reduce(0, +)
      """,
      findings: [
        FindingSpec("1️⃣", message: "collection transforms before 'min' allocate an intermediate array — consider '.lazy'"),
        FindingSpec("2️⃣", message: "collection transforms before 'contains' allocate an intermediate array — consider '.lazy'"),
        FindingSpec("3️⃣", message: "collection transforms before 'reduce' allocate an intermediate array — consider '.lazy'"),
      ]
    )
  }

  @Test func twoLinkChainBeforeSinglePassConsumerFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let ok = 1️⃣items.filter(isReady).map(\\.name).allSatisfy { $0.isEmpty }
      """,
      findings: [
        FindingSpec("1️⃣", message: "collection transforms before 'allSatisfy' allocate an intermediate array — consider '.lazy'"),
      ]
    )
  }

  @Test func joinedWithSeparatorFlaggedAndBareJoinedNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let names = 1️⃣users.map { $0.name }.joined(separator: ", ")
      let flat = users.map { $0.tags }.joined()
      """,
      findings: [
        FindingSpec("1️⃣", message: "collection transforms before 'joined' allocate an intermediate array — consider '.lazy'"),
      ]
    )
  }

  @Test func lazyChainBeforeSinglePassConsumerNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let minY = vertices.lazy.map { $0.y }.min()
      """,
      findings: []
    )
  }

  @Test func materializingConsumerNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let sorted = items.map(\\.id).sorted()
      let backwards = items.map(\\.id).reversed()
      """,
      findings: []
    )
  }

  @Test func uncalledConsumerNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let head = items.map(\\.id).first
      """,
      findings: []
    )
  }

  @Test func threeLinkChainBeforeConsumerReportedOnce() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let value = 1️⃣items.map(f).filter(p).compactMap(g).min()
      """,
      findings: [
        FindingSpec("1️⃣", message: "chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'"),
      ]
    )
  }

  @Test func consumerWithoutATransformNotFlagged() {
    assertLint(
      UseLazyForLongChainOps.self,
      """
      let minY = vertices.min()
      let ok = items.allSatisfy { $0.isReady }
      """,
      findings: []
    )
  }

  @Test func twoChainsAdjacentEachReportedOnce() {
    assertLint(
      UseLazyForLongChainOps.self,
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
