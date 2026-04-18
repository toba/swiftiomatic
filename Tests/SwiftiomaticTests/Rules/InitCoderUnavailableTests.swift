@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct InitCoderUnavailableTests: RuleTesting {

  @Test func addsUnavailableToFatalErrorStub() {
    assertFormatting(
      InitCoderUnavailable.self,
      input: """
        class MyView: UIView {
          required 1️⃣init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      expected: """
        class MyView: UIView {
          @available(*, unavailable)
          required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add '@available(*, unavailable)' to this 'required init(coder:)' stub"),
      ]
    )
  }

  @Test func alreadyUnavailableUnchanged() {
    assertFormatting(
      InitCoderUnavailable.self,
      input: """
        class MyView: UIView {
          @available(*, unavailable)
          required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      expected: """
        class MyView: UIView {
          @available(*, unavailable)
          required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      findings: []
    )
  }

  @Test func nonFatalErrorBodyUnchanged() {
    assertFormatting(
      InitCoderUnavailable.self,
      input: """
        class MyView: UIView {
          required init?(coder: NSCoder) {
            super.init(coder: coder)
          }
        }
        """,
      expected: """
        class MyView: UIView {
          required init?(coder: NSCoder) {
            super.init(coder: coder)
          }
        }
        """,
      findings: []
    )
  }

  @Test func nonRequiredInitUnchanged() {
    assertFormatting(
      InitCoderUnavailable.self,
      input: """
        class MyView: UIView {
          init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      expected: """
        class MyView: UIView {
          init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      findings: []
    )
  }

  @Test func nonFailableInit() {
    assertFormatting(
      InitCoderUnavailable.self,
      input: """
        class MyView: UIView {
          required 1️⃣init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      expected: """
        class MyView: UIView {
          @available(*, unavailable)
          required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "add '@available(*, unavailable)' to this 'required init(coder:)' stub"),
      ]
    )
  }

  @Test func multipleStatementsUnchanged() {
    assertFormatting(
      InitCoderUnavailable.self,
      input: """
        class MyView: UIView {
          required init?(coder: NSCoder) {
            print("about to crash")
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      expected: """
        class MyView: UIView {
          required init?(coder: NSCoder) {
            print("about to crash")
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      findings: []
    )
  }
}
