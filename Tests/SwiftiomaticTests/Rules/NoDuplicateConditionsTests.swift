@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoDuplicateConditionsTests: RuleTesting {
  @Test func ifElseIfDuplicates() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if 1️⃣x < 5 {
        foo()
      } else if y == "s" {
        bar()
      } else if 2️⃣x < 5 {
        baz()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
        FindingSpec("2️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
      ]
    )
  }

  @Test func threeWayDuplicate() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if 1️⃣x < 5 {}
      else if 2️⃣x < 5 {}
      else if 3️⃣x < 5 {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
        FindingSpec("2️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
        FindingSpec("3️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
      ]
    )
  }

  @Test func conditionListOrderInsensitive() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if 1️⃣x < 5, y == "s" {
        foo()
      } else if x < 10 {
        bar()
      } else if 2️⃣y == "s", x < 5 {
        baz()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
        FindingSpec("2️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
      ]
    )
  }

  @Test func optionalBindingDuplicate() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if 1️⃣let xyz = maybeXyz {
        foo()
      } else if 2️⃣let xyz = maybeXyz {
        bar()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
        FindingSpec("2️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
      ]
    )
  }

  @Test func patternMatchDuplicate() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if 1️⃣case .p = x {
        foo()
      } else if 2️⃣case .p = x {
        bar()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
        FindingSpec("2️⃣", message: "this condition appears multiple times in the same if/else-if chain"),
      ]
    )
  }

  @Test func separateIfStatementsDoNotTrigger() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if x < 5 {
        foo()
      }
      if x < 5 {
        bar()
      }
      """,
      findings: []
    )
  }

  @Test func differentConditionsDoNotTrigger() {
    assertLint(
      NoDuplicateConditions.self,
      """
      if x < 5 {
        foo()
      } else if y == "s" {
        bar()
      }
      """,
      findings: []
    )
  }

  @Test func switchCaseDuplicates() {
    assertLint(
      NoDuplicateConditions.self,
      """
      switch x {
      case 1️⃣"a", "b":
        foo()
      case "c", 2️⃣"a":
        bar()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "this case appears multiple times in the switch"),
        FindingSpec("2️⃣", message: "this case appears multiple times in the switch"),
      ]
    )
  }

  @Test func switchCaseWithMatchingWhereClauseDuplicates() {
    assertLint(
      NoDuplicateConditions.self,
      """
      switch x {
      case 1️⃣"a" where y == "s":
        foo()
      case 2️⃣"a" where y == "s":
        bar()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "this case appears multiple times in the switch"),
        FindingSpec("2️⃣", message: "this case appears multiple times in the switch"),
      ]
    )
  }

  @Test func switchCaseWithDifferentWhereClauseDoesNotTrigger() {
    assertLint(
      NoDuplicateConditions.self,
      """
      switch x {
      case "a" where y == "s":
        foo()
      case "a" where y == "t":
        bar()
      }
      """,
      findings: []
    )
  }
}
