import SwiftSyntax

struct MultipleTrailingClosuresRule {
  static let id = "multiple_trailing_closures"
  static let name = "Multiple Trailing Closures"
  static let summary =
    "Trailing closure syntax should not be used when passing more than one closure argument"
  static var nonTriggeringExamples: [Example] {
    [
      Example("foo.map { $0 + 1 }"),
      Example("foo.reduce(0) { $0 + $1 }"),
      Example("if let foo = bar.map({ $0 + 1 }) {\n\n}"),
      Example("foo.something(param1: { $0 }, param2: { $0 + 1 })"),
      Example(
        """
        UIView.animate(withDuration: 1.0) {
            someView.alpha = 0.0
        }
        """,
      ),
      Example("foo.method { print(0) } arg2: { print(1) }"),
      Example("foo.methodWithParenArgs((0, 1), arg2: (0, 1, 2)) { $0 } arg4: { $0 }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("foo.something(param1: { $0 }) ↓{ $0 + 1 }"),
      Example(
        """
        UIView.animate(withDuration: 1.0, animations: {
            someView.alpha = 0.0
        }) ↓{ _ in
            someView.removeFromSuperview()
        }
        """,
      ),
      Example("foo.multipleTrailing(arg1: { $0 }) { $0 } arg3: { $0 }"),
      Example("foo.methodWithParenArgs(param1: { $0 }, param2: (0, 1), (0, 1)) { $0 }"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension MultipleTrailingClosuresRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultipleTrailingClosuresRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let trailingClosure = node.trailingClosure,
        node.hasTrailingClosureViolation
      else {
        return
      }

      violations.append(trailingClosure.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var hasTrailingClosureViolation: Bool {
    guard trailingClosure != nil else {
      return false
    }

    return arguments.contains { elem in
      elem.expression.is(ClosureExprSyntax.self)
    }
  }
}
