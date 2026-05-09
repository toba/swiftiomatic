@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagForEachOverIndicesTests: RuleTesting {
  private static let message =
    "'ForEach' over indices loses row identity on insert/remove — use 'ForEach(Array(<collection>.enumerated()), id: \\.element.id)'"

  @Test func indicesWithIdSelfFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(1️⃣items.indices, id: \\.self) { i in
        Text("\\(i)")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func indicesWithoutIdFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(1️⃣items.indices) { i in
        Text("\\(i)")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func halfOpenRangeWithIdSelfFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(1️⃣0..<items.count, id: \\.self) { i in
        Text("\\(i)")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func halfOpenRangeWithoutIdFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(1️⃣0..<n) { i in
        Text("\\(i)")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func closedRangeFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(1️⃣0...9) { i in
        Text("\\(i)")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func rangeInitFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(1️⃣Range(0..<n)) { i in
        Text("\\(i)")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func elementCollectionWithIdSelfNotFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(items, id: \\.self) { item in
        Text(String(describing: item))
      }
      """,
      findings: []
    )
  }

  @Test func plainElementCollectionNotFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(items) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func enumeratedNotFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      ForEach(Array(tags.enumerated()), id: \\.element.id) { index, tag in
        Text(tag.name)
      }
      """,
      findings: []
    )
  }

  @Test func nonForEachNotFlagged() {
    assertLint(
      FlagForEachOverIndices.self,
      """
      List(items.indices, id: \\.self) { i in
        Text("\\(i)")
      }
      """,
      findings: []
    )
  }
}
