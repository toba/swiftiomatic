import Foundation
import SwiftSyntax

struct GenericTypeNameRule {
  var options = NameOptions<Self>(
    minLengthWarning: 1,
    minLengthError: 0,
    maxLengthWarning: 20,
    maxLengthError: 1000,
  )

  static let configuration = GenericTypeNameConfiguration()
}

extension GenericTypeNameRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension GenericTypeNameRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: GenericParameterSyntax) {
      let name = node.name.text
      guard !name.isEmpty,
        !configuration.shouldExclude(name: name),
        node.specifier?.tokenKind != .keyword(.let)
      else {
        return
      }

      if !configuration.containsOnlyAllowedCharacters(name: name) {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: """
              Generic type name '\(
                            name
                        )' should only contain alphanumeric and other allowed characters
              """,
            severity: configuration.unallowedSymbolsSeverity.severity,
          ),
        )
      } else if let caseCheckSeverity = configuration.validatesStartWithLowercase.severity,
        name.first?.isUppercase != true
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Generic type name '\(name)' should start with an uppercase character",
            severity: caseCheckSeverity,
          ),
        )
      } else if let severity = configuration.severity(forLength: name.count) {
        let reason =
          "Generic type name '\(name)' should be between \(configuration.minLengthThreshold) and "
          + "\(configuration.maxLengthThreshold) characters long"
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: reason,
            severity: severity,
          ),
        )
      }
    }
  }
}
