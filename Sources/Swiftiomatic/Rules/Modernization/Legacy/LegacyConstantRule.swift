import SwiftSyntax
import SwiftSyntaxBuilder

struct LegacyConstantRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "legacy_constant",
    name: "Legacy Constant",
    description: "Struct-scoped constants are preferred over legacy global constants",
    nonTriggeringExamples: LegacyConstantRuleExamples.nonTriggeringExamples,
    triggeringExamples: LegacyConstantRuleExamples.triggeringExamples,
    corrections: LegacyConstantRuleExamples.corrections,
  )
}

extension LegacyConstantRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension LegacyConstantRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if LegacyConstantRuleExamples.patterns.keys.contains(node.baseName.text) {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      if node.isLegacyPiExpression {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
      guard let correction = LegacyConstantRuleExamples.patterns[node.baseName.text] else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return ("\(raw: correction)" as ExprSyntax)
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.isLegacyPiExpression,
        let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self)
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return ("\(raw: calledExpression.baseName.text).pi" as ExprSyntax)
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var isLegacyPiExpression: Bool {
    guard
      let calledExpression = calledExpression.as(DeclReferenceExprSyntax.self),
      calledExpression.baseName.text == "CGFloat"
        || calledExpression.baseName
          .text == "Float",
      let argument = arguments.onlyElement?.expression.as(DeclReferenceExprSyntax.self),
      argument.baseName.text == "M_PI"
    else {
      return false
    }

    return true
  }
}
