import SwiftiomaticSyntax

struct TrailingClosureEmptyParensRule {
  static let id = "trailing_closure_empty_parens"
  static let name = "Trailing Closure Empty Parens"
  static let summary =
    "When using trailing closures, empty parentheses should be avoided after the method call"
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
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
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("[1, 2].map↓() { $0 + 1 }"),
      Example("[1, 2].map↓( ) { $0 + 1 }"),
      Example("[1, 2].map↓() { number in\n number + 1 \n}"),
      Example("[1, 2].map↓(  ) { number in\n number + 1 \n}"),
      Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}"),
    ]
  }

  static var corrections: [Example: Example] {
    [
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
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension TrailingClosureEmptyParensRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension TrailingClosureEmptyParensRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let position = node.violationPosition else {
        return
      }

      violations.append(position)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
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
