import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagSortAfterAppendTests: RuleTesting {
  private static func message(_ receiver: String) -> String {
    "consider an insert at the sorted index of '\(receiver)'. A 'sort' after one 'append' sorts the whole collection again"
  }

  @Test func sortAfterOneAppendFlagged() {
    assertLint(
      FlagSortAfterAppend.self,
      """
      func add(_ tag: Tag) {
        tags.append(tag)
        1️⃣tags.sort()
        selection = tag
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("tags"))]
    )
  }

  @Test func sortByAndMemberReceiverFlagged() {
    assertLint(
      FlagSortAfterAppend.self,
      """
      func add(_ item: Item) {
        self.items.append(item)
        1️⃣self.items.sort { $0.name < $1.name }
      }
      func insert(_ row: Row) {
        rows.append(row)
        2️⃣rows.sort(by: <)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("self.items")),
        FindingSpec("2️⃣", message: Self.message("rows")),
      ]
    )
  }

  @Test func sortInLoopBodyFlagged() {
    assertLint(
      FlagSortAfterAppend.self,
      """
      for value in values {
        sorted.append(value)
        1️⃣sorted.sort()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("sorted"))]
    )
  }

  @Test func batchSortAfterLoopNotFlagged() {
    assertLint(
      FlagSortAfterAppend.self,
      """
      var results: [Result] = []
      for value in values {
        results.append(value)
      }
      results.sort()
      """,
      findings: []
    )
  }

  @Test func nearMissesNotFlagged() {
    assertLint(
      FlagSortAfterAppend.self,
      """
      func run() {
        tags.append(contentsOf: more)
        tags.sort()
        names.append(name)
        other.sort()
        list.append(item)
        count += 1
        list.sort()
        let ordered = items.sorted()
        items.append(x)
        _ = items.sorted()
      }
      """,
      findings: []
    )
  }
}
