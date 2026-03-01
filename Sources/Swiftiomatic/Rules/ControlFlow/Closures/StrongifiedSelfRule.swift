import SwiftSyntax

struct StrongifiedSelfRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "strongified_self",
    name: "Strongified Self",
    description: "Remove backticks around `self` in optional unwrap expressions",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("guard let self = self else { return }"),
      Example("guard let self else { return }"),
    ],
    triggeringExamples: [
      Example("guard let ↓`self` = self else { return }"),
    ],
  )
}

extension StrongifiedSelfRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension StrongifiedSelfRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      // Check for `let \`self\` = self` pattern
      if let pattern = node.pattern.as(IdentifierPatternSyntax.self),
        pattern.identifier.text == "self",
        pattern.identifier.tokenKind == .identifier("`self`")
      {
        violations.append(pattern.identifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
