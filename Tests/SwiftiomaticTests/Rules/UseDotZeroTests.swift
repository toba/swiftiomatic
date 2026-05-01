@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseDotZeroTests: RuleTesting {

  @Test func cgPointZero() {
    assertFormatting(
      UseDotZero.self,
      input: """
        let p = 1️⃣CGPoint(x: 0, y: 0)
        """,
      expected: """
        let p = CGPoint.zero
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'CGPoint.zero' over an all-zero initializer"),
      ]
    )
  }

  @Test func cgRectZero() {
    assertFormatting(
      UseDotZero.self,
      input: """
        let r = 1️⃣CGRect(x: 0, y: 0, width: 0, height: 0)
        """,
      expected: """
        let r = CGRect.zero
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'CGRect.zero' over an all-zero initializer"),
      ]
    )
  }

  @Test func cgSizeZeroFloatLiterals() {
    assertFormatting(
      UseDotZero.self,
      input: """
        let s = 1️⃣CGSize(width: 0.0, height: 0.000)
        """,
      expected: """
        let s = CGSize.zero
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'CGSize.zero' over an all-zero initializer"),
      ]
    )
  }

  @Test func uIEdgeInsetsZero() {
    assertFormatting(
      UseDotZero.self,
      input: """
        let i = 1️⃣UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        """,
      expected: """
        let i = UIEdgeInsets.zero
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'UIEdgeInsets.zero' over an all-zero initializer"),
      ]
    )
  }

  @Test func nonZeroValuesNotChanged() {
    assertFormatting(
      UseDotZero.self,
      input: """
        let a = CGPoint(x: 0, y: -1)
        let b = CGSize(width: 2, height: 4)
        let c = CGRect(x: 0, y: 0, width: 0, height: 1)
        let d = CGVector(dx: -5, dy: 0)
        let e = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
        """,
      expected: """
        let a = CGPoint(x: 0, y: -1)
        let b = CGSize(width: 2, height: 4)
        let c = CGRect(x: 0, y: 0, width: 0, height: 1)
        let d = CGVector(dx: -5, dy: 0)
        let e = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
        """,
      findings: []
    )
  }

  @Test func nsPointZero() {
    assertFormatting(
      UseDotZero.self,
      input: """
        let p = 1️⃣NSPoint(x: 0, y: 0)
        """,
      expected: """
        let p = NSPoint.zero
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'NSPoint.zero' over an all-zero initializer"),
      ]
    )
  }
}
