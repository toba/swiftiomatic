import SwiftSyntax

struct UnusedOptionalBindingRule {
  var options = UnusedOptionalBindingOptions()

  static let description = RuleDescription(
    identifier: "unused_optional_binding",
    name: "Unused Optional Binding",
    description: "Prefer `!= nil` over `let _ =`",
    nonTriggeringExamples: [
      Example("if let bar = Foo.optionalValue {}"),
      Example("if let (_, second) = getOptionalTuple() {}"),
      Example("if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"),
      Example("if foo() { let _ = bar() }"),
      Example("if foo() { _ = bar() }"),
      Example("if case .some(_) = self {}"),
      Example("if let point = state.find({ _ in true }) {}"),
    ],
    triggeringExamples: [
      Example("if let ↓_ = Foo.optionalValue {}"),
      Example("if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}"),
      Example("guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}"),
      Example("if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
      Example("if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
      Example("if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
      Example("if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"),
      Example("func foo() { if let ↓_ = bar {} }"),
    ],
  )
}

extension UnusedOptionalBindingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnusedOptionalBindingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      guard let pattern = node.pattern.as(ExpressionPatternSyntax.self),
        pattern.expression.isDiscardExpression
      else {
        return
      }

      if configuration.ignoreOptionalTry,
        let tryExpr = node.initializer?.value.as(TryExprSyntax.self),
        tryExpr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark
      {
        return
      }

      violations.append(pattern.expression.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension ExprSyntax {
  fileprivate var isDiscardExpression: Bool {
    if `is`(DiscardAssignmentExprSyntax.self) {
      return true
    }
    if let tuple = `as`(TupleExprSyntax.self) {
      return tuple.elements.allSatisfy(\.expression.isDiscardExpression)
    }

    return false
  }
}
