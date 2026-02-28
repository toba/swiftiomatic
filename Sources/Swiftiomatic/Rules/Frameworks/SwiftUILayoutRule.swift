import SwiftSyntax

struct SwiftUILayoutRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "swiftui_layout",
    name: "SwiftUI Layout",
    description:
      "Detects SwiftUI layout composition anti-patterns like nested NavigationStack or List inside ScrollView",
    kind: .lint,
    nonTriggeringExamples: [
      Example("NavigationStack { List { Text(\"Hello\") } }")
    ],
    triggeringExamples: [
      Example("NavigationStack { ↓NavigationStack { Text(\"Hello\") } }")
    ],
  )
}

extension SwiftUILayoutRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationsSyntaxVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension SwiftUILayoutRule: OptInRule {}

extension SwiftUILayoutRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    private var containerStack: [String] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
      let callee = node.calledExpression.trimmedDescription
      guard SwiftUILayoutDetector.trackedContainers.contains(callee) else {
        return .visitChildren
      }

      if let issue = SwiftUILayoutDetector.checkNestedNavigationStack(
        callee: callee, containerStack: containerStack,
      ) {
        emitIssue(issue, at: node)
      }
      if let issue = SwiftUILayoutDetector.checkListInsideScrollView(
        callee: callee, containerStack: containerStack,
      ) {
        emitIssue(issue, at: node)
      }
      if let issue = SwiftUILayoutDetector.checkGeometryReaderInsideScrollView(
        callee: callee, containerStack: containerStack,
      ) {
        emitIssue(issue, at: node)
      }

      containerStack.append(callee)

      if let issue = SwiftUILayoutDetector.checkMultipleUnboundedContainers(
        containerStack: containerStack,
      ) {
        emitIssue(issue, at: node)
      }

      return .visitChildren
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription
      guard SwiftUILayoutDetector.trackedContainers.contains(callee) else { return }
      if let index = containerStack.lastIndex(of: callee) {
        containerStack.remove(at: index)
      }
    }

    private func emitIssue(
      _ issue: SwiftUILayoutDetector.LayoutIssue,
      at node: FunctionCallExprSyntax,
    ) {
      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason: issue.reason,
          severity: issue.isHighSeverity ? .error : .warning,
          confidence: issue.isHighSeverity ? .high : .medium,
          suggestion: issue.suggestion,
        ),
      )
    }
  }
}
