import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct EmptyFileTests {
  var collectedLinter: CollectedLinter!
  var ruleStorage: RuleStorage!

  @Test(
    .disabled("setUp() not converted from XCTest — collectedLinter/ruleStorage uninitialized"),
  )
  func shouldLintEmptyFileRespectedDuringLint() {
    let ruleViolations = collectedLinter.ruleViolations(using: ruleStorage)
    #expect(ruleViolations.count == 1)
    #expect(ruleViolations.first?.ruleIdentifier == "rule_mock<LintEmptyFiles>")
  }

  @Test(
    .disabled("setUp() not converted from XCTest — collectedLinter/ruleStorage uninitialized"),
  )
  func shouldLintEmptyFileRespectedDuringCorrect() {
    let corrections = collectedLinter.correct(using: ruleStorage)
    #expect(corrections == ["rule_mock<LintEmptyFiles>": 1])
  }
}

private protocol ShouldLintEmptyFilesProtocol {
  static var shouldLintEmptyFiles: Bool { get }
}

private struct LintEmptyFiles: ShouldLintEmptyFilesProtocol {
  static var shouldLintEmptyFiles: Bool { true }
}

private struct DontLintEmptyFiles: ShouldLintEmptyFilesProtocol {
  static var shouldLintEmptyFiles: Bool { false }
}

private struct RuleMock<ShouldLintEmptyFiles: ShouldLintEmptyFilesProtocol>: Rule {
  var options = SeverityOption<Self>(.warning)

  static var id: String { "rule_mock<\(ShouldLintEmptyFiles.self)>" }
  static var name: String { "" }
  static var summary: String { "" }
  static var deprecatedAliases: Set<String> { ["mock"] }

  var shouldLintEmptyFiles: Bool {
    ShouldLintEmptyFiles.shouldLintEmptyFiles
  }

  func validate(file: SwiftSource) -> [RuleViolation] {
    [RuleViolation(ruleType: Self.self, location: Location(file: file.path))]
  }

  func correct(file _: SwiftSource) -> Int {
    1
  }
}
