import Foundation
import SwiftiomaticSyntax

struct ConcurrencyModernizationRule {
  static let id = "concurrency_modernization"
  static let name = "Concurrency Modernization"
  static let summary =
    "Flags GCD usage and legacy concurrency patterns that should use structured concurrency"
  static let isOptIn = true
  static let canEnrichAsync = true

  static var relatedRuleIDs: [String] { ["async_stream_safety"] }
  static var nonTriggeringExamples: [Example] {
    [
      Example("Task { @MainActor in update() }"),
      Example("await withTaskGroup(of: Void.self) { }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓DispatchQueue.main.async { update() }", configuration: ["severity": "warning"]),
      Example("↓DispatchGroup()", configuration: ["severity": "warning"]),
      Example(
        "↓func fetch(completion: @escaping (Result<Data, Error>) -> Void) {}",
        configuration: ["severity": "warning"]),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension ConcurrencyModernizationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ConcurrencyModernizationRule: AsyncEnrichableRule {
  func enrich(
    file: SwiftSource,
    typeResolver: any TypeResolver,
  ) async -> [RuleViolation] {
    guard let filePath = file.path else { return [] }

    // Find DispatchQueue.*.async calls and verify via SourceKit
    let collector = DispatchQueueCallCollector(viewMode: .sourceAccurate)
    collector.walk(file.syntaxTree)

    var violations: [RuleViolation] = []

    for query in collector.queries {
      guard
        let resolved = await typeResolver.resolveType(
          inFile: filePath, offset: query.offset,
        )
      else { continue }

      if resolved.moduleName == "Dispatch"
        || resolved.typeName.hasPrefix("Dispatch.DispatchQueue")
        || resolved.typeName == "DispatchQueue"
      {
        // Confirmed DispatchQueue — emit with high confidence
        violations.append(
          RuleViolation(
            ruleType: Self.self,
            severity: options.severity,
            location: Location(file: filePath, line: query.line, column: query.column),
            reason: "DispatchQueue.async can be replaced with structured concurrency",
            confidence: .high,
            suggestion: "Use Task { @MainActor in ... } or async function",
          ),
        )
      }
    }

    return violations
  }
}

extension ConcurrencyModernizationRule {
  fileprivate struct DispatchQueueQuery {
    let offset: Int
    let line: Int
    let column: Int
  }

  fileprivate final class DispatchQueueCallCollector: SyntaxVisitor {
    var queries: [DispatchQueueQuery] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
      let callee = node.calledExpression.trimmedDescription
      if ConcurrencyPatternDetector.isDispatchQueueAsync(callee) {
        let loc = node.startLocation(
          converter: .init(fileName: "", tree: node.root),
        )
        queries.append(
          DispatchQueueQuery(
            offset: node.calledExpression.positionAfterSkippingLeadingTrivia.utf8Offset,
            line: loc.line,
            column: loc.column,
          ),
        )
      }
      return .visitChildren
    }
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      for param in node.signature.parameterClause.parameters
      where ConcurrencyPatternDetector.isCompletionHandlerParam(param) {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Function '\(node.name.text)' uses completion handler pattern",
            severity: .warning,
            confidence: .high,
            suggestion: "Convert to async/await",
          ),
        )
        break
      }
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription

      if ConcurrencyPatternDetector.isDispatchQueueAsync(callee) {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "DispatchQueue.async can be replaced with structured concurrency",
            severity: .warning,
            confidence: .medium,
            suggestion: "Use Task { @MainActor in ... } or async function",
          ),
        )
      }

      if callee.contains("DispatchGroup") {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "DispatchGroup can be replaced with TaskGroup",
            severity: .warning,
            confidence: .medium,
            suggestion: "Use withTaskGroup or withThrowingTaskGroup",
          ),
        )
      }

      if callee.contains("NSLock()") || callee.contains("os_unfair_lock") {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Lock-based synchronization can be replaced with Mutex",
            severity: .warning,
            confidence: .medium,
            suggestion: "Use Mutex<Value> for state protection",
          ),
        )
      }

      // Detect withCheckedContinuation wrapping single async call
      if callee == "withCheckedContinuation" || callee == "withCheckedThrowingContinuation" {
        if let trailingClosure = node.trailingClosure {
          let stmts = trailingClosure.statements
          let awaitCount = stmts.trimmedDescription.countOccurrences(of: "await ")
          let resumeCount = stmts.trimmedDescription
            .countOccurrences(of: "continuation.resume")
          if awaitCount == 1, resumeCount == 1 {
            violations.append(
              SyntaxViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason:
                  "\(callee) wraps a single async call — the continuation wrapper may be unnecessary",
                severity: .warning,
                confidence: .medium,
                suggestion:
                  "Call the async function directly instead of wrapping in a continuation",
              ),
            )
          }
        }
      }

      // Detect OperationQueue()
      if callee == "OperationQueue" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "OperationQueue can be replaced with TaskGroup",
            severity: .warning,
            confidence: .medium,
            suggestion: "Use withTaskGroup or withThrowingTaskGroup",
          ),
        )
      }

      // Detect Timer.scheduledTimer and DispatchSource.makeTimerSource
      if callee.contains("Timer.scheduledTimer") || callee.contains("makeTimerSource") {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Timer/DispatchSource timer can be replaced with AsyncTimerSequence",
            severity: .warning,
            confidence: .medium,
            suggestion:
              "Use AsyncTimerSequence from swift-async-algorithms or Task.sleep(for:)",
          ),
        )
      }
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
      let memberName = node.declName.baseName.text

      // Detect NotificationCenter.addObserver in async context
      if memberName == "addObserver",
        node.base?.trimmedDescription.contains("NotificationCenter") == true,
        isInsideAsyncContext(Syntax(node))
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "NotificationCenter.addObserver in async context — prefer .notifications(named:)",
            severity: .warning,
            confidence: .low,
            suggestion: "Use NotificationCenter.default.notifications(named:) async sequence",
          ),
        )
      }

      // Detect OperationQueue usage
      if memberName == "addOperation" || memberName == "addBarrierBlock" {
        if node.base?.trimmedDescription.contains("operationQueue") == true
          || node.base?.trimmedDescription.contains("OperationQueue") == true
        {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason: "OperationQueue.\(memberName) can be replaced with TaskGroup",
              severity: .warning,
              confidence: .medium,
              suggestion: "Use withTaskGroup or withThrowingTaskGroup",
            ),
          )
        }
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      if ConcurrencyPatternDetector.hasUncheckedSendable(node.inheritanceClause) {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Class '\(node.name.text)' uses @unchecked Sendable — check if Mutex would enable proper Sendable",
            severity: .warning,
            confidence: .low,
          ),
        )
      }
    }

    private func isInsideAsyncContext(_ node: Syntax) -> Bool {
      if let funcDecl = node.nearestAncestor(ofType: FunctionDeclSyntax.self) {
        return funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
      }
      if let closureExpr = node.nearestAncestor(ofType: ClosureExprSyntax.self) {
        return closureExpr.signature?.effectSpecifiers?.asyncSpecifier != nil
      }
      return false
    }
  }
}

extension String {
  fileprivate func countOccurrences(of target: String) -> Int {
    var count = 0
    var searchRange = startIndex..<endIndex
    while let found = range(of: target, range: searchRange) {
      count += 1
      searchRange = found.upperBound..<endIndex
    }
    return count
  }
}
