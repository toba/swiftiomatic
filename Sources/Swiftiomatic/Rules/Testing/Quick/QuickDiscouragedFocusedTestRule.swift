import SwiftSyntax

struct QuickDiscouragedFocusedTestRule {
    static let id = "quick_discouraged_focused_test"
    static let name = "Quick Discouraged Focused Test"
    static let summary = "Non-focused tests won't run as long as this test is focused"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        QuickDiscouragedFocusedTestRuleExamples.nonTriggeringExamples
    }
    static var triggeringExamples: [Example] {
        QuickDiscouragedFocusedTestRuleExamples.triggeringExamples
    }
  var options = SeverityConfiguration<Self>(.warning)

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
