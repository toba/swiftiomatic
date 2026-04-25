@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireFatalErrorMessageTests: RuleTesting {

  @Test func emptyFatalError() {
    assertFormatting(
      RequireFatalErrorMessage.self,
      input: """
        func foo() {
          1️⃣fatalError()
        }
        """,
      expected: """
        func foo() {
          fatalError()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'fatalError' should include a descriptive message"),
      ]
    )
  }

  @Test func fatalErrorWithEmptyString() {
    assertFormatting(
      RequireFatalErrorMessage.self,
      input: """
        func foo() {
          1️⃣fatalError("")
        }
        """,
      expected: """
        func foo() {
          fatalError("")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "'fatalError' should include a descriptive message"),
      ]
    )
  }

  @Test func fatalErrorWithMessageNotDiagnosed() {
    assertFormatting(
      RequireFatalErrorMessage.self,
      input: """
        func foo() {
          fatalError("unreachable")
        }
        func bar(_ x: String) {
          fatalError(x)
        }
        """,
      expected: """
        func foo() {
          fatalError("unreachable")
        }
        func bar(_ x: String) {
          fatalError(x)
        }
        """,
      findings: []
    )
  }
}
