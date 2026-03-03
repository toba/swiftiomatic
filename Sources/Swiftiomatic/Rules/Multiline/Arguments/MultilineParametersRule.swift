import SwiftSyntax

struct MultilineParametersRule {
    static let id = "multiline_parameters"
    static let name = "Multiline Parameters"
    static let summary =
        "Functions and methods parameters should be either on the same line, or one per line"
    static let isOptIn = true
    var options = MultilineParametersOptions()
}

extension MultilineParametersRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

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
