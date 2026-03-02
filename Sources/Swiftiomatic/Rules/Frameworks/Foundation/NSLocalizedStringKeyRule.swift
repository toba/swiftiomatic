import SwiftSyntax

struct NSLocalizedStringKeyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NSLocalizedStringKeyConfiguration()
}

extension NSLocalizedStringKeyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSLocalizedStringKeyRule {}

extension NSLocalizedStringKeyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "NSLocalizedString"
      else {
        return
      }

      if let keyArgument = node.arguments.first(where: { $0.label == nil })?.expression,
        keyArgument.hasViolation
      {
        violations.append(keyArgument.positionAfterSkippingLeadingTrivia)
      }

      if let commentArgument = node.arguments.first(where: { $0.label?.text == "comment" })?
        .expression,
        commentArgument.hasViolation
      {
        violations.append(commentArgument.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension ExprSyntax {
  fileprivate var hasViolation: Bool {
    if let strExpr = `as`(StringLiteralExprSyntax.self) {
      return strExpr.segments.contains { segment in
        !segment.is(StringSegmentSyntax.self)
      }
    }

    if let sequenceExpr = `as`(SequenceExprSyntax.self) {
      return sequenceExpr.elements.contains { expr in
        if expr.is(BinaryOperatorExprSyntax.self) {
          return false
        }

        return expr.hasViolation
      }
    }

    return true
  }
}
