import SwiftSyntax

struct ObservationPitfallsRule {
    static let id = "observation_pitfalls"
    static let name = "Observation Pitfalls"
    static let summary = "Detects common pitfalls with the Observation framework"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("for await value in Observations({ [weak self] in self?.model }) { }")
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                for await value in ↓Observations({ self.model }) {
                    print(value)
                }
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension ObservationPitfallsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ObservationPitfallsRule {}

extension ObservationPitfallsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
