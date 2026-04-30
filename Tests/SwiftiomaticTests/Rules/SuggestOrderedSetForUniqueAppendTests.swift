@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct SuggestOrderedSetForUniqueAppendTests: RuleTesting {
  @Test func bareIdentifierContainsAppend() {
    assertLint(
      SuggestOrderedSetForUniqueAppend.self,
      """
      func add(_ x: Int) {
        1️⃣if !values.contains(x) {
          values.append(x)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'!contains' + 'append' guards uniqueness in O(n) — consider 'OrderedSet' from swift-collections"),
      ]
    )
  }

  @Test func selfMemberContainsAppend() {
    assertLint(
      SuggestOrderedSetForUniqueAppend.self,
      """
      func add(_ x: Int) {
        1️⃣if !self.values.contains(x) {
          self.values.append(x)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'!contains' + 'append' guards uniqueness in O(n) — consider 'OrderedSet' from swift-collections"),
      ]
    )
  }

  @Test func differentArgumentNotFlagged() {
    assertLint(
      SuggestOrderedSetForUniqueAppend.self,
      """
      func add(_ x: Int, _ y: Int) {
        if !values.contains(x) {
          values.append(y)
        }
      }
      """,
      findings: []
    )
  }

  @Test func differentCollectionNotFlagged() {
    assertLint(
      SuggestOrderedSetForUniqueAppend.self,
      """
      func add(_ x: Int) {
        if !a.contains(x) {
          b.append(x)
        }
      }
      """,
      findings: []
    )
  }

  @Test func multiStatementBodyNotFlagged() {
    assertLint(
      SuggestOrderedSetForUniqueAppend.self,
      """
      func add(_ x: Int) {
        if !values.contains(x) {
          values.append(x)
          print("added")
        }
      }
      """,
      findings: []
    )
  }

  @Test func extraConditionsNotFlagged() {
    assertLint(
      SuggestOrderedSetForUniqueAppend.self,
      """
      func add(_ x: Int) {
        if !values.contains(x), x > 0 {
          values.append(x)
        }
      }
      """,
      findings: []
    )
  }
}
