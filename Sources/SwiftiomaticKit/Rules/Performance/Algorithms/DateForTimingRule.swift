import SwiftSyntax

struct DateForTimingRule {
  static let id = "date_for_timing"
  static let name = "Date for Timing"
  static let summary =
    "Detects Date() used for timing measurements — prefer ContinuousClock for monotonic timing"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let now = ContinuousClock.now"),
      Example("let date = Date()"),
      Example("let formatter = DateFormatter()"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let start = ↓Date(); doWork(); let elapsed = Date().timeIntervalSince(start)"),
      Example("let start = ↓Date(); let duration = Date().timeIntervalSince(start)"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension DateForTimingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DateForTimingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription
      guard callee == "Date" || callee == "Date.init" else { return }

      if let parent = node.parent,
        parent.trimmedDescription.contains("timeIntervalSince")
          || parent.trimmedDescription.contains("elapsed")
          || parent.trimmedDescription.contains("start")
          || parent.trimmedDescription.contains("duration")
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Date() used for timing — can go backwards due to NTP adjustments",
            severity: .warning,
            confidence: .medium,
            suggestion: "Use ContinuousClock.now for monotonic timing",
          ),
        )
      }
    }
  }
}
