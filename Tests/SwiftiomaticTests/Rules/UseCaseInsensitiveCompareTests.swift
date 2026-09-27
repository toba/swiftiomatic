@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseCaseInsensitiveCompareTests: RuleTesting {
  private static let equality =
    "compare these strings with 'caseInsensitiveCompare(_:)' or 'compare(_:options:)' instead of converting both sides with 'lowercased()'"
  private static let search =
    "search with 'localizedStandardContains(_:)' or 'range(of:options:)' instead of converting both sides with 'lowercased()' before 'contains'"

  @Test func optionalChainInequalityInGuard() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      func f() {
        guard let repo = LocalCheckout.repository(at: root),
              1️⃣project.repoFullName?.lowercased() != repo.fullName.lowercased()
        else { return }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.equality)]
    )
  }

  @Test func inequalityInSingleLineGuard() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      func f() {
        guard 1️⃣moved.repoFullName?.lowercased() != ownerRepo.lowercased() else { return }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.equality)]
    )
  }

  @Test func uppercasedEquality() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      let same = 1️⃣a.uppercased() == b.uppercased()
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "compare these strings with 'caseInsensitiveCompare(_:)' or 'compare(_:options:)' instead of converting both sides with 'uppercased()'"
        )
      ]
    )
  }

  @Test func containsPrefixSuffix() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      let a = 1️⃣title.lowercased().contains(query.lowercased())
      let b = 2️⃣title.lowercased().hasPrefix(query.lowercased())
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.search),
        FindingSpec(
          "2️⃣",
          message: "search with 'localizedStandardContains(_:)' or 'range(of:options:)' instead of converting both sides with 'lowercased()' before 'hasPrefix'"
        ),
      ]
    )
  }

  @Test func mixedConversionsNotFlagged() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      let a = x.lowercased() == y.uppercased()
      let b = x.lowercased() == y
      let c = x.lowercased(with: locale) == y.lowercased(with: locale)
      """,
      findings: []
    )
  }

  @Test func storedConversionNotFlagged() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      let key = name.lowercased()
      if key == other.lowercased() { cache[key] = value }
      """,
      findings: []
    )
  }

  @Test func customLowercasedDeclarationNotFlagged() {
    assertLint(
      UseCaseInsensitiveCompare.self,
      """
      struct Tag {
        func lowercased() -> Tag { self }
      }
      let same = a.lowercased() == b.lowercased()
      """,
      findings: []
    )
  }
}
