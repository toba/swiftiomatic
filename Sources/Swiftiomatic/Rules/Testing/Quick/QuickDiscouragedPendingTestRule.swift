import SwiftSyntax

struct QuickDiscouragedPendingTestRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "quick_discouraged_pending_test",
    name: "Quick Discouraged Pending Test",
    description: "This test won't run as long as it's marked pending",
    nonTriggeringExamples: QuickDiscouragedPendingTestRuleExamples.nonTriggeringExamples,
    triggeringExamples: QuickDiscouragedPendingTestRuleExamples.triggeringExamples,
  )
}

extension QuickDiscouragedPendingTestRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension QuickDiscouragedPendingTestRule: OptInRule {}

extension QuickDiscouragedPendingTestRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
