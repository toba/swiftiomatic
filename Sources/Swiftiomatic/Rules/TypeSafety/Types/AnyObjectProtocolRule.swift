import SwiftSyntax

struct AnyObjectProtocolRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "any_object_protocol",
    name: "AnyObject Protocol",
    description: "Prefer `AnyObject` over `class` in protocol definitions",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("protocol Foo: AnyObject {}"),
      Example("protocol Foo: Sendable {}"),
    ],
    triggeringExamples: [
      Example("protocol Foo: ↓class {}"),
    ],
  )
}

extension AnyObjectProtocolRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension AnyObjectProtocolRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ProtocolDeclSyntax) {
      guard let inheritanceClause = node.inheritanceClause else { return }
      for type in inheritanceClause.inheritedTypes {
        if let simpleType = type.type.as(IdentifierTypeSyntax.self),
          simpleType.name.tokenKind == .keyword(.class)
        {
          violations.append(simpleType.name.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }
}
