import SwiftSyntax

struct AsyncStreamSafetyRule {
  static let id = "async_stream_safety"
  static let name = "AsyncStream Safety"
  static let summary =
    "AsyncStream continuations must call finish() and set onTermination"
  static let isOptIn = false

  static var relatedRuleIDs: [String] { ["concurrency_modernization"] }

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        let stream = AsyncStream<Int> { continuation in
            continuation.onTermination = { _ in cleanup() }
            Task {
                for i in 0..<10 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        """),
      Example(
        """
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            continuation.onTermination = { _ in session.cancel() }
            session.onData = { data in continuation.yield(data) }
            session.onComplete = { continuation.finish() }
            session.onError = { continuation.finish(throwing: $0) }
        }
        """),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        let stream = ↓AsyncStream<Int> { continuation in
            Task {
                for i in 0..<10 {
                    continuation.yield(i)
                }
            }
        }
        """,
        configuration: ["severity": "warning"]),
      Example(
        """
        let stream = ↓AsyncThrowingStream<Data, Error> { continuation in
            continuation.finish()
        }
        """,
        configuration: ["severity": "warning"]),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension AsyncStreamSafetyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AsyncStreamSafetyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription

      guard callee == "AsyncStream" || callee == "AsyncThrowingStream" else {
        return
      }
      guard let trailingClosure = node.trailingClosure else {
        return
      }

      let body = trailingClosure.statements.trimmedDescription

      if !body.contains("continuation.finish") {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "\(callee) may be missing continuation.finish() call",
            severity: .warning,
            confidence: .high,
            suggestion: "Add continuation.finish() in all exit paths",
          ),
        )
      }

      if !body.contains("onTermination") {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "\(callee) missing onTermination handler — resources may leak on cancellation",
            severity: .warning,
            confidence: .medium,
            suggestion: "Set continuation.onTermination to clean up resources",
          ),
        )
      }
    }
  }
}
