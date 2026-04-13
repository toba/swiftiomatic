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

  /// Rules A–M (reduces parameterized test size to avoid SIGBUS on CI runners).
  static var firstHalf: [RuleCase] {
    testable.filter { $0.ruleType.identifier < "n" }
  }

  /// Rules N–Z.
  static var secondHalf: [RuleCase] {
    testable.filter { $0.ruleType.identifier >= "n" }
  }
}

// Split into two suites to avoid SIGBUS (signal 10) on CI runners.
// A single ~300-case parameterized test crashes the swift-testing helper
// process mid-run due to memory pressure (see 2sx-3uj).

@Suite(.rulesRegistered, .serialized)
struct RuleExampleTestsAM {
  @Test("Rule examples validate (A–M)", arguments: RuleCase.firstHalf)
  func verifyExamples(_ rule: RuleCase) async {
    await verifyRule(
      rule.ruleType,
      skipCommentTests: true,
      skipStringTests: true,
      skipDisableCommandTests: true,
      shouldTestMultiByteOffsets: false,
      testShebang: false,
    )
    // Prevent memory buildup across parameterized cases (CI SIGBUS).
    SwiftSource.clearCaches()
  }
}

@Suite(.rulesRegistered, .serialized)
struct RuleExampleTestsNZ {
  @Test("Rule examples validate (N–Z)", arguments: RuleCase.secondHalf)
  func verifyExamples(_ rule: RuleCase) async {
    await verifyRule(
      rule.ruleType,
      skipCommentTests: true,
      skipStringTests: true,
      skipDisableCommandTests: true,
      shouldTestMultiByteOffsets: false,
      testShebang: false,
    )
    SwiftSource.clearCaches()
  }
}
