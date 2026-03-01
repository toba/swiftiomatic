import SwiftSyntax

struct ObservationPitfallsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "observation_pitfalls",
    name: "Observation Pitfalls",
    description: "Detects common pitfalls with the Observation framework",
    nonTriggeringExamples: [
      Example("for await value in Observations({ [weak self] in self?.model }) { }")
    ],
    triggeringExamples: [
      Example("↓withObservationTracking { observe() }")
    ],
  )
}

extension ObservationPitfallsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension ObservationPitfallsRule: OptInRule {}

extension ObservationPitfallsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if node.calledExpression.trimmedDescription == "withObservationTracking" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "withObservationTracking with recursive onChange — consider Observations AsyncSequence",
            severity: .warning,
            confidence: .medium,
            suggestion: "Replace with `for await value in Observations { ... }`",
          ),
        )
      }
    }

    override func visitPost(_ node: ForStmtSyntax) {
      guard let callExpr = node.sequence.as(FunctionCallExprSyntax.self),
        callExpr.calledExpression.trimmedDescription == "Observations"
      else { return }

      if let trailingClosure = callExpr.trailingClosure {
        let hasWeakSelf =
          trailingClosure.signature?.capture?.items.contains { item in
            item.trimmedDescription.contains("weak self")
          } ?? false

        if !hasWeakSelf {
          violations.append(
            SyntaxViolation(
              position: callExpr.positionAfterSkippingLeadingTrivia,
              reason: "Observations closure missing [weak self] — may cause retain cycle",
              severity: .error,
              confidence: .medium,
              suggestion: "Add [weak self] to the Observations closure",
            ),
          )
        }
      }
    }
  }
}
