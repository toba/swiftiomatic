import SwiftSyntax

struct UntypedErrorInCatchRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UntypedErrorInCatchConfiguration()
}

extension UntypedErrorInCatchRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension UntypedErrorInCatchRule {}

extension CatchItemSyntax {
  fileprivate var isIdentifierPattern: Bool {
    guard whereClause == nil else {
      return false
    }

    if let pattern = pattern?.as(ValueBindingPatternSyntax.self) {
      return pattern.pattern.is(IdentifierPatternSyntax.self)
    }

    if let pattern = pattern?.as(ExpressionPatternSyntax.self),
      let tupleExpr = pattern.expression.as(TupleExprSyntax.self),
      let tupleElement = tupleExpr.elements.onlyElement,
      let unresolvedPattern = tupleElement.expression.as(PatternExprSyntax.self),
      let valueBindingPattern = unresolvedPattern.pattern.as(ValueBindingPatternSyntax.self)
    {
      return valueBindingPattern.pattern.is(IdentifierPatternSyntax.self)
    }

    return false
  }
}

extension UntypedErrorInCatchRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: CatchClauseSyntax) {
      guard let item = node.catchItems.onlyElement, item.isIdentifierPattern else {
        return
      }
      violations.append(node.catchKeyword.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
      guard let item = node.catchItems.onlyElement, item.isIdentifierPattern else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(
        node
          .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .spaces(1)))
          .with(\.catchItems, CatchItemListSyntax([])),
      )
    }
  }
}
