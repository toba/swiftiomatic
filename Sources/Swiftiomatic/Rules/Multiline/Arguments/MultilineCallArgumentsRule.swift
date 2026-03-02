import SwiftSyntax

struct MultilineCallArgumentsRule {
  var options = MultilineCallArgumentsOptions()

  static let configuration = MultilineCallArgumentsConfiguration()
}

extension MultilineCallArgumentsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineCallArgumentsRule {}

extension MultilineCallArgumentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if containsViolation(
        parameterPositions: node.arguments.map(\.positionAfterSkippingLeadingTrivia),
      ) {
        violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
      }
    }

    private func containsViolation(parameterPositions: [AbsolutePosition]) -> Bool {
      containsMultilineViolation(
        positions: parameterPositions,
        locationConverter: locationConverter,
        allowsSingleLine: configuration.allowsSingleLine,
        maxSingleLine: configuration.maxNumberOfSingleLineParameters,
      )
    }
  }
}
