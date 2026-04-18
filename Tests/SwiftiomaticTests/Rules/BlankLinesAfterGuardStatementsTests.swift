@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesAfterGuardStatementsTests: RuleTesting {

  @Test func removesBlanksBetweenConsecutiveGuards() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            guard let one = test.one else {
                return
            }

            1️⃣guard let two = test.two else {
                return
            }


            2️⃣guard let three = test.three else {
                return
            }
        }
        """,
      expected: """
        func test() {
            guard let one = test.one else {
                return
            }
            guard let two = test.two else {
                return
            }
            guard let three = test.three else {
                return
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank line between consecutive guard statements"),
        FindingSpec("2️⃣", message: "remove blank line between consecutive guard statements"),
      ]
    )
  }

  @Test func insertsBlankAfterLastGuard() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            1️⃣guard let one = test.one else {
                return
            }
            let x = test()
        }
        """,
      expected: """
        func test() {
            guard let one = test.one else {
                return
            }

            let x = test()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after guard statement"),
      ]
    )
  }

  @Test func insertsBlankAfterSingleLineGuard() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            1️⃣guard let one = test.one else { return }
            let x = test()
        }
        """,
      expected: """
        func test() {
            guard let one = test.one else { return }

            let x = test()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after guard statement"),
      ]
    )
  }

  @Test func alreadyCorrectNoChange() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            guard let one = test.one else { return }
            guard let two = test.two else { return }

            let x = test()
        }
        """,
      expected: """
        func test() {
            guard let one = test.one else { return }
            guard let two = test.two else { return }

            let x = test()
        }
        """,
      findings: []
    )
  }

  @Test func guardFollowedByIfStatement() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            1️⃣guard let something = test.something else {
                return
            }
            if someone == someoneElse {
                print("hello")
            }
        }
        """,
      expected: """
        func test() {
            guard let something = test.something else {
                return
            }

            if someone == someoneElse {
                print("hello")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after guard statement"),
      ]
    )
  }

  @Test func nestedGuard() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            guard let one = test.one else {
                1️⃣guard let two = test.two() else {
                    return
                }
                return
            }
        }
        """,
      expected: """
        func test() {
            guard let one = test.one else {
                guard let two = test.two() else {
                    return
                }

                return
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after guard statement"),
      ]
    )
  }

  @Test func guardAtEndOfScope() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            guard let one = test.one else {
                return
            }
        }
        """,
      expected: """
        func test() {
            guard let one = test.one else {
                return
            }
        }
        """,
      findings: []
    )
  }

  @Test func guardsWithCommentsBetween() {
    assertFormatting(
      BlankLinesAfterGuardStatements.self,
      input: """
        func test() {
            1️⃣guard let somethingTwo = test.somethingTwo else {
                return
            }
            // commentOne
            2️⃣guard let somethingOne = test.somethingOne else {
                return
            }
            // commentTwo
            let something = xxx
        }
        """,
      expected: """
        func test() {
            guard let somethingTwo = test.somethingTwo else {
                return
            }

            // commentOne
            guard let somethingOne = test.somethingOne else {
                return
            }

            // commentTwo
            let something = xxx
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after guard statement"),
        FindingSpec("2️⃣", message: "insert blank line after guard statement"),
      ]
    )
  }
}
