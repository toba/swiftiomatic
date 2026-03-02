import SwiftSyntax

struct MultipleClosuresWithTrailingClosureRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = MultipleClosuresWithTrailingClosureConfiguration()
}

extension MultipleClosuresWithTrailingClosureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultipleClosuresWithTrailingClosureRule {
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
