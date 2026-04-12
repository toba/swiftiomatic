import Foundation
import SwiftParser
public import SwiftiomaticSyntax

/// Orchestrates analysis of Swift source files through a single Rule-based pipeline.
///
/// All analysis — suggest, lint, and async enrichment — flows through `Rule.validate()`.
/// Rules conforming to `AsyncEnrichableRule` get a second pass via `enrich()` with SourceKit resolution.
public struct Analyzer: Sendable {
  /// Minimum confidence to include in results.
  public let minConfidence: Confidence

  /// Optional SourceKit-backed type resolver for semantic analysis.
  public let typeResolver: (any TypeResolver)?

  /// Instantiated lint rules to run.
  public let lintRules: [any Rule]

  /// Compiler arguments for AnalyzerRules (if any).
  public let compilerArguments: [String]

  public init(
    minConfidence: Confidence = .low,
    typeResolver: (any TypeResolver)? = nil,
    lintRules: [any Rule] = [],
    compilerArguments: [String] = [],
  ) {
    self.minConfidence = minConfidence
    self.typeResolver = typeResolver
    self.lintRules = lintRules
    self.compilerArguments = compilerArguments
  }

  /// Analyze the given file paths and return unified diagnostics.
  public func analyze(paths: [String]) async -> [Diagnostic] {
    let files = FileDiscovery.findSwiftFiles(in: paths)
    guard !files.isEmpty else { return [] }

    let sources = files.compactMap { SwiftSource(path: $0) }
    var diagnostics = runLintRules(on: sources)

    // Async enrichment for rules that support it
    if let resolver = typeResolver, resolver.isAvailable {
      let enrichableRules = lintRules.compactMap { $0 as? any AsyncEnrichableRule }
      if !enrichableRules.isEmpty {
        for file in sources {
          for rule in enrichableRules {
            let extra = await CurrentRule.$identifier.withValue(type(of: rule).identifier) {
              await rule.enrich(file: file, typeResolver: resolver)
            }
            diagnostics += extra.map { $0.toDiagnostic() }
          }
        }
      }
    }

    // Filter by confidence
    diagnostics = diagnostics.filter { $0.confidence >= minConfidence }

    return diagnostics.sorted()
  }

  // MARK: - Lint Rules

  private func runLintRules(on lintFiles: [SwiftSource]) -> [Diagnostic] {
    guard !lintRules.isEmpty else { return [] }

    let storage = RuleStorage()

    // Separate collecting rules (need two-pass) from single-pass rules
    let collectingRules = lintRules.filter { type(of: $0).isCrossFile }
    let singlePassRules = lintRules.filter { !type(of: $0).isCrossFile }

    // Pass 1: collect cross-file info for CollectingRules
    for file in lintFiles {
      for rule in collectingRules {
        CurrentRule.$identifier.withValue(type(of: rule).identifier) {
          rule.collectInfo(for: file, into: storage, compilerArguments: compilerArguments)
        }
      }
    }

    // Pass 2: validate all rules
    var diagnostics: [Diagnostic] = []
    for file in lintFiles {
      for rule in singlePassRules {
        let violations = CurrentRule.$identifier.withValue(type(of: rule).identifier) {
          rule.validate(file: file)
        }
        diagnostics += violations.map { $0.toDiagnostic() }
      }
      for rule in collectingRules {
        let violations = CurrentRule.$identifier.withValue(type(of: rule).identifier) {
          rule.validate(
            file: file,
            using: storage,
            compilerArguments: compilerArguments,
          )
        }
        diagnostics += violations.map { $0.toDiagnostic() }
      }
    }

    return diagnostics
  }
}
