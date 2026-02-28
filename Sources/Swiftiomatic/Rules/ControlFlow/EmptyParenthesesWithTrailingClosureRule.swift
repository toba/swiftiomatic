import SwiftSyntax

struct EmptyParenthesesWithTrailingClosureRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "empty_parentheses_with_trailing_closure",
    name: "Empty Parentheses with Trailing Closure",
    description: "When using trailing closures, empty parentheses should be avoided "
      + "after the method call",
    kind: .style,
    nonTriggeringExamples: [
      Example("[1, 2].map { $0 + 1 }"),
      Example("[1, 2].map({ $0 + 1 })"),
      Example("[1, 2].reduce(0) { $0 + $1 }"),
      Example("[1, 2].map { number in\n number + 1 \n}"),
      Example("let isEmpty = [1, 2].isEmpty()"),
      Example(
        """
        UIView.animateWithDuration(0.3, animations: {
           self.disableInteractionRightView.alpha = 0
        }, completion: { _ in
           ()
        })
        """,
      ),
    ],
    triggeringExamples: [
      Example("[1, 2].map↓() { $0 + 1 }"),
      Example("[1, 2].map↓( ) { $0 + 1 }"),
      Example("[1, 2].map↓() { number in\n number + 1 \n}"),
      Example("[1, 2].map↓(  ) { number in\n number + 1 \n}"),
      Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}"),
    ],
    corrections: [
      Example("[1, 2].map↓() { $0 + 1 }"): Example("[1, 2].map { $0 + 1 }"),
      Example("[1, 2].map↓( ) { $0 + 1 }"): Example("[1, 2].map { $0 + 1 }"),
      Example("[1, 2].map↓() { number in\n number + 1 \n}"):
        Example("[1, 2].map { number in\n number + 1 \n}"),
      Example("[1, 2].map↓(  ) { number in\n number + 1 \n}"):
        Example("[1, 2].map { number in\n number + 1 \n}"),
      Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}"):
        Example("func foo() -> [Int] {\n    return [1, 2].map { $0 + 1 }\n}"),
      Example("class C {\n#if true\nfunc f() {\n[1, 2].map↓() { $0 + 1 }\n}\n#endif\n}"):
        Example("class C {\n#if true\nfunc f() {\n[1, 2].map { $0 + 1 }\n}\n#endif\n}"),
    ],
  )
}

extension EmptyParenthesesWithTrailingClosureRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationsSyntaxVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationsSyntaxRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension EmptyParenthesesWithTrailingClosureRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let position = node.violationPosition else {
        return
      }

      violations.append(position)
    }
  }

  fileprivate final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.violationPosition != nil else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode =
        node
        .with(\.leftParen, nil)
        .with(\.rightParen, nil)
        .with(
          \.trailingClosure,
          node.trailingClosure?.with(\.leadingTrivia, .spaces(1)),
        )
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var violationPosition: AbsolutePosition? {
    guard trailingClosure != nil,
      let leftParen,
      arguments.isEmpty
    else {
      return nil
    }
    return leftParen.positionAfterSkippingLeadingTrivia
  }
}
