@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferToggleTests: RuleTesting {

  @Test func simpleToggle() {
    assertFormatting(
      PreferToggle.self,
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
      PreferToggle.self,
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
      PreferToggle.self,
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
      PreferToggle.self,
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
