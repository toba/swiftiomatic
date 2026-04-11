import SwiftParser
import SwiftSyntax
import Testing

@testable import SwiftiomaticKit

/// Mock resolver for testing SourceKit-enhanced rules without sourcekitd.
struct MockResolver: TypeResolver {
  var isAvailable: Bool { true }

  /// Canned responses keyed by offset.
  var typesByOffset: [Int: ResolvedType] = [:]
  var fileIndexes: [String: FileIndex] = [:]
  var expressionTypesByFile: [String: [ExpressionTypeInfo]] = [:]

  func resolveType(inFile _: String, offset: Int) -> ResolvedType? {
    typesByOffset[offset]
  }

  func indexFile(_ file: String) -> FileIndex? {
    fileIndexes[file]
  }

  func expressionTypes(inFile file: String) -> [ExpressionTypeInfo] {
    expressionTypesByFile[file] ?? []
  }
}

@Suite("TypeResolver Integration")
struct TypeResolverTests {
  @Test func nullResolverReturnsNil() {
    let resolver = NullResolver()
    #expect(!resolver.isAvailable)
    #expect(resolver.resolveType(inFile: "test.swift", offset: 0) == nil)
    #expect(resolver.indexFile("test.swift") == nil)
    #expect(resolver.expressionTypes(inFile: "test.swift").isEmpty)
  }

  @Test func analyzerWorksWithNilResolver() async {
    let analyzer = Analyzer(
      typeResolver: nil
    )
    // Just verify it doesn't crash — analyzer uses paths, not inline source
    let findings = await analyzer.analyze(paths: [])
    #expect(findings.isEmpty)
  }

  @Test func concurrencyRuleDetectsDispatchQueue() {
    let source = """
      import Dispatch
      func doWork() {
          DispatchQueue.main.async { print("hi") }
      }
      """
    let file = SwiftSource(contents: source)
    let rule = ConcurrencyModernizationRule()
    let violations = rule.validate(file: file)

    let dispatchViolation = violations.first {
      $0.reason.contains("DispatchQueue")
    }
    // Without async enrichment — medium confidence
    #expect(dispatchViolation?.confidence == .medium)
  }

  @Test func anyRuleDetectsLiteralAny() {
    let source = """
      var data: Any = 42
      """
    let file = SwiftSource(contents: source)
    let rule = AnyEliminationRule()
    let violations = rule.validate(file: file)

    let anyViolations = violations.filter {
      $0.reason.contains("Any")
    }
    #expect(!anyViolations.isEmpty)
  }
}
