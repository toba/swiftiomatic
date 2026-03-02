import SwiftSyntax

struct OptionalDataStringConversionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = OptionalDataStringConversionConfiguration()
}

extension OptionalDataStringConversionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OptionalDataStringConversionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if node.baseName.text == "String",
        let parent = node.parent?.as(FunctionCallExprSyntax.self),
        parent.arguments.map(\.label?.text) == ["decoding", "as"],
        let expr = parent.arguments.last?.expression.as(MemberAccessExprSyntax.self),
        expr.base?.description == "UTF8",
        expr.declName.baseName.description == "self"
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
