import SwiftSyntax

struct NoSpaceInMethodCallRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NoSpaceInMethodCallConfiguration()
}

extension NoSpaceInMethodCallRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension NoSpaceInMethodCallRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.hasNoSpaceInMethodCallViolation else {
        return
      }

      violations.append(node.calledExpression.endPositionBeforeTrailingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.hasNoSpaceInMethodCallViolation else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode =
        node
        .with(\.calledExpression, node.calledExpression.with(\.trailingTrivia, []))
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var hasNoSpaceInMethodCallViolation: Bool {
    leftParen != nil && !calledExpression.is(TupleExprSyntax.self)
      && calledExpression.trailingTrivia.isNotEmpty
  }
}
