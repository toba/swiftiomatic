import SwiftSyntax

struct ReturnArrowWhitespaceRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ReturnArrowWhitespaceConfiguration()
}

extension ReturnArrowWhitespaceRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ReturnArrowWhitespaceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionTypeSyntax) {
      if let violation = node.returnClause.arrow.arrowViolation {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: FunctionSignatureSyntax) {
      if let output = node.returnClause, let violation = output.arrow.arrowViolation {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: ClosureSignatureSyntax) {
      if let output = node.returnClause, let violation = output.arrow.arrowViolation {
        violations.append(violation)
      }
    }
  }
}

extension TokenSyntax {
  fileprivate var arrowViolation: SyntaxViolation? {
    guard let previousToken = previousToken(viewMode: .sourceAccurate),
      let nextToken = nextToken(viewMode: .sourceAccurate)
    else {
      return nil
    }

    var start: AbsolutePosition?
    var end: AbsolutePosition?
    var correction = " -> "

    if previousToken.trailingTrivia != .space, !leadingTrivia.containsNewlines() {
      start = previousToken.endPositionBeforeTrailingTrivia
      end = endPosition

      if nextToken.leadingTrivia.containsNewlines() {
        correction = " ->"
      }
    }

    if trailingTrivia != .space, !nextToken.leadingTrivia.containsNewlines() {
      if leadingTrivia.containsNewlines() {
        start = positionAfterSkippingLeadingTrivia
        correction = "-> "
      } else {
        start = previousToken.endPositionBeforeTrailingTrivia
      }
      end = endPosition
    }

    guard let start, let end else {
      return nil
    }

    return .init(
      position: start, correction: .init(start: start, end: end, replacement: correction),
    )
  }
}
