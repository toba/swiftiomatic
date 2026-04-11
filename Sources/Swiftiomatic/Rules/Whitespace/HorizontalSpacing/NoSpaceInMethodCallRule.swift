import SwiftSyntax

struct NoSpaceInMethodCallRule {
  static let id = "no_space_in_method_call"
  static let name = "No Space in Method Call"
  static let summary = "Don't add a space between the method name and the parentheses"
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
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
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("foo↓ ()"),
      Example("object.foo↓ ()"),
      Example("object.foo↓ (1)"),
      Example("object.foo↓ (value: 1)"),
      Example("object.foo↓ () {}"),
      Example("object.foo↓     ()"),
      Example("object.foo↓     (value: 1) { x in print(x) }"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("foo↓ ()"): Example("foo()"),
      Example("object.foo↓ ()"): Example("object.foo()"),
      Example("object.foo↓ (1)"): Example("object.foo(1)"),
      Example("object.foo↓ (value: 1)"): Example("object.foo(value: 1)"),
      Example("object.foo↓ () {}"): Example("object.foo() {}"),
      Example("object.foo↓     ()"): Example("object.foo()"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension NoSpaceInMethodCallRule: SwiftSyntaxRule {
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
