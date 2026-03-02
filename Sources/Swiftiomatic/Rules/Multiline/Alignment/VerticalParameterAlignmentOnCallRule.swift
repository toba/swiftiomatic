import SwiftSyntax

struct VerticalParameterAlignmentOnCallRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = VerticalParameterAlignmentOnCallConfiguration()
}

extension VerticalParameterAlignmentOnCallRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension VerticalParameterAlignmentOnCallRule {}

extension VerticalParameterAlignmentOnCallRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      let arguments = node.arguments
      guard arguments.count > 1, let firstArg = arguments.first else {
        return
      }

      var firstArgumentLocation = locationConverter.location(
        for: firstArg.positionAfterSkippingLeadingTrivia,
      )

      var visitedLines = Set<Int>()
      var previousArgumentWasMultiline = false

      let violatingPositions: [AbsolutePosition] =
        arguments
        .compactMap { argument -> AbsolutePosition? in
          defer {
            previousArgumentWasMultiline = isMultiline(argument: argument)
          }

          let position = argument.positionAfterSkippingLeadingTrivia
          let location = locationConverter.location(for: position)
          guard location.line > firstArgumentLocation.line else {
            return nil
          }

          let (firstVisit, _) = visitedLines.insert(location.line)
          guard location.column != firstArgumentLocation.column, firstVisit else {
            return nil
          }

          // if this is the first element on a new line after a closure with multiple lines,
          // we reset the reference position
          if previousArgumentWasMultiline, firstVisit {
            firstArgumentLocation = location
            return nil
          }

          return position
        }

      violations.append(contentsOf: violatingPositions)
    }

    private func isMultiline(argument: LabeledExprListSyntax.Element) -> Bool {
      let expression = argument.expression
      let startPosition = locationConverter.location(
        for: expression.positionAfterSkippingLeadingTrivia,
      )
      let endPosition =
        locationConverter
        .location(for: expression.endPositionBeforeTrailingTrivia)

      return endPosition.line > startPosition.line
    }
  }
}
