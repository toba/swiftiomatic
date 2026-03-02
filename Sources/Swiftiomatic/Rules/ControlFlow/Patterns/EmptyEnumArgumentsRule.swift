import SwiftSyntax

struct EmptyEnumArgumentsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = EmptyEnumArgumentsConfiguration()
}

extension EmptyEnumArgumentsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension EmptyEnumArgumentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseItemSyntax) {
      if let violationPosition = node.pattern.emptyEnumArgumentsViolation(rewrite: false)?
        .position
      {
        violations.append(violationPosition)
      }
    }

    override func visitPost(_ node: MatchingPatternConditionSyntax) {
      if let violationPosition = node.pattern.emptyEnumArgumentsViolation(rewrite: false)?
        .position
      {
        violations.append(violationPosition)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
      guard let (_, newPattern) = node.pattern.emptyEnumArgumentsViolation(rewrite: true)
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(node.with(\.pattern, newPattern))
    }

    override func visit(_ node: MatchingPatternConditionSyntax)
      -> MatchingPatternConditionSyntax
    {
      guard let (_, newPattern) = node.pattern.emptyEnumArgumentsViolation(rewrite: true)
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(node.with(\.pattern, newPattern))
    }
  }
}

extension PatternSyntax {
  fileprivate func emptyEnumArgumentsViolation(rewrite: Bool) -> (
    position: AbsolutePosition, pattern: PatternSyntax,
  )? {
    guard
      var pattern = `as`(ExpressionPatternSyntax.self),
      let expression = pattern.expression.as(FunctionCallExprSyntax.self),
      expression.argumentsHasViolation,
      let calledExpression = expression.calledExpression.as(MemberAccessExprSyntax.self),
      calledExpression.base == nil,
      let violationPosition = expression.innermostFunctionCall.leftParen?
        .positionAfterSkippingLeadingTrivia
    else {
      return nil
    }

    if rewrite {
      pattern.expression = expression.removingInnermostDiscardArguments
    }

    return (violationPosition, PatternSyntax(pattern))
  }
}

extension FunctionCallExprSyntax {
  fileprivate var argumentsHasViolation: Bool {
    !calledExpression.is(DeclReferenceExprSyntax.self)
      && calledExpression.as(MemberAccessExprSyntax.self)?.isInit == false
      && arguments.allSatisfy(\.expression.isDiscardAssignmentOrFunction)
  }

  fileprivate var innermostFunctionCall: FunctionCallExprSyntax {
    arguments
      .lazy
      .compactMap { $0.expression.as(FunctionCallExprSyntax.self)?.innermostFunctionCall }
      .first ?? self
  }

  fileprivate var removingInnermostDiscardArguments: ExprSyntax {
    guard
      argumentsHasViolation,
      let calledExpression = calledExpression.as(MemberAccessExprSyntax.self),
      calledExpression.base == nil
    else {
      return ExprSyntax(self)
    }

    if arguments.allSatisfy({ $0.expression.is(DiscardAssignmentExprSyntax.self) }) {
      let newCalledExpression =
        calledExpression
        .with(\.trailingTrivia, rightParen?.trailingTrivia ?? Trivia())
      let newExpression = with(\.calledExpression, ExprSyntax(newCalledExpression))
        .with(\.leftParen, nil)
        .with(\.arguments, [])
        .with(\.rightParen, nil)
      return ExprSyntax(newExpression)
    }

    var copy = self
    for arg in arguments {
      if let newArgExpr = arg.expression.as(FunctionCallExprSyntax.self),
        let index = arguments.index(of: arg)
      {
        let newArg = arg.with(\.expression, newArgExpr.removingInnermostDiscardArguments)
        copy.arguments = copy.arguments.with(\.[index], newArg)
      }
    }
    return ExprSyntax(copy)
  }
}

extension ExprSyntax {
  fileprivate var isDiscardAssignmentOrFunction: Bool {
    `is`(DiscardAssignmentExprSyntax.self)
      || (`as`(FunctionCallExprSyntax.self)?.argumentsHasViolation == true)
  }
}

extension MemberAccessExprSyntax {
  fileprivate var isInit: Bool {
    lastToken(viewMode: .sourceAccurate)?.tokenKind == .keyword(.`init`)
  }
}
