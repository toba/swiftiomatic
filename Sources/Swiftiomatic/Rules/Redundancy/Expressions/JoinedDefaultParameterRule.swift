import SwiftSyntax

struct JoinedDefaultParameterRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = JoinedDefaultParameterConfiguration()
}

extension JoinedDefaultParameterRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension JoinedDefaultParameterRule {}

extension JoinedDefaultParameterRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let violationPosition = node.violationPosition {
        violations.append(violationPosition)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.violationPosition != nil else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode = node.with(\.arguments, [])
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var violationPosition: AbsolutePosition? {
    guard let argument = arguments.first,
      let memberExp = calledExpression.as(MemberAccessExprSyntax.self),
      memberExp.declName.baseName.text == "joined",
      argument.label?.text == "separator",
      let strLiteral = argument.expression.as(StringLiteralExprSyntax.self),
      strLiteral.isEmptyString
    else {
      return nil
    }

    return argument.positionAfterSkippingLeadingTrivia
  }
}
