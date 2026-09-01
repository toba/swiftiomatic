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

  /// A known rule the configuration disables is NOT flagged. The rule never runs, so the directive
  /// may still be a valid hedge for a run that enables it.
  @Test func testKnownRuleNeverQueriedNotFlagged() {
    var config = Configuration.forTesting
    config.disableAllRules()
    config.enableRule(named: "flagUnusedIgnoreDirective")
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      // sm:ignore:next noForceCast
      let x = obj as! Foo
      """,
      findings: [],
      configuration: config
    )
  }

  /// An active rule that the pipelines dispatch is flagged even when the file holds no node of the
  /// kind it visits. `UseUnavailableNotFatalError` transforms `IfExprSyntax` alone, so a file with
  /// no `if` never queries the mask for it, yet the directive still suppresses nothing.
  @Test func testActiveRuleWithNoMatchingNodeIsFlagged() {
    var config = Configuration.forTesting
    config.disableAllRules()
    config.enableRule(named: "flagUnusedIgnoreDirective")
    config.enableRule(named: "useUnavailableNotFatalError")
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      1️⃣// sm:ignore:next useUnavailableNotFatalError
      func aliased() -> Int {
        fatalError("export API")
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "'// sm:ignore' lists 'useUnavailableNotFatalError' but it suppresses nothing here; "
            + "remove it"
        ),
      ],
      configuration: config
    )
  }

  /// A rule the layout stage owns is never flagged during a lint run. `ReflowComments` reaches
  /// source only from the pretty printer, which `sm lint` does not run, so the directive may still
  /// suppress a rewrite that a format run would make.
  @Test func testLayoutStageRuleNotFlagged() {
    var config = Configuration.forTesting
    config.disableAllRules()
    config.enableRule(named: "flagUnusedIgnoreDirective")
    config.enableRule(named: "reflowComments")
    assertLint(
      FlagUnusedIgnoreDirective.self,
      """
      // sm:ignore:next reflowComments
      let x = 1
      """,
      findings: [],
      configuration: config
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
