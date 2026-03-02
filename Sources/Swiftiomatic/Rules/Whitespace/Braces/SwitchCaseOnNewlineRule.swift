import SwiftSyntax

struct SwitchCaseOnNewlineRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SwitchCaseOnNewlineConfiguration()
}

extension SwitchCaseOnNewlineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SwitchCaseOnNewlineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseSyntax) {
      let caseEndLine =
        locationConverter
        .location(for: node.label.endPositionBeforeTrailingTrivia)
        .line
      let statementsPosition = node.statements.positionAfterSkippingLeadingTrivia
      let statementStartLine = locationConverter.location(for: statementsPosition).line
      if statementStartLine == caseEndLine {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
