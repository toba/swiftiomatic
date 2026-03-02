import SwiftSyntax

struct ShorthandOptionalBindingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ShorthandOptionalBindingConfiguration()
}

extension ShorthandOptionalBindingRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ShorthandOptionalBindingRule {}

extension ShorthandOptionalBindingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if node.isShadowingOptionalBinding {
        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: OptionalBindingConditionSyntax)
      -> OptionalBindingConditionSyntax
    {
      guard node.isShadowingOptionalBinding else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode =
        node
        .with(\.initializer, nil)
        .with(\.pattern, node.pattern.with(\.trailingTrivia, node.trailingTrivia))
      return super.visit(newNode)
    }
  }
}

extension OptionalBindingConditionSyntax {
  fileprivate var isShadowingOptionalBinding: Bool {
    if let id = pattern.as(IdentifierPatternSyntax.self),
      let value = initializer?.value.as(DeclReferenceExprSyntax.self),
      id.identifier.text == value.baseName.text
    {
      return true
    }
    return false
  }
}
