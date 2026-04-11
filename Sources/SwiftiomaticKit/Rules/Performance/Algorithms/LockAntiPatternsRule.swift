import SwiftSyntax

struct LockAntiPatternsRule {
  static let id = "lock_anti_patterns"
  static let name = "Lock Anti-Patterns"
  static let summary =
    "Detects nested withLock calls (deadlock risk) and await inside withLock (held across suspension)"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        mutex.withLock {
            count += 1
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        mutex.↓withLock {
            await fetchData()
        }
        """,
        configuration: ["severity": "error"],
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension LockAntiPatternsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LockAntiPatternsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var withLockDepth = 0

    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription
      guard callee.hasSuffix(".withLock") || callee == "withLock" else { return }

      withLockDepth += 1
      defer { withLockDepth -= 1 }

      if withLockDepth > 1 {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Nested withLock — potential deadlock risk",
            severity: .error,
            confidence: .high,
          ),
        )
      }

      if let trailingClosure = node.trailingClosure {
        let bodyStr = trailingClosure.statements.trimmedDescription
        if bodyStr.contains("await ") {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "withLock closure contains await — lock will be held across suspension point",
              severity: .error,
              confidence: .high,
              suggestion: "Move the await outside the lock or use an actor instead",
            ),
          )
        }
      }
    }
  }
}
