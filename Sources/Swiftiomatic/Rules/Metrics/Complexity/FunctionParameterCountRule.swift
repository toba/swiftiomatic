import SwiftSyntax

struct FunctionParameterCountRule {
  var options = FunctionParameterCountOptions()

  static let configuration = FunctionParameterCountConfiguration()
}

extension FunctionParameterCountRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FunctionParameterCountRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard !node.modifiers.contains(keyword: .override) else {
        return
      }

      let parameterList = node.signature.parameterClause.parameters
      guard
        let minThreshold = configuration.severityConfiguration.params.map(\.value)
          .min(by: <)
      else {
        return
      }

      let allParameterCount = parameterList.count
      if allParameterCount < minThreshold {
        return
      }

      var parameterCount = allParameterCount
      if configuration.ignoresDefaultParameters {
        parameterCount -= parameterList.count(where: { $0.defaultValue != nil })
      }

      for parameter in configuration.severityConfiguration.params
      where parameterCount > parameter.value {
        let reason =
          "Function should have \(configuration.severityConfiguration.warning) parameters "
          + "or less: it currently has \(parameterCount)"

        violations.append(
          SyntaxViolation(
            position: node.funcKeyword.positionAfterSkippingLeadingTrivia,
            reason: reason,
            severity: parameter.severity,
          ),
        )
        return
      }
    }
  }
}
