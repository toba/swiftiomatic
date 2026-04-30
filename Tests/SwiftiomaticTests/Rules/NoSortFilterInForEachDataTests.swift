@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoSortFilterInForEachDataTests: RuleTesting {
  @Test func sortedInData() {
    assertLint(
      NoSortFilterInForEachData.self,
      """
      ForEach(1️⃣items.sorted()) { item in
        Text(item.name)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'.sorted' in 'ForEach' data is recomputed on every render — hoist into a stored or computed property"),
      ]
    )
  }

  @Test func filterInData() {
    assertLint(
      NoSortFilterInForEachData.self,
      """
      ForEach(1️⃣items.filter { $0.isEnabled }) { item in
        Text(item.name)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'.filter' in 'ForEach' data is recomputed on every render — hoist into a stored or computed property"),
      ]
    )
  }

  @Test func mapInData() {
    assertLint(
      NoSortFilterInForEachData.self,
      """
      ForEach(1️⃣items.map(\\.id), id: \\.self) { id in
        Text(String(id))
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'.map' in 'ForEach' data is recomputed on every render — hoist into a stored or computed property"),
      ]
    )
  }

  @Test func plainCollectionNotFlagged() {
    assertLint(
      NoSortFilterInForEachData.self,
      """
      ForEach(items) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func memberAccessNotFlagged() {
    assertLint(
      NoSortFilterInForEachData.self,
      """
      ForEach(model.items) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }
}
