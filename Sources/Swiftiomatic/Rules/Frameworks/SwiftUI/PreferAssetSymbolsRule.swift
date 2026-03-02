import SwiftSyntax

struct PreferAssetSymbolsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferAssetSymbolsConfiguration()
}

extension PreferAssetSymbolsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferAssetSymbolsRule {}

extension PreferAssetSymbolsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      // Check for UIImage(named:) or SwiftUI Image(_:) calls
      if isImageInit(node: node, className: "UIImage", argumentLabel: "named")
        || isImageInit(node: node, className: "Image", argumentLabel: nil)
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    private func isImageInit(
      node: FunctionCallExprSyntax, className: String, argumentLabel: String?,
    ) -> Bool {
      // Check if this is the specified class or class.init call using syntax tree matching
      guard isImageCall(node.calledExpression, className: className) else {
        return false
      }

      // Check if the first argument has the expected label and is a string literal
      guard let firstArgument = node.arguments.first,
        firstArgument.label?.text == argumentLabel,
        let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
        stringLiteral.isConstantString
      else {
        return false
      }

      return true
    }

    private func isImageCall(_ expression: ExprSyntax, className: String) -> Bool {
      // Match ClassName directly
      if let identifierExpr = expression.as(DeclReferenceExprSyntax.self) {
        return identifierExpr.baseName.text == className
      }

      // Match ClassName.init
      if let memberAccessExpr = expression.as(MemberAccessExprSyntax.self),
        let baseExpr = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self),
        baseExpr.baseName.text == className,
        memberAccessExpr.declName.baseName.text == "init"
      {
        return true
      }

      return false
    }
  }
}

extension StringLiteralExprSyntax {
  fileprivate var isConstantString: Bool {
    segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
  }
}
