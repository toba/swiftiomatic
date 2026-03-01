import SwiftSyntax

struct ImplicitGetterRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "implicit_getter",
    name: "Implicit Getter",
    description: "Computed read-only properties and subscripts should avoid using the get keyword.",
    nonTriggeringExamples: ImplicitGetterRuleExamples.nonTriggeringExamples,
    triggeringExamples: ImplicitGetterRuleExamples.triggeringExamples,
  )
}

extension ImplicitGetterRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

private enum ViolationKind {
  case `subscript`, property

  var violationDescription: String {
    switch self {
    case .subscript:
      return "Computed read-only subscripts should avoid using the get keyword"
    case .property:
      return "Computed read-only properties should avoid using the get keyword"
    }
  }
}

extension ImplicitGetterRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AccessorBlockSyntax) {
      guard node.accessorsList.count == 1,
        let getAccessor = node.getAccessor,
        getAccessor.effectSpecifiers == nil,
        getAccessor.modifiers.isEmpty,
        getAccessor.attributes.isEmpty,
        getAccessor.body != nil
      else {
        return
      }

      let kind: ViolationKind =
        node.parent?.as(SubscriptDeclSyntax.self) == nil ? .property : .subscript
      violations.append(
        SyntaxViolation(
          position: getAccessor.positionAfterSkippingLeadingTrivia,
          reason: kind.violationDescription,
        ),
      )
    }
  }
}
