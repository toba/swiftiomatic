import SwiftSyntax

struct StrongifiedSelfRule {
  static let id = "strongified_self"
  static let name = "Strongified Self"
  static let summary = "Remove backticks around `self` in optional unwrap expressions"
  static let scope: Scope = .suggest
  static var nonTriggeringExamples: [Example] {
    [
      Example("guard let self = self else { return }"),
      Example("guard let self else { return }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("guard let ↓`self` = self else { return }")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension StrongifiedSelfRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension StrongifiedSelfRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      // Check for `let \`self\` = self` pattern
      // In modern SwiftSyntax, backticked `self` may parse as .keyword(.self)
      // or .identifier("self"); check trimmedDescription for backticks
      if let pattern = node.pattern.as(IdentifierPatternSyntax.self),
        pattern.identifier.trimmedDescription == "`self`"
      {
        violations.append(pattern.identifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
