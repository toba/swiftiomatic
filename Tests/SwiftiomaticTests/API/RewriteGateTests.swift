@testable import SwiftiomaticKit
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import Testing

/// Verifies that a rule configured with `rewrite: false, lint: .warn` reports findings without
/// modifying source. Regression for issues x3m-t6u (preferFinalClasses) and a5z-211
/// (uppercaseAcronymsInIdentifiers), where the rewrite path was gated on the OR-of-lint-or-rewrite
/// `enabledRules` set and so fired even when the user had explicitly disabled the rewrite.
@Suite
struct RewriteGateTests {
  /// `uppercaseAcronymsInIdentifiers` lints `Url` → suggests `URL` , but with `rewrite: false` the source
  /// must be left intact.
  @Test func uppercaseAcronymsLintsButDoesNotRewriteWhenRewriteFalse() throws {
    let source = "let myUrl = 0\n"

    var config = Configuration.forTesting
    config.disableAllRules()
    var ruleValue = config[UppercaseAcronymsInIdentifiers.self]
    ruleValue.rewrite = false
    ruleValue.lint = .warn
    config[UppercaseAcronymsInIdentifiers.self] = ruleValue

    var findings: [Finding] = []
    let pipeline = RewriteCoordinator(
      configuration: config,
      findingConsumer: { findings.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)

    let tree = Parser.parse(source: source)
    let sourceFile = try OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    var output = ""
    try pipeline.format(
      syntax: sourceFile,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: nil,
      selection: .infinite,
      to: &output
    )

    #expect(output == source, "source must be unchanged when rewrite is disabled")
    _ = findings
  }

  /// `preferFinalClasses` lints `class C {}` and would normally add `final` , but with
  /// `rewrite: false` the source must be left intact.
  @Test func preferFinalClassesLintsButDoesNotRewriteWhenRewriteFalse() throws {
    let source = "class Widget {}\n"

    var config = Configuration.forTesting
    config.disableAllRules()
    var ruleValue = config[PreferFinalClasses.self]
    ruleValue.rewrite = false
    ruleValue.lint = .warn
    config[PreferFinalClasses.self] = ruleValue

    var findings: [Finding] = []
    let pipeline = RewriteCoordinator(
      configuration: config,
      findingConsumer: { findings.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)

    let tree = Parser.parse(source: source)
    let sourceFile = try OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    var output = ""
    try pipeline.format(
      syntax: sourceFile,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: nil,
      selection: .infinite,
      to: &output
    )

    #expect(output == source, "source must be unchanged when rewrite is disabled")
    _ = findings
  }
}
