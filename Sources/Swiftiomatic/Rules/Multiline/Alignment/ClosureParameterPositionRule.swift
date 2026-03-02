import SwiftSyntax

struct ClosureParameterPositionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ClosureParameterPositionConfiguration()
}

extension ClosureParameterPositionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ClosureParameterPositionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClosureExprSyntax) {
      guard let signature = node.signature else {
        return
      }

      let leftBracePosition = node.leftBrace.positionAfterSkippingLeadingTrivia
      let startLine = locationConverter.location(for: leftBracePosition).line

      let positionsToCheck = signature.positionsToCheck
      guard let lastPosition = positionsToCheck.last else {
        return
      }

      // fast path: we can check the last position only, and if that
      // doesn't have a violation, we don't need to check any other positions,
      // since calling `locationConverter.location(for:)` is expensive
      let lastPositionLine = locationConverter.location(for: lastPosition).line
      if lastPositionLine == startLine {
        return
      }
      let localViolations = positionsToCheck.dropLast().filter { position in
        locationConverter.location(for: position).line != startLine
      }

      violations.append(contentsOf: localViolations)
      violations.append(lastPosition)
    }
  }
}

extension ClosureSignatureSyntax {
  fileprivate var positionsToCheck: [AbsolutePosition] {
    var positions: [AbsolutePosition] = []
    if let captureItems = capture?.items {
      positions
        .append(contentsOf: captureItems.map(\.name.positionAfterSkippingLeadingTrivia))
    }

    if let input = parameterClause?.as(ClosureShorthandParameterListSyntax.self) {
      positions.append(contentsOf: input.map(\.positionAfterSkippingLeadingTrivia))
    } else if let input = parameterClause?.as(ClosureParameterClauseSyntax.self) {
      positions.append(contentsOf: input.parameters.map(\.positionAfterSkippingLeadingTrivia))
    }

    return positions
  }
}
