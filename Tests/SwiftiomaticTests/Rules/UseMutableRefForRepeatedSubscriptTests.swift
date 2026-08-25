@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseMutableRefForRepeatedSubscriptTests: RuleTesting {
  private static func message(_ base: String, _ count: Int) -> String {
    "'\(base)[i]' is subscripted \(count) times in this loop body — bind it once with 'MutableRef(&\(base)[i])' (SE-0519) so the element is mutated in place"
  }

  @Test func repeatedSubscriptFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func normalize(_ elements: inout [Element]) {
        1️⃣for i in elements.indices {
          elements[i].leadingTrivia = []
          elements[i].key = elements[i].key.trimmed
          elements[i].value = elements[i].value.trimmed
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("elements", 5))]
    )
  }

  @Test func threeSubscriptsFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func normalize(_ xs: inout [Element]) {
        1️⃣for i in xs.indices {
          xs[i].a = 0
          xs[i].b = 0
          xs[i].c = 0
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("xs", 3))]
    )
  }

  @Test func twoSubscriptsNotFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func normalize(_ xs: inout [Element]) {
        for i in xs.indices {
          xs[i].a = 0
          xs[i].b = 0
        }
      }
      """,
      findings: []
    )
  }

  @Test func copyOutCopyBackNotFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func normalize(_ xs: inout [Element]) {
        for i in xs.indices {
          var element = xs[i]
          element.a = 0
          element.b = 0
          xs[i] = element
        }
      }
      """,
      findings: []
    )
  }

  @Test func differentIndexNotFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func swapEnds(_ xs: inout [Element]) {
        for i in xs.indices {
          xs[i].a = xs[0].a
          xs[i].b = xs[1].b
        }
      }
      """,
      findings: []
    )
  }

  @Test func readOnlyLoopNotFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func total(_ xs: [Element]) -> Int {
        var sum = 0
        for i in xs.indices {
          sum += xs[i].a
          sum += xs[i].b
          sum += xs[i].c
        }
        return sum
      }
      """,
      findings: []
    )
  }

  @Test func differentBasesNotFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func merge(_ xs: inout [Element], _ ys: inout [Element]) {
        for i in xs.indices {
          xs[i].a = 0
          ys[i].a = 0
          xs[i].b = 0
        }
      }
      """,
      findings: []
    )
  }

  @Test func mutableRefFormNotFlagged() {
    assertLint(
      UseMutableRefForRepeatedSubscript.self,
      """
      func normalize(_ xs: inout [Element]) {
        for i in xs.indices {
          var element = MutableRef(&xs[i])
          element.value.a = 0
          element.value.b = 0
          element.value.c = 0
        }
      }
      """,
      findings: []
    )
  }
}
