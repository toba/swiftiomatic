@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagUnusedIgnoreDirectiveTests: RuleTesting {
  /// A typo'd rule name in `// sm:ignore` can never match a real rule's hits, so it's flagged.
  @Test func testFlagsTypoRuleName() {
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      1️⃣// sm:ignore:next nonexistentRule
      let x = 1
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "'// sm:ignore' lists 'nonexistentRule' but it suppresses nothing here; remove it"
        ),
      ]
    )
  }

  /// Bare `// sm:ignore` (all rules) is never flagged — proving "no rule fired" requires running
  /// every rule against every node, which is expensive and noisy.
  @Test func testIgnoresBareDirective() {
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      // sm:ignore:next
      let x = 1
      """,
      findings: []
    )
  }

  /// Trailing `// sm:ignore` on the same line as code: typo'd name still flagged.
  @Test func testFlagsTypoOnTrailing() {
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      let x = 1 1️⃣// sm:ignore typoRule
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "'// sm:ignore' lists 'typoRule' but it suppresses nothing here; remove it"
        ),
      ]
    )
  }

  /// Mix of valid (suppressing) and typo'd names: only the unused name is flagged.
  @Test func testPartialUseFlagsOnlyUnused() {
    // `useForLoopNotForEach` will suppress the `.forEach` finding via the directive (real hit);
    // `typoRule` matches nothing → flagged.
    var config = Configuration.forTesting
    config.disableAllRules()
    config.enableRule(named: "flagUnusedIgnoreDirective")
    config.enableRule(named: "useForLoopNotForEach")
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      1️⃣// sm:ignore:next useForLoopNotForEach, typoRule
      values.forEach { print($0) }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "'// sm:ignore' lists 'typoRule' but it suppresses nothing here; remove it"
        ),
      ],
      configuration: config
    )
  }
}
