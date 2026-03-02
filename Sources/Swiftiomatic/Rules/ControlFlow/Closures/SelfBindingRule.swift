import SwiftSyntax

// MARK: - SelfBindingRule

struct SelfBindingRule {
    static let id = "self_binding"
    static let name = "Self Binding"
    static let summary = "Re-bind `self` to a consistent identifier name."
    static let isCorrectable = true
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("if let self = self { return }"),
              Example("guard let self = self else { return }"),
              Example("if let this = this { return }"),
              Example("guard let this = this else { return }"),
              Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
              Example(
                "guard let this = self else { return }",
                configuration: ["bind_identifier": "this"],
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("if let ↓`self` = self { return }"),
              Example("guard let ↓`self` = self else { return }"),
              Example("if let ↓this = self { return }"),
              Example("guard let ↓this = self else { return }"),
              Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]),
              Example(
                "guard let ↓self = self else { return }",
                configuration: ["bind_identifier": "this"],
              ),
              Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]),
              Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("if let ↓`self` = self { return }"):
                Example("if let self = self { return }"),
              Example("guard let ↓`self` = self else { return }"):
                Example("guard let self = self else { return }"),
              Example("if let ↓this = self { return }"):
                Example("if let self = self { return }"),
              Example("guard let ↓this = self else { return }"):
                Example("guard let self = self else { return }"),
              Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]):
                Example(
                  "if let this = self { return }",
                  configuration: ["bind_identifier": "this"],
                ),
              Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]):
                Example(
                  "if let this = self { return }",
                  configuration: ["bind_identifier": "this"],
                ),
              Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]):
                Example(
                  "guard let this = self else { return }",
                  configuration: ["bind_identifier": "this"],
                ),
            ]
    }
  var options = SelfBindingOptions()

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
