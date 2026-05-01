@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagForEachIDSelfInViewTests: RuleTesting {
  @Test func idSelfFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(items, id: 1️⃣\\.self) { item in
        Text(String(describing: item))
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'id: \\.self' is fragile — make the element 'Identifiable' or supply a stable id key path"),
      ]
    )
  }

  @Test func idKeyPathToPropertyNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(items, id: \\.id) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func noIdArgumentNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(items) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func nonForEachNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      List(items, id: \\.self) { item in
        Text(String(describing: item))
      }
      """,
      findings: []
    )
  }
}
