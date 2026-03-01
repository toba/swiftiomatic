import SwiftSyntax

struct NoSpaceInMethodCallRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NoSpaceInMethodCallConfiguration()

  static let description = RuleDescription(
    identifier: "no_space_in_method_call",
    name: "No Space in Method Call",
    description: "Don't add a space between the method name and the parentheses",
    nonTriggeringExamples: [
      Example("foo()"),
      Example("object.foo()"),
      Example("object.foo(1)"),
      Example("object.foo(value: 1)"),
      Example("object.foo { print($0 }"),
      Example("list.sorted { $0.0 < $1.0 }.map { $0.value }"),
      Example("self.init(rgb: (Int) (colorInt))"),
      Example(
        """
        Button {
            print("Button tapped")
        } label: {
            Text("Button")
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example("foo↓ ()"),
      Example("object.foo↓ ()"),
      Example("object.foo↓ (1)"),
      Example("object.foo↓ (value: 1)"),
      Example("object.foo↓ () {}"),
      Example("object.foo↓     ()"),
      Example("object.foo↓     (value: 1) { x in print(x) }"),
    ],
    corrections: [
      Example("foo↓ ()"): Example("foo()"),
      Example("object.foo↓ ()"): Example("object.foo()"),
      Example("object.foo↓ (1)"): Example("object.foo(1)"),
      Example("object.foo↓ (value: 1)"): Example("object.foo(value: 1)"),
      Example("object.foo↓ () {}"): Example("object.foo() {}"),
      Example("object.foo↓     ()"): Example("object.foo()"),
    ],
  )
}

extension NoSpaceInMethodCallRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension NoSpaceInMethodCallRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.hasNoSpaceInMethodCallViolation else {
        return
      }

      violations.append(node.calledExpression.endPositionBeforeTrailingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.hasNoSpaceInMethodCallViolation else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode =
        node
        .with(\.calledExpression, node.calledExpression.with(\.trailingTrivia, []))
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var hasNoSpaceInMethodCallViolation: Bool {
    leftParen != nil && !calledExpression.is(TupleExprSyntax.self)
      && calledExpression.trailingTrivia.isNotEmpty
  }
}
