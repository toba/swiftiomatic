import SwiftSyntax

struct AgentReviewRule {
  static let id = "agent_review"
  static let name = "Agent Review"
  static let summary = "Lower-confidence checks that benefit from agent verification"
  static let isOptIn = true
  static let relatedRuleIDs: [String] = ["fire_and_forget_task"]
  static var nonTriggeringExamples: [Example] {
    [
      Example("enum AppError: LocalizedError { case failed }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("enum ↓AppError: Error { case failed }", configuration: ["severity": "warning"]),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension AgentReviewRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AgentReviewRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription

      // .absoluteString usage
      if callee.hasSuffix(".absoluteString") {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: ".absoluteString used — verify this isn't a file URL (use .path for file URLs)",
            severity: .warning,
            confidence: .low,
          ),
        )
      }
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
      if node.declName.baseName.text == "absoluteString",
        node.parent?.is(FunctionCallExprSyntax.self) != true
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: ".absoluteString used — verify this isn't a file URL (use .path for file URLs)",
            severity: .warning,
            confidence: .low,
          ),
        )
      }
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      guard let inheritance = node.inheritanceClause else { return }
      let inheritedTypes = inheritance.inheritedTypes.map(\.type.trimmedDescription)
      if inheritedTypes.contains("Error"), !inheritedTypes.contains("LocalizedError") {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason:
              "Error enum '\(node.name.text)' doesn't conform to LocalizedError — verify if user-facing",
            severity: .warning,
            confidence: .low,
            suggestion: "Add LocalizedError conformance with errorDescription",
          ),
        )
      }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      let modifiers = node.modifiers.map(\.trimmedDescription)
      if modifiers.contains("nonisolated(unsafe)") {
        let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "nonisolated(unsafe) on '\(bindingName)' — verify the value is actually Sendable in Swift 6.2",
            severity: .warning,
            confidence: .low,
          ),
        )
      }
    }
  }
}
