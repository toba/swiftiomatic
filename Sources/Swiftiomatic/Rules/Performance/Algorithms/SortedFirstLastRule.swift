import SwiftSyntax

struct SortedFirstLastRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SortedFirstLastConfiguration()
}

extension SortedFirstLastRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SortedFirstLastRule {}

extension SortedFirstLastRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard
        node.declName.baseName.text == "first" || node.declName.baseName.text == "last",
        node.parent?.is(FunctionCallExprSyntax.self) != true,
        let firstBase = node.base?.asFunctionCall,
        let firstBaseCalledExpression = firstBase.calledExpression
          .as(MemberAccessExprSyntax.self),
        firstBaseCalledExpression.declName.baseName.text == "sorted",
        case let argumentLabels = firstBase.arguments.map({ $0.label?.text }),
        argumentLabels.isEmpty || argumentLabels == ["by"]
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
