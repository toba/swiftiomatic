import SwiftSyntax

struct MultilineParametersRule: Rule {
  var configuration = MultilineParametersConfiguration()

  static let description = RuleDescription(
    identifier: "multiline_parameters",
    name: "Multiline Parameters",
    description:
      "Functions and methods parameters should be either on the same line, or one per line",
    nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
    triggeringExamples: MultilineParametersRuleExamples.triggeringExamples,
  )
}

extension MultilineParametersRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension MultilineParametersRule: OptInRule {}

extension MultilineParametersRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      if containsViolation(for: node.signature) {
        violations.append(node.name.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if containsViolation(for: node.signature) {
        violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    private func containsViolation(for signature: FunctionSignatureSyntax) -> Bool {
      let parameterPositions = signature.parameterClause.parameters.map(
        \.positionAfterSkippingLeadingTrivia,
      )
      return containsMultilineViolation(
        positions: parameterPositions,
        locationConverter: locationConverter,
        allowsSingleLine: configuration.allowsSingleLine,
        maxSingleLine: configuration.maxNumberOfSingleLineParameters,
      )
    }
  }
}
