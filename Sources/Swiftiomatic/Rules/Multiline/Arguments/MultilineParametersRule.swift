import SwiftSyntax

struct MultilineParametersRule {
  var options = MultilineParametersOptions()

  static let configuration = MultilineParametersConfiguration()

  static let description = RuleDescription(
    identifier: "multiline_parameters",
    name: "Multiline Parameters",
    description:
      "Functions and methods parameters should be either on the same line, or one per line",
    isOptIn: true,
    nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
    triggeringExamples: MultilineParametersRuleExamples.triggeringExamples,
  )
}

extension MultilineParametersRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineParametersRule {}

extension MultilineParametersRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
