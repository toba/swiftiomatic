import SwiftSyntax

struct AnyObjectProtocolRule {
    static let id = "any_object_protocol"
    static let name = "AnyObject Protocol"
    static let summary = "Prefer `AnyObject` over `class` in protocol definitions"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example("protocol Foo: AnyObject {}"),
              Example("protocol Foo: Sendable {}"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("protocol Foo: ↓class {}"),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension AnyObjectProtocolRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
