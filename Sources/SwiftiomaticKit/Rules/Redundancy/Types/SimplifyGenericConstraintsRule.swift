import SwiftSyntax

struct SimplifyGenericConstraintsRule {
  static let id = "simplify_generic_constraints"
  static let name = "Simplify Generic Constraints"
  static let summary =
    "Use inline generic constraints instead of where clauses for simple protocol conformances"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("func foo<T: Hashable>(_ value: T) {}"),
      Example("struct Foo<T: Equatable> {}"),
      Example("func foo<T>(_ value: T) where T.Element: Equatable {}"),
      Example("func foo<T: Hashable>(_ value: T) where T: Codable {}"),
      Example("extension Array where Element: Equatable {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("func ↓foo<T>(_ value: T) where T: Hashable {}"),
      Example("struct ↓Foo<T> where T: Equatable {}"),
      Example("class ↓Bar<T, U> where T: Hashable, U: Codable {}"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SimplifyGenericConstraintsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SimplifyGenericConstraintsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let genericClause = node.genericParameterClause,
        let whereClause = node.genericWhereClause
      else { return }

      if hasSimplifiableConstraints(genericClause: genericClause, whereClause: whereClause) {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason: "Where clause constraints can be moved inline to generic parameter list",
          ),
        )
      }
    }

    override func visitPost(_ node: StructDeclSyntax) {
      guard let genericClause = node.genericParameterClause,
        let whereClause = node.genericWhereClause
      else { return }

      if hasSimplifiableConstraints(genericClause: genericClause, whereClause: whereClause) {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason: "Where clause constraints can be moved inline to generic parameter list",
          ),
        )
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      guard let genericClause = node.genericParameterClause,
        let whereClause = node.genericWhereClause
      else { return }

      if hasSimplifiableConstraints(genericClause: genericClause, whereClause: whereClause) {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason: "Where clause constraints can be moved inline to generic parameter list",
          ),
        )
      }
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      guard let genericClause = node.genericParameterClause,
        let whereClause = node.genericWhereClause
      else { return }

      if hasSimplifiableConstraints(genericClause: genericClause, whereClause: whereClause) {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason: "Where clause constraints can be moved inline to generic parameter list",
          ),
        )
      }
    }

    /// Check if the where clause has protocol conformance constraints that could be moved inline
    private func hasSimplifiableConstraints(
      genericClause: GenericParameterClauseSyntax,
      whereClause: GenericWhereClauseSyntax,
    ) -> Bool {
      let genericParamNames = Set(genericClause.parameters.map(\.name.text))

      for requirement in whereClause.requirements {
        // Only consider conformance constraints (T: Protocol), not same-type (T == Foo)
        guard
          let conformance = requirement.requirement
            .as(ConformanceRequirementSyntax.self)
        else {
          continue
        }

        // The left type must be a simple generic parameter name (not T.Element)
        guard let leftIdent = conformance.leftType.as(IdentifierTypeSyntax.self),
          genericParamNames.contains(leftIdent.name.text)
        else {
          continue
        }

        // Check that this parameter doesn't already have an inline constraint
        let paramHasInlineConstraint = genericClause.parameters.contains { param in
          param.name.text == leftIdent.name.text && param.inheritedType != nil
        }

        // If the parameter has no inline constraint, the where clause could be simplified
        if !paramHasInlineConstraint {
          return true
        }
      }

      return false
    }
  }
}
