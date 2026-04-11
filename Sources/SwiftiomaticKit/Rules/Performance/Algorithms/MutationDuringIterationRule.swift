import SwiftSyntax

struct MutationDuringIterationRule {
  static let id = "mutation_during_iteration"
  static let name = "Mutation During Iteration"
  static let summary =
    "Detects collection mutation in for loops and Data.dropFirst() in loops"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("array.removeAll(where: { $0.isEmpty })"),
      Example(
        """
        for item in items {
            print(item)
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓for item in items {
            items.remove(at: 0)
        }
        """,
        configuration: ["severity": "warning"],
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension MutationDuringIterationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MutationDuringIterationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ForStmtSyntax) {
      if let sequenceExpr = node.sequence.as(DeclReferenceExprSyntax.self) {
        let collectionName = sequenceExpr.baseName.text

        let mutationFinder = MutationDuringIterationFinder(
          collectionName: collectionName,
          viewMode: .sourceAccurate,
        )
        mutationFinder.walk(node.body)

        if mutationFinder.foundMutation {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "Collection '\(collectionName)' is mutated during iteration — may crash or skip elements",
              severity: .error,
              confidence: .high,
              suggestion: "Use removeAll(where:), filter, or collect indices first",
            ),
          )
        }

        // Detect Data.dropFirst() in loop body
        let bodyStr = node.body.statements.trimmedDescription
        if bodyStr.contains("\(collectionName).dropFirst()") {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "Calling .dropFirst() on '\(collectionName)' inside loop — O(n²) if Data or contiguous collection",
              severity: .warning,
              confidence: .high,
              suggestion: "Use an index-based approach or Slice",
            ),
          )
        }
      }

      // Detect for-await over Observations with expensive body
      if let awaitKeyword = node.awaitKeyword {
        let sequenceStr = node.sequence.trimmedDescription
        if sequenceStr.contains("Observations") {
          let stmtCount = node.body.statements.count
          let bodyStr = node.body.statements.trimmedDescription
          if stmtCount > 2 || bodyStr.contains("await ") {
            violations.append(
              SyntaxViolation(
                position: awaitKeyword.positionAfterSkippingLeadingTrivia,
                reason:
                  "for-await over Observations with expensive body — consider debouncing or extracting work",
                severity: .warning,
                confidence: .low,
              ),
            )
          }
        }
      }
    }
  }
}
