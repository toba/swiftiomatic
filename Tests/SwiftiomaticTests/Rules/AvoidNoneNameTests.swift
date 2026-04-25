@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct AvoidNoneNameTests: RuleTesting {

  @Test func enumCaseNamedNone() {
    assertFormatting(
      AvoidNoneName.self,
      input: """
        enum E {
          case 1️⃣none
          case other
        }
        """,
      expected: """
        enum E {
          case none
          case other
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "avoid naming an enum case 'none' as it can conflict with 'Optional<T>.none'"
        ),
      ]
    )
  }

  @Test func staticMemberNamedNone() {
    assertFormatting(
      AvoidNoneName.self,
      input: """
        struct S {
          static let 1️⃣none = S()
          static var 2️⃣none2 = S()
        }
        class C {
          class var 3️⃣none: C { C() }
        }
        """,
      expected: """
        struct S {
          static let none = S()
          static var none2 = S()
        }
        class C {
          class var none: C { C() }
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "avoid naming a 'static' member 'none' as it can conflict with 'Optional<T>.none'"
        ),
        FindingSpec(
          "3️⃣",
          message: "avoid naming a 'class' member 'none' as it can conflict with 'Optional<T>.none'"
        ),
      ]
    )
  }

  @Test func enumCaseWithAssociatedValuesNotDiagnosed() {
    assertFormatting(
      AvoidNoneName.self,
      input: """
        enum E {
          case none(Any)
          case nonenone
          case _none
        }
        struct S {
          let none = S()
          var none2 = S()
        }
        """,
      expected: """
        enum E {
          case none(Any)
          case nonenone
          case _none
        }
        struct S {
          let none = S()
          var none2 = S()
        }
        """,
      findings: []
    )
  }
}
