import SwiftSyntax

struct SwitchCaseAlignmentRule {
  var options = SwitchCaseAlignmentOptions()

  static let configuration = SwitchCaseAlignmentConfiguration()
}

extension SwitchCaseAlignmentRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SwitchCaseAlignmentRule {
  final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchExprSyntax) {
      guard node.cases.isNotEmpty,
        let firstCasePosition = node.cases.first?.positionAfterSkippingLeadingTrivia
      else {
        return
      }

      let closingBracePosition = node.rightBrace.positionAfterSkippingLeadingTrivia
      let closingBraceLocation = locationConverter.location(for: closingBracePosition)
      let switchKeywordPosition = node.switchKeyword.positionAfterSkippingLeadingTrivia
      let switchKeywordLocation = locationConverter.location(for: switchKeywordPosition)

      if configuration.ignoreOneLiners,
        switchKeywordLocation.line == closingBraceLocation.line
      {
        return
      }

      let closingBraceColumn = closingBraceLocation.column
      let firstCaseColumn = locationConverter.location(for: firstCasePosition).column

      for `case` in node.cases where `case`.is(SwitchCaseSyntax.self) {
        let casePosition = `case`.positionAfterSkippingLeadingTrivia
        let caseColumn = locationConverter.location(for: casePosition).column

        let hasViolation =
          (configuration.indentedCases && caseColumn <= closingBraceColumn)
          || (!configuration.indentedCases && caseColumn != closingBraceColumn)
          || (configuration.indentedCases && caseColumn != firstCaseColumn)

        guard hasViolation else {
          continue
        }

        let reason = """
          Case statements should \
          \(configuration.indentedCases ? "be indented within" : "vertically aligned with") \
          their closing brace
          """

        violations.append(SyntaxViolation(position: casePosition, reason: reason))
      }
    }
  }
}
