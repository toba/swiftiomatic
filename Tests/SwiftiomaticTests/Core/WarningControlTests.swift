import Foundation
@testable import SwiftiomaticKit
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import Testing

/// Verifies that Swift's first-party `@warn(<group>, as: …)` attribute
/// (renamed `@diagnose` in newer swift-syntax) is honoured by Swiftiomatic
/// as a per-region severity override and suppression mechanism.
///
/// `DropRedundantEscaping` is the driver rule because it fires reliably on a
/// small fixture (`func run(_ body: @escaping () -> Void) { body() }`) and
/// has a config key (`dropRedundantEscaping` / `DropRedundantEscaping`) we
/// can name in `@warn(...)`.
@Suite
struct WarningControlTests {
  /// Runs the lint pipeline on `source`, returns the emitted findings for
  /// the named rule.
  private func lintFindings(
    _ source: String,
    rule: (some SyntaxRule).Type
  ) -> [Finding] {
    let tree = Parser.parse(source: source)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    let ruleKey = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? "\(rule)"
    let configuration = Configuration.forTesting(enabledRule: ruleKey)
    var emitted: [Finding] = []
    let pipeline = LintCoordinator(
      configuration: configuration,
      findingConsumer: { emitted.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    try! pipeline.lint(
      syntax: sourceFileSyntax,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )
    return emitted
  }

  private let escapingFixtureBody = """
    func run(_ body: @escaping () -> Void) {
      body()
    }
    """

  // MARK: - Sanity

  @Test func noWarnAttributeUsesConfiguredSeverity() {
    let findings = lintFindings(escapingFixtureBody, rule: DropRedundantEscaping.self)
    #expect(findings.count == 1)
    #expect(findings.first?.severity == .warn)
  }

  // MARK: - PascalCase group identifier

  @Test func pascalCaseIgnoredSilencesFinding() {
    let source = """
      @warn(DropRedundantEscaping, as: ignored)
      \(escapingFixtureBody)
      """
    let findings = lintFindings(source, rule: DropRedundantEscaping.self)
    #expect(findings.isEmpty)
  }

  @Test func pascalCaseErrorUpgradesFinding() {
    let source = """
      @warn(DropRedundantEscaping, as: error)
      \(escapingFixtureBody)
      """
    let findings = lintFindings(source, rule: DropRedundantEscaping.self)
    #expect(findings.count == 1)
    #expect(findings.first?.severity == .error)
  }

  @Test func pascalCaseWarningKeepsDefaultSeverity() {
    let source = """
      @warn(DropRedundantEscaping, as: warning)
      \(escapingFixtureBody)
      """
    let findings = lintFindings(source, rule: DropRedundantEscaping.self)
    #expect(findings.count == 1)
    #expect(findings.first?.severity == .warn)
  }

  // MARK: - camelCase group identifier (matches sm:ignore vocabulary)

  @Test func camelCaseGroupIdentifierIsRecognized() {
    let source = """
      @warn(dropRedundantEscaping, as: ignored)
      \(escapingFixtureBody)
      """
    let findings = lintFindings(source, rule: DropRedundantEscaping.self)
    #expect(findings.isEmpty)
  }

  // MARK: - Nested scopes: inner region wins

  @Test func nestedScopeInnermostWins() {
    let source = """
      @warn(DropRedundantEscaping, as: error)
      enum Outer {
        @warn(DropRedundantEscaping, as: ignored)
        \(escapingFixtureBody)
      }
      """
    let findings = lintFindings(source, rule: DropRedundantEscaping.self)
    #expect(findings.isEmpty)
  }

  // MARK: - Rule disabled in config: @warn cannot re-enable

  @Test func configuredOffStaysOff() {
    let source = """
      @warn(DropRedundantEscaping, as: error)
      \(escapingFixtureBody)
      """
    let tree = Parser.parse(source: source)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    var configuration = Configuration()
    var ruleValue = configuration[DropRedundantEscaping.self]
    ruleValue.lint = .no
    configuration[DropRedundantEscaping.self] = ruleValue
    var emitted: [Finding] = []
    let pipeline = LintCoordinator(
      configuration: configuration,
      findingConsumer: { emitted.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    try! pipeline.lint(
      syntax: sourceFileSyntax,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )
    #expect(emitted.isEmpty)
  }

}
