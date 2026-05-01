@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseToggleTests: RuleTesting {

  @Test func simpleToggle() {
    assertFormatting(
      UseToggle.self,
      input: """
        1️⃣isHidden = !isHidden
        """,
      expected: """
        isHidden.toggle()
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'toggle()' over assigning the negation"),
      ]
    )
  }

  @Test func memberAccessToggle() {
    assertFormatting(
      UseToggle.self,
      input: """
        1️⃣view.clipsToBounds = !view.clipsToBounds
        """,
      expected: """
        view.clipsToBounds.toggle()
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'toggle()' over assigning the negation"),
      ]
    )
  }

  @Test func mismatchedSidesNotChanged() {
    assertFormatting(
      UseToggle.self,
      input: """
        disconnected = !connected
        result = !result.toggle()
        view.clipsToBounds = !clipsToBounds
        """,
      expected: """
        disconnected = !connected
        result = !result.toggle()
        view.clipsToBounds = !clipsToBounds
        """,
      findings: []
    )
  }

  @Test func indentationPreserved() {
    assertFormatting(
      UseToggle.self,
      input: """
        func foo() {
            1️⃣abc = !abc
        }
        """,
      expected: """
        func foo() {
            abc.toggle()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'toggle()' over assigning the negation"),
      ]
    )
  }
}
