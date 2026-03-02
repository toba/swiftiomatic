import SwiftSyntax

struct QuickDiscouragedPendingTestRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = QuickDiscouragedPendingTestConfiguration()
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
