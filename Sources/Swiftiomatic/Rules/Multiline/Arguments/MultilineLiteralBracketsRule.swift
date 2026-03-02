import Foundation
import SwiftSyntax

struct MultilineLiteralBracketsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = MultilineLiteralBracketsConfiguration()
}

extension MultilineLiteralBracketsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineLiteralBracketsRule {}

extension MultilineLiteralBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ArrayExprSyntax) {
      validate(
        node,
        openingToken: node.leftSquare,
        closingToken: node.rightSquare,
        firstElement: node.elements.first?.expression,
        lastElement: node.elements.last?.expression,
      )
    }

    override func visitPost(_ node: DictionaryExprSyntax) {
      switch node.content {
      case .colon:
        break
      case .elements(let elements):
        validate(
          node,
          openingToken: node.leftSquare,
          closingToken: node.rightSquare,
          firstElement: elements.first?.key,
          lastElement: elements.last?.value,
        )
      }
    }

    private func validate(
      _ node: some ExprSyntaxProtocol,
      openingToken: TokenSyntax,
      closingToken: TokenSyntax,
      firstElement: (some ExprSyntaxProtocol)?,
      lastElement: (some ExprSyntaxProtocol)?,
    ) {
      guard let firstElement, let lastElement,
        isMultiline(node)
      else {
        return
      }

      if areOnTheSameLine(openingToken, firstElement) {
        // don't skip trivia to keep violations in the same position as the legacy implementation
        violations.append(firstElement.position)
      }

      if areOnTheSameLine(lastElement, closingToken) {
        violations.append(closingToken.positionAfterSkippingLeadingTrivia)
      }
    }

    private func isMultiline(_ node: some ExprSyntaxProtocol) -> Bool {
      let startLocation =
        locationConverter
        .location(for: node.positionAfterSkippingLeadingTrivia)
      let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)

      return endLocation.line > startLocation.line
    }

    private func areOnTheSameLine(_ first: some SyntaxProtocol, _ second: some SyntaxProtocol)
      -> Bool
    {
      let firstLocation =
        locationConverter
        .location(for: first.endPositionBeforeTrailingTrivia)
      let secondLocation = locationConverter.location(
        for: second.positionAfterSkippingLeadingTrivia,
      )

      return firstLocation.line == secondLocation.line
    }
  }
}
