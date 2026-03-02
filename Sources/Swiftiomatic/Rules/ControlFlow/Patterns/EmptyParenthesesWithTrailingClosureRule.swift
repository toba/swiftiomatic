import SwiftSyntax

struct EmptyParenthesesWithTrailingClosureRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = EmptyParenthesesWithTrailingClosureConfiguration()
}

extension EmptyParenthesesWithTrailingClosureRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension EmptyParenthesesWithTrailingClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let position = node.violationPosition else {
        return
      }

      violations.append(position)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.violationPosition != nil else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode =
        node
        .with(\.leftParen, nil)
        .with(\.rightParen, nil)
        .with(
          \.trailingClosure,
          node.trailingClosure?.with(\.leadingTrivia, .spaces(1)),
        )
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var violationPosition: AbsolutePosition? {
    guard trailingClosure != nil,
      let leftParen,
      arguments.isEmpty
    else {
      return nil
    }
    return leftParen.positionAfterSkippingLeadingTrivia
  }
}
