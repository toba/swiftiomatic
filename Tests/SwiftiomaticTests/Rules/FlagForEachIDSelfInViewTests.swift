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

  @Test func compoundKeyPathNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(Array(tags.enumerated()), id: \\.element.id) { index, tag in
        Text(tag.name)
      }
      """,
      findings: []
    )
  }

  @Test func indicesWithIdSelfNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(citations.indices, id: \\.self) { index in
        Text("\\(index)")
      }
      """,
      findings: []
    )
  }

  @Test func halfOpenRangeWithIdSelfNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(0..<count, id: \\.self) { index in
        Text("\\(index)")
      }
      """,
      findings: []
    )
  }

  @Test func closedRangeWithIdSelfNotFlagged() {
    assertLint(
      FlagForEachIDSelfInView.self,
      """
      ForEach(1...n, id: \\.self) { index in
        Text("\\(index)")
      }
      """,
      findings: []
    )
  }
}
