import SwiftSyntax

struct QuickDiscouragedFocusedTestRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = QuickDiscouragedFocusedTestConfiguration()
}

extension QuickDiscouragedFocusedTestRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension QuickDiscouragedFocusedTestRule {}

extension QuickDiscouragedFocusedTestRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        case let name = identifierExpr.baseName.text,
        QuickFocusedCallKind(rawValue: name) != nil
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

private enum QuickFocusedCallKind: String {
  case fdescribe
  case fcontext
  case fit
  case fitBehavesLike
}
