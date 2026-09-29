import Foundation
@testable import SwiftiomaticKit
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseCountWhereTests: RuleTesting {
  @Test func trailingClosureFilterCount() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.1️⃣filter { $0.isValid }.count
        """,
      expected: """
        let n = items.count(where: { $0.isValid })
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  @Test func parenthesizedClosureFilterCount() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.1️⃣filter({ $0.isValid }).count
        """,
      expected: """
        let n = items.count(where: { $0.isValid })
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  @Test func chainedFilterCount() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.sorted().1️⃣filter { $0.isActive }.count
        """,
      expected: """
        let n = items.sorted().count(where: { $0.isActive })
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  @Test func keyPathFilterCount() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.1️⃣filter(\\.isValid).count
        """,
      expected: """
        let n = items.count(where: \\.isValid)
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  /// In the full lint pipeline the rule receives a rewritten node. A finding placed on that node
  /// lost its source location, so `sm lint` reported the wrong line or nothing.
  @Test func lintPipelineReportsSourceLocation() {
    let source = """
      func f(parts: [Int]) {
          let n = parts.filter { $0 > 1 }.count
          print(n)
      }

      """
    let tree = Parser.parse(source: source)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    var emitted: [Finding] = []
    let pipeline = LintCoordinator(
      configuration: .forTesting,
      findingConsumer: { emitted.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    try! pipeline.lint(
      syntax: sourceFileSyntax,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )

    let findings = emitted.filter { $0.ruleID == "useCountWhere" }
    #expect(findings.count == 1)
    #expect(findings.first?.location?.line == 2)
    #expect(findings.first?.location?.column == 19)
  }

  @Test func filterWithoutCount() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let filtered = items.filter { $0.isValid }
        """,
      expected: """
        let filtered = items.filter { $0.isValid }
        """,
      findings: []
    )
  }

  @Test func countWithoutFilter() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.count
        """,
      expected: """
        let n = items.count
        """,
      findings: []
    )
  }

  @Test func filterCountAsMethodCall() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.filter { $0.isValid }.count(of: "x")
        """,
      expected: """
        let n = items.filter { $0.isValid }.count(of: "x")
        """,
      findings: []
    )
  }

  @Test func countWhereAlreadyUsed() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.count(where: { $0.isValid })
        """,
      expected: """
        let n = items.count(where: { $0.isValid })
        """,
      findings: []
    )
  }

  @Test func filterWithMultipleArgs() {
    assertFormatting(
      UseCountWhere.self,
      input: """
        let n = items.filter(isIncluded: predicate, limit: 10).count
        """,
      expected: """
        let n = items.filter(isIncluded: predicate, limit: 10).count
        """,
      findings: []
    )
  }
}
