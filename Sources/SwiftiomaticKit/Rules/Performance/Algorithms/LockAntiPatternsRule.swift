import SwiftiomaticSyntax

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
        """
      ),
      Example(
        """
        mutex.withLock {
            doSyncWork()
        }
        """
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
      Example(
        """
        outer.↓withLock {
            inner.↓withLock {
                count += 1
            }
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

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
      guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "withLock"
      else {
        return .visitChildren
      }

      let position = memberAccess.declName.baseName.positionAfterSkippingLeadingTrivia

      withLockDepth += 1

      if withLockDepth > 1 {
        violations.append(
          SyntaxViolation(
            position: position,
            reason: "Nested withLock — potential deadlock risk",
            severity: .error,
            confidence: .high,
          )
        )
      }

      if let trailingClosure = node.trailingClosure {
        let hasAwait = trailingClosure.statements.children(viewMode: .sourceAccurate)
          .contains { node in
            node.tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.await) }
          }
        if hasAwait {
          violations.append(
            SyntaxViolation(
              position: position,
              reason:
                "withLock closure contains await — lock will be held across suspension point",
              severity: .error,
              confidence: .high,
              suggestion: "Move the await outside the lock or use an actor instead",
            )
          )
        }
      }

      return .visitChildren
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "withLock"
      else { return }
      withLockDepth -= 1
    }
  }
}
