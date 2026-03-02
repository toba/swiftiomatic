import SwiftSyntax

struct FatalErrorMessageRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = FatalErrorMessageConfiguration()
}

extension FatalErrorMessageRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FatalErrorMessageRule {}

extension FatalErrorMessageRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let expression = node.calledExpression.as(DeclReferenceExprSyntax.self),
        expression.baseName.text == "fatalError",
        node.arguments.isEmptyOrEmptyString
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension LabeledExprListSyntax {
  fileprivate var isEmptyOrEmptyString: Bool {
    if isEmpty {
      return true
    }
    return count == 1
      && first?.expression.as(StringLiteralExprSyntax.self)?
        .isEmptyString == true
  }
}
