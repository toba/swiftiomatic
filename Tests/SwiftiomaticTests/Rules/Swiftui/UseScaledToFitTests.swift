@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseScaledToFitTests: RuleTesting {
  @Test func memberFitBecomesScaledToFit() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.1️⃣aspectRatio(contentMode: .fit)
        """,
      expected: """
        view.scaledToFit()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.scaledToFit()' instead of '.aspectRatio(contentMode: .fit)'"
        ),
      ]
    )
  }

  @Test func memberFillBecomesScaledToFill() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.1️⃣aspectRatio(contentMode: .fill)
        """,
      expected: """
        view.scaledToFill()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.scaledToFill()' instead of '.aspectRatio(contentMode: .fill)'"
        ),
      ]
    )
  }

  @Test func explicitContentModeFitBecomesScaledToFit() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.1️⃣aspectRatio(contentMode: ContentMode.fit)
        """,
      expected: """
        view.scaledToFit()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.scaledToFit()' instead of '.aspectRatio(contentMode: .fit)'"
        ),
      ]
    )
  }

  @Test func explicitContentModeFillBecomesScaledToFill() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.1️⃣aspectRatio(contentMode: ContentMode.fill)
        """,
      expected: """
        view.scaledToFill()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.scaledToFill()' instead of '.aspectRatio(contentMode: .fill)'"
        ),
      ]
    )
  }

  @Test func bareCallBecomesScaledToFit() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        1️⃣aspectRatio(contentMode: .fit)
        """,
      expected: """
        scaledToFit()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.scaledToFit()' instead of '.aspectRatio(contentMode: .fit)'"
        ),
      ]
    )
  }

  @Test func chainedInViewBodyRewrites() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        Image("x").resizable().1️⃣aspectRatio(contentMode: .fit)
        """,
      expected: """
        Image("x").resizable().scaledToFit()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.scaledToFit()' instead of '.aspectRatio(contentMode: .fit)'"
        ),
      ]
    )
  }

  // MARK: - Non-triggering

  @Test func ratioArgumentNotFlagged() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.aspectRatio(ratio, contentMode: .fit)
        """,
      expected: """
        view.aspectRatio(ratio, contentMode: .fit)
        """,
      findings: []
    )
  }

  @Test func nonConstantContentModeNotFlagged() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.aspectRatio(contentMode: contentMode)
        """,
      expected: """
        view.aspectRatio(contentMode: contentMode)
        """,
      findings: []
    )
  }

  @Test func ternaryContentModeNotFlagged() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.aspectRatio(contentMode: shouldFit ? .fit : .fill)
        """,
      expected: """
        view.aspectRatio(contentMode: shouldFit ? .fit : .fill)
        """,
      findings: []
    )
  }

  @Test func customEnumBaseNotFlagged() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.aspectRatio(contentMode: CustomMode.fit)
        """,
      expected: """
        view.aspectRatio(contentMode: CustomMode.fit)
        """,
      findings: []
    )
  }

  @Test func alreadyScaledToFitNotFlagged() {
    assertFormatting(
      UseScaledToFit.self,
      input: """
        view.scaledToFit()
        """,
      expected: """
        view.scaledToFit()
        """,
      findings: []
    )
  }
}
