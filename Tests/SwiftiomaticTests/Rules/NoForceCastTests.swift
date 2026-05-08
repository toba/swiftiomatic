import Foundation
@testable import SwiftiomaticKit
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForceCastTests: RuleTesting {

  /// Issue fn9-zk6: lint-only config (`rewrite: false, lint: .warn`) must still emit findings for
  /// transform-based rules like `NoForceCast`. Before the fix, `RewritePipeline` gated the entire
  /// rule dispatch on `rewriteEnabledRules`, so the inline `.diagnose` call never fired in
  /// `sm lint` mode for the rule's default config.
  @Test func lintOnlyConfigEmitsFinding() {
    var config = Configuration.forTesting
    config.disableAllRules()
    config[NoForceCast.self] = .init(rewrite: false, lint: .warn)

    let source = "let x = value as! Int\n"
    let tree = Parser.parse(source: source)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    var emitted: [Finding] = []
    let pipeline = LintCoordinator(
      configuration: config,
      findingConsumer: { emitted.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    try! pipeline.lint(
      syntax: sourceFileSyntax,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )

    #expect(emitted.count == 1)
    #expect(emitted.first?.message.text == "do not force cast to 'Int'")
  }


  @Test func forceCastDiagnosed() {
    assertFormatting(
      NoForceCast.self,
      input: """
        let x = value 1️⃣as! Int
        let y = something() 2️⃣as! String
        """,
      expected: """
        let x = value as! Int
        let y = something() as! String
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'Int'"),
        FindingSpec("2️⃣", message: "do not force cast to 'String'"),
      ]
    )
  }

  @Test func conditionalCastNotDiagnosed() {
    assertFormatting(
      NoForceCast.self,
      input: """
        let x = value as? Int
        let y = value as String
        """,
      expected: """
        let x = value as? Int
        let y = value as String
        """,
      findings: []
    )
  }

  @Test func forceCastInChain() {
    assertFormatting(
      NoForceCast.self,
      input: """
        let s = (value 1️⃣as! NSString).length
        """,
      expected: """
        let s = (value as! NSString).length
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'NSString'"),
      ]
    )
  }
}
