import SwiftSyntax

struct ImplicitGetterRule {
    static let id = "implicit_getter"
    static let name = "Implicit Getter"
    static let summary = "Computed read-only properties and subscripts should avoid using the get keyword."
    static var nonTriggeringExamples: [Example] {
        ImplicitGetterRuleExamples.nonTriggeringExamples
    }
    static var triggeringExamples: [Example] {
        ImplicitGetterRuleExamples.triggeringExamples
    }
  var options = SeverityConfiguration<Self>(.warning)

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
