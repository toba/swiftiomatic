import Foundation
import SwiftSyntax

struct TrailingCommaRule {
  var options = TrailingCommaOptions()

  static let configuration = TrailingCommaConfiguration()
}

extension TrailingCommaRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension TrailingCommaRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DictionaryElementListSyntax) {
      guard let lastElement = node.last else {
        return
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    override func visitPost(_ node: ArrayElementListSyntax) {
      guard let lastElement = node.last else {
        return
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    private func violation(for position: AbsolutePosition) -> SyntaxViolation {
      let reason =
        configuration.mandatoryComma
        ? "Multi-line collection literals should have trailing commas"
        : "Collection literals should not have trailing commas"
      return SyntaxViolation(position: position, reason: reason)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: DictionaryElementListSyntax) -> DictionaryElementListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        let newTrailingTrivia = (lastElement.value.trailingTrivia)
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingComma, nil)
              .with(\.trailingTrivia, newTrailingTrivia),
          )
        return super.visit(newNode)
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingTrivia, [])
              .with(\.trailingComma, .commaToken())
              .with(\.trailingTrivia, lastElement.trailingTrivia),
          )
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: ArrayElementListSyntax) -> ArrayElementListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingComma, nil)
              .with(
                \.trailingTrivia,
                (lastElement.expression.trailingTrivia)
                  .appending(trivia: commaToken.leadingTrivia)
                  .appending(trivia: commaToken.trailingTrivia),
              ),
          )
        return super.visit(newNode)
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(
                \.expression,
                lastElement.expression.with(\.trailingTrivia, []),
              )
              .with(\.trailingComma, .commaToken())
              .with(\.trailingTrivia, lastElement.expression.trailingTrivia),
          )
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }
  }
}

extension SourceLocationConverter {
  fileprivate func isSingleLine(node: some SyntaxProtocol) -> Bool {
    location(for: node.positionAfterSkippingLeadingTrivia).line
      == location(for: node.endPositionBeforeTrailingTrivia).line
  }
}

extension Trivia {
  fileprivate func appending(trivia: Trivia) -> Trivia {
    var result = self
    for piece in trivia.pieces {
      result = result.appending(piece)
    }
    return result
  }
}
