import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

/// Wraps a rule metatype so it can be used as a `@Test(arguments:)` parameter.
struct RuleCase: Sendable, CustomTestStringConvertible {
  let ruleType: any Rule.Type
  var testDescription: String { ruleType.identifier }

  /// All registered rules that have examples and can be tested without
  /// SourceKit, compiler arguments, or cross-file collection.
  static var testable: [RuleCase] {
    _ = _testSetup
    return RuleRegistry.shared.list.rules.values
      .filter { !$0.requiresSourceKit }
      .filter { !$0.requiresCompilerArguments }
      .filter { !$0.isCrossFile }
      .filter { !$0.requiresFileOnDisk }
      .filter { !["blanket_disable_command", "redundant_disable_command", "invalid_command"].contains($0.identifier) }
      .filter { !$0.nonTriggeringExamples.isEmpty || !$0.triggeringExamples.isEmpty }
      .sorted { $0.identifier < $1.identifier }
      .map { RuleCase(ruleType: $0) }
  }
}

@Suite(.rulesRegistered, .serialized)
struct RuleExampleTests {
  @Test("Rule examples validate", arguments: RuleCase.testable)
  func verifyExamples(_ rule: RuleCase) async {
    // Only run core triggering/non-triggering checks in the batch.
    // Full variant tests (comment/string wrapping, disable commands,
    // multi-byte offsets, severity elevation) are covered by dedicated
    // per-rule test files and the individual --filter runs.
    await verifyRule(
      rule.ruleType,
      skipCommentTests: true,
      skipStringTests: true,
      skipDisableCommandTests: true,
      shouldTestMultiByteOffsets: false,
      testShebang: false,
    )
  }
}
