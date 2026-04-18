@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct StrongifiedSelfTests: RuleTesting {
  @Test func backtickSelfConvertedInGuard() {
    assertFormatting(
      NoBacktickedSelf.self,
      input: """
        { [weak self] in
            guard let 1️⃣`self` = self else { return }
        }
        """,
      expected: """
        { [weak self] in
            guard let self = self else { return }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove backticks around 'self' in optional binding"),
      ]
    )
  }

  @Test func backtickSelfConvertedInIf() {
    assertFormatting(
      NoBacktickedSelf.self,
      input: """
        { [weak self] in
            if let 1️⃣`self` = self { print(self) }
        }
        """,
      expected: """
        { [weak self] in
            if let self = self { print(self) }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove backticks around 'self' in optional binding"),
      ]
    )
  }

  @Test func nonConditionalBacktickSelfNotConverted() {
    // nonisolated(unsafe) let `self` = self is NOT an optional binding
    assertFormatting(
      NoBacktickedSelf.self,
      input: """
        let `self` = something
        """,
      expected: """
        let `self` = something
        """,
      findings: []
    )
  }

  @Test func selfWithoutBackticksNotFlagged() {
    assertFormatting(
      NoBacktickedSelf.self,
      input: """
        { [weak self] in
            guard let self = self else { return }
        }
        """,
      expected: """
        { [weak self] in
            guard let self = self else { return }
        }
        """,
      findings: []
    )
  }

  @Test func backtickSelfWithDifferentInitializerNotFlagged() {
    // `self` = somethingElse — not the strongify pattern
    assertFormatting(
      NoBacktickedSelf.self,
      input: """
        { [weak self] in
            guard let `self` = other else { return }
        }
        """,
      expected: """
        { [weak self] in
            guard let `self` = other else { return }
        }
        """,
      findings: []
    )
  }
}
