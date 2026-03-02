import SwiftSyntax

struct NonOptionalStringDataConversionRule {
  var options = NonOptionalStringDataConversionOptions()

  static let configuration = NonOptionalStringDataConversionConfiguration()
}

extension NonOptionalStringDataConversionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NonOptionalStringDataConversionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      if node.declName.baseName.text == "data",
        let parent = node.parent?.as(FunctionCallExprSyntax.self),
        let argument = parent.arguments.onlyElement,
        argument.label?.text == "using",
        argument.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true,
        let base = node.base,
        base.is(StringLiteralExprSyntax.self) || configuration.includeVariables
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension MemberAccessExprSyntax {
  fileprivate var isUTF8: Bool {
    declName.baseName.text == "utf8"
  }
}
