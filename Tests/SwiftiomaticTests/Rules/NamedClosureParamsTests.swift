@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NamedClosureParamsTests: RuleTesting {

  @Test func dollarParamInMultilineClosure() {
    assertFormatting(
      NamedClosureParams.self,
      input: """
        closure {
            print(1️⃣$0)
        }
        """,
      expected: """
        closure {
            print($0)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use a named parameter instead of '$0' in this multi-line closure"),
      ]
    )
  }

  @Test func dollarParamInSingleLineClosureAllowed() {
    assertFormatting(
      NamedClosureParams.self,
      input: """
        closure { $0 }
        closure { print($0) }
        items.map { $0.name }
        """,
      expected: """
        closure { $0 }
        closure { print($0) }
        items.map { $0.name }
        """,
      findings: []
    )
  }

  @Test func nestedSingleLineInsideMultilineNotDiagnosed() {
    // The inner closure is single-line, so $0 there is fine.
    assertFormatting(
      NamedClosureParams.self,
      input: """
        closure { arg in
            nestedClosure { $0 + arg }
        }
        """,
      expected: """
        closure { arg in
            nestedClosure { $0 + arg }
        }
        """,
      findings: []
    )
  }

  @Test func multipleDollarsDiagnosed() {
    assertFormatting(
      NamedClosureParams.self,
      input: """
        closure {
            let a = 1️⃣$0
            let b = 2️⃣$1
        }
        """,
      expected: """
        closure {
            let a = $0
            let b = $1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use a named parameter instead of '$0' in this multi-line closure"),
        FindingSpec("2️⃣", message: "use a named parameter instead of '$1' in this multi-line closure"),
      ]
    )
  }
}
