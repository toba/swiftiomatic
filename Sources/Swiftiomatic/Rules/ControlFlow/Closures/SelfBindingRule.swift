import SwiftSyntax

// MARK: - SelfBindingRule

struct SelfBindingRule {
  var options = SelfBindingOptions()

  static let configuration = SelfBindingConfiguration()
}

extension SelfBindingRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SelfBindingRule {}

extension SelfBindingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
        identifierPattern.identifier.text != configuration.bindIdentifier
      {
        var hasViolation = false
        if let initializerIdentifier = node.initializer?.value
          .as(DeclReferenceExprSyntax.self)
        {
          hasViolation = initializerIdentifier.baseName.text == "self"
        } else if node.initializer == nil {
          hasViolation =
            identifierPattern.identifier.text == "self"
            && configuration
              .bindIdentifier != "self"
        }

        if hasViolation {
          violations.append(
            SyntaxViolation(
              position: identifierPattern.positionAfterSkippingLeadingTrivia,
              reason: "`self` should always be re-bound to `\(configuration.bindIdentifier)`",
            ),
          )
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: OptionalBindingConditionSyntax)
      -> OptionalBindingConditionSyntax
    {
      guard let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
        identifierPattern.identifier.text != configuration.bindIdentifier
      else {
        return super.visit(node)
      }

      if let initializerIdentifier = node.initializer?.value.as(DeclReferenceExprSyntax.self),
        initializerIdentifier.baseName.text == "self"
      {
        numberOfCorrections += 1
        let newPattern = PatternSyntax(
          identifierPattern
            .with(
              \.identifier,
              identifierPattern.identifier
                .with(\.tokenKind, .identifier(configuration.bindIdentifier)),
            ),
        )

        return super.visit(node.with(\.pattern, newPattern))
      }
      if node.initializer == nil,
        identifierPattern.identifier.text == "self",
        configuration.bindIdentifier != "self"
      {
        numberOfCorrections += 1
        let newPattern = PatternSyntax(
          identifierPattern
            .with(
              \.identifier,
              identifierPattern.identifier
                .with(\.tokenKind, .identifier(configuration.bindIdentifier)),
            ),
        )

        let newInitializer = InitializerClauseSyntax(
          value: DeclReferenceExprSyntax(
            baseName: .keyword(
              .`self`,
              leadingTrivia: .space,
              trailingTrivia: identifierPattern.trailingTrivia,
            ),
          ),
        )

        let newNode =
          node
          .with(\.pattern, newPattern)
          .with(\.initializer, newInitializer)
        return super.visit(newNode)
      }
      return super.visit(node)
    }
  }
}
