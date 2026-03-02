import SwiftSyntax
import SwiftSyntaxBuilder

struct ExplicitInitRule {
  var options = ExplicitInitOptions()

  static let configuration = ExplicitInitConfiguration()
}

extension ExplicitInitRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ExplicitInitRule {}

extension ExplicitInitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self)
      else {
        return
      }

      if let violationPosition = calledExpression.explicitInitPosition {
        violations.append(violationPosition)
      }

      if configuration.includeBareInit,
        let violationPosition = calledExpression.bareInitPosition
      {
        let reason = "Prefer named constructors over .init and type inference"
        violations.append(
          SyntaxViolation(
            position: violationPosition,
            reason: reason,
          ))
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
        calledExpression.explicitInitPosition != nil,
        let calledBase = calledExpression.base
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode = node.with(\.calledExpression, calledBase)
      return super.visit(newNode)
    }
  }
}

extension MemberAccessExprSyntax {
  fileprivate var explicitInitPosition: AbsolutePosition? {
    if let base, base.isTypeReferenceLike, declName.baseName.text == "init" {
      return base.endPositionBeforeTrailingTrivia
    }
    return nil
  }

  fileprivate var bareInitPosition: AbsolutePosition? {
    if base == nil, declName.baseName.text == "init" {
      return period.positionAfterSkippingLeadingTrivia
    }
    return nil
  }
}

extension ExprSyntax {
  /// `String` or `Nested.Type`.
  fileprivate var isTypeReferenceLike: Bool {
    if let expr = `as`(DeclReferenceExprSyntax.self), expr.baseName.text.startsWithUppercase {
      return true
    }
    if let expr = `as`(MemberAccessExprSyntax.self),
      expr.description.split(separator: ".").allSatisfy(\.startsWithUppercase)
    {
      return true
    }
    if let expr = `as`(GenericSpecializationExprSyntax.self)?.expression.as(
      DeclReferenceExprSyntax.self,
    ),
      expr.baseName.text.startsWithUppercase
    {
      return true
    }
    return false
  }
}

extension StringProtocol {
  fileprivate var startsWithUppercase: Bool {
    first?.isUppercase == true
  }
}
