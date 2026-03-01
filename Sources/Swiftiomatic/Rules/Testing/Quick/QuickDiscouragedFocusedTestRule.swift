import SwiftSyntax

struct QuickDiscouragedFocusedTestRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "quick_discouraged_focused_test",
    name: "Quick Discouraged Focused Test",
    description: "Non-focused tests won't run as long as this test is focused",
    nonTriggeringExamples: QuickDiscouragedFocusedTestRuleExamples.nonTriggeringExamples,
    triggeringExamples: QuickDiscouragedFocusedTestRuleExamples.triggeringExamples,
  )
}

extension QuickDiscouragedFocusedTestRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension QuickDiscouragedFocusedTestRule: OptInRule {}

extension QuickDiscouragedFocusedTestRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
