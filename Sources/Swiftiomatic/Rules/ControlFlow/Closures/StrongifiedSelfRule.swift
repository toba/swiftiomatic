import SwiftSyntax

struct StrongifiedSelfRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = StrongifiedSelfConfiguration()
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
      if let pattern = node.pattern.as(IdentifierPatternSyntax.self),
        pattern.identifier.text == "self",
        pattern.identifier.tokenKind == .identifier("`self`")
      {
        violations.append(pattern.identifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
