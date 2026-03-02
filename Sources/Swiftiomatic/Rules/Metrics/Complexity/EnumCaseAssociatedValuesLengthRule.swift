import SwiftSyntax

struct EnumCaseAssociatedValuesLengthRule {
  var options = SeverityLevelsConfiguration<Self>(warning: 5, error: 6)

  static let configuration = EnumCaseAssociatedValuesLengthConfiguration()
}

extension EnumCaseAssociatedValuesLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension EnumCaseAssociatedValuesLengthRule {}

extension EnumCaseAssociatedValuesLengthRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumCaseElementSyntax) {
      guard let associatedValue = node.parameterClause,
        case let enumCaseAssociatedValueCount = associatedValue.parameters.count,
        enumCaseAssociatedValueCount >= configuration.warning
      else {
        return
      }

      let violationSeverity: Severity
      if let errorConfig = configuration.error,
        enumCaseAssociatedValueCount >= errorConfig
      {
        violationSeverity = .error
      } else {
        violationSeverity = .warning
      }

      let reason =
        "Enum case \(node.name.text) should contain "
        + "less than \(configuration.warning) associated values: "
        + "currently contains \(enumCaseAssociatedValueCount)"
      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason: reason,
          severity: violationSeverity,
        ),
      )
    }
  }
}
