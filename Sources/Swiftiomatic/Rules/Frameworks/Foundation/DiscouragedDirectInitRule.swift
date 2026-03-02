import SwiftSyntax

struct DiscouragedDirectInitRule {
  var options = DiscouragedDirectInitOptions()

  static let configuration = DiscouragedDirectInitConfiguration()
}

extension DiscouragedDirectInitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedDirectInitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.arguments.isEmpty, node.trailingClosure == nil,
        configuration.discouragedInits.contains(node.calledExpression.trimmedDescription)
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
