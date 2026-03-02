import SwiftSyntax

struct AnonymousArgumentInMultilineClosureRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = AnonymousArgumentInMultilineClosureConfiguration()
}

extension AnonymousArgumentInMultilineClosureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AnonymousArgumentInMultilineClosureRule {}

extension AnonymousArgumentInMultilineClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      let startLocation = locationConverter.location(
        for: node.leftBrace.positionAfterSkippingLeadingTrivia,
      )
      let endLocation = locationConverter.location(
        for: node.rightBrace.endPositionBeforeTrailingTrivia,
      )
      return startLocation.line == endLocation.line ? .skipChildren : .visitChildren
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if case .dollarIdentifier = node.baseName.tokenKind {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
