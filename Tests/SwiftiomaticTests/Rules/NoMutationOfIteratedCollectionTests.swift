@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoMutationOfIteratedCollectionTests: RuleTesting {
  @Test func removeAtOnIteratedArray() {
    assertLint(
      NoMutationOfIteratedCollection.self,
      """
      for x in items {
        if x.shouldDelete {
          1️⃣items.remove(at: 0)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'remove' mutates the collection currently being iterated — undefined behavior"),
      ]
    )
  }

  @Test func appendOnIteratedArray() {
    assertLint(
      NoMutationOfIteratedCollection.self,
      """
      for x in items {
        1️⃣items.append(x)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'append' mutates the collection currently being iterated — undefined behavior"),
      ]
    )
  }

  @Test func selfMemberIteratedCollection() {
    assertLint(
      NoMutationOfIteratedCollection.self,
      """
      for x in self.items {
        1️⃣self.items.removeAll()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'removeAll' mutates the collection currently being iterated — undefined behavior"),
      ]
    )
  }

  @Test func mutationOfDifferentCollectionNotFlagged() {
    assertLint(
      NoMutationOfIteratedCollection.self,
      """
      for x in items {
        result.append(x)
      }
      """,
      findings: []
    )
  }

  @Test func nonMutatingCallsNotFlagged() {
    assertLint(
      NoMutationOfIteratedCollection.self,
      """
      for x in items {
        _ = items.contains(x)
        _ = items.first
      }
      """,
      findings: []
    )
  }

  @Test func multipleMutationsFlaggedSeparately() {
    assertLint(
      NoMutationOfIteratedCollection.self,
      """
      for x in items {
        1️⃣items.append(x)
        2️⃣items.remove(at: 0)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'append' mutates the collection currently being iterated — undefined behavior"),
        FindingSpec("2️⃣", message: "'remove' mutates the collection currently being iterated — undefined behavior"),
      ]
    )
  }
}
