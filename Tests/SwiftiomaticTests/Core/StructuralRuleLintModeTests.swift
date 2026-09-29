import Foundation
@testable import SwiftiomaticKit
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
package import Testing

/// Lint mode runs each `StructuralFormatRule` through its lint-only path, which emits findings
/// without building a new tree. These tests pin the findings of that path, including nested
/// nodes that a `super.visit` recursion inside the rule would reach a second time.
@Suite
struct StructuralRuleLintModeTests {
  /// Lints `source` with only `rule` enabled and returns each finding as `"<line>: <message>"`,
  /// followed by one `"  note <line>: <message>"` entry for each of its notes.
  private func lintFindings(
    _ source: String,
    rule: (some SyntaxRule).Type,
    configure: (inout Configuration) -> Void = { _ in }
  ) throws -> [String] {
    let tree = Parser.parse(source: source)
    let sourceFileSyntax = try #require(
      try OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self))
    let ruleKey = try #require(ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)])
    var configuration = Configuration.forTesting(enabledRule: ruleKey)
    configure(&configuration)
    var emitted: [Finding] = []
    let coordinator = LintCoordinator(
      configuration: configuration,
      findingConsumer: { emitted.append($0) }
    )
    coordinator.debugOptions.insert(.disablePrettyPrint)
    try coordinator.lint(
      syntax: sourceFileSyntax,
      source: source,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )
    return emitted
      .sorted { ($0.location?.line ?? 0, $0.message.text) < ($1.location?.line ?? 0, $1.message.text) }
      .flatMap { finding in
        ["\(finding.location?.line ?? 0): \(finding.message.text)"]
          + finding.notes.map { "  note \($0.location?.line ?? 0): \($0.message.text)" }
      }
  }

  @Test func insertBlankLineBetweenScopesReportsNestedBlocksOnce() throws {
    let source = """
      struct A {
        struct B {
          func f() {
          }
          func g() {}
        }
        func h() {}
      }
      """
    #expect(
      try lintFindings(source, rule: InsertBlankLineBetweenScopes.self) == [
        "5: insert blank line after scoped declaration",
        "7: insert blank line after scoped declaration",
      ])
  }

  @Test func sortDeclarationsReportsNestedRegionOnce() throws {
    let source = """
      struct A {
        struct B {
          // swiftiomatic:sort:begin
          var b = 1
          var a = 2
          // swiftiomatic:sort:end
          var z = 3
        }
      }
      """
    #expect(
      try lintFindings(source, rule: SortDeclarations.self) == [
        "4: sort declarations alphabetically"
      ])
  }

  @Test func hoistExtensionAccessKeepsMemberNotes() throws {
    let source = """
      public extension A {
        func f() {}
        #if DEBUG
        var x: Int { 1 }
        #endif
        internal func g() {}
      }
      """
    #expect(
      try lintFindings(source, rule: HoistExtensionAccess.self) == [
        "1: move this 'public' access modifier to precede each member inside this extension",
        "  note 2: add 'public' access modifier to this declaration",
        "  note 4: add 'public' access modifier to this declaration",
      ])
  }

  @Test func hoistExtensionAccessOnExtensionKeepsMemberNotes() throws {
    let source = """
      extension A {
        public func f() {}
        public var x: Int { 1 }
      }
      """
    let findings = try lintFindings(source, rule: HoistExtensionAccess.self) {
      $0[HoistExtensionAccess.self].placement = .onExtension
    }
    #expect(
      findings == [
        "1: hoist 'public' access modifier from members to this extension",
        "  note 2: remove 'public' access modifier from this declaration",
        "  note 3: remove 'public' access modifier from this declaration",
      ])
  }

  @Test func useShorthandTypeNamesReportsEachTypeOnce() throws {
    let source = """
      let x: Array<Array<Int>> = []
      """
    #expect(
      try lintFindings(source, rule: UseShorthandTypeNames.self) == [
        "1: use shorthand syntax for this 'Array' type",
        "1: use shorthand syntax for this 'Array' type",
      ])
  }

  @Test func useFilePrivateForFileLocalReportsConditionalDeclarations() throws {
    let source = """
      fileprivate func f() {}
      #if DEBUG
      fileprivate var x = 1
      #endif
      """
    #expect(
      try lintFindings(source, rule: UseFilePrivateForFileLocal.self) == [
        "1: replace 'fileprivate' with 'private' on file-scoped declarations",
        "3: replace 'fileprivate' with 'private' on file-scoped declarations",
      ])
  }

  @Test func sortImportsReportsOrderAndDuplicates() throws {
    let source = """
      import B
      import A
      import A

      let x = 1
      """
    #expect(
      try lintFindings(source, rule: SortImports.self) == [
        "2: sort import statements lexicographically",
        "3: remove this duplicate import",
      ])
  }

  @Test func sortTypeAliasesReportsUnsortedComposition() throws {
    #expect(
      try lintFindings("typealias T = B & A", rule: SortTypeAliases.self) == [
        "1: sort protocol composition types alphabetically"
      ])
  }

  @Test func sortSwitchCasesReportsUnsortedItems() throws {
    let source = """
      switch x {
      case .b, .a: break
      default: break
      }
      """
    #expect(
      try lintFindings(source, rule: SortSwitchCases.self) == [
        "2: sort switch case items alphabetically"
      ])
  }

  @Test func insertBlankLineAfterImportsReportsMissingLine() throws {
    let source = """
      import A
      let x = 1
      """
    #expect(
      try lintFindings(source, rule: InsertBlankLineAfterImports.self) == [
        "2: insert blank line after import statements"
      ])
  }
}
