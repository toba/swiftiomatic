import SwiftSyntax

struct QuickDiscouragedPendingTestRule {
    static let id = "quick_discouraged_pending_test"
    static let name = "Quick Discouraged Pending Test"
    static let summary = "This test won't run as long as it's marked pending"
    static let isOptIn = true
  var options = SeverityOption<Self>(.warning)

}

extension QuickDiscouragedPendingTestRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension QuickDiscouragedPendingTestRule {}

extension QuickDiscouragedPendingTestRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        case let name = identifierExpr.baseName.text,
        QuickPendingCallKind(rawValue: name) != nil
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      node.containsInheritance ? .visitChildren : .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      node.isSpecFunction ? .visitChildren : .skipChildren
    }
  }
}

private enum QuickPendingCallKind: String {
  case pending
  case xdescribe
  case xcontext
  case xit
  case xitBehavesLike
}
