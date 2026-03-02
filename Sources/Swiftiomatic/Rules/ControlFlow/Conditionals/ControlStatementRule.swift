import SwiftSyntax

struct ControlStatementRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ControlStatementConfiguration()
}

extension ControlStatementRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ControlStatementRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: CatchClauseSyntax) {
      if node.catchItems.containSuperfluousParens == true {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: GuardStmtSyntax) {
      if node.conditions.containSuperfluousParens {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: IfExprSyntax) {
      if node.conditions.containSuperfluousParens {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: SwitchExprSyntax) {
      if node.subject.unwrapped != nil {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: WhileStmtSyntax) {
      if node.conditions.containSuperfluousParens {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
      guard case let items = node.catchItems, items.containSuperfluousParens == true else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let node =
        node
        .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .space))
        .with(\.catchItems, items.withoutParens)
      return super.visit(node)
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
      guard node.conditions.containSuperfluousParens else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let node =
        node
        .with(\.guardKeyword, node.guardKeyword.with(\.trailingTrivia, .space))
        .with(\.conditions, node.conditions.withoutParens)
      return super.visit(node)
    }

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
      guard node.conditions.containSuperfluousParens else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let node =
        node
        .with(\.ifKeyword, node.ifKeyword.with(\.trailingTrivia, .space))
        .with(\.conditions, node.conditions.withoutParens)
      return super.visit(node)
    }

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
      guard let tupleElement = node.subject.unwrapped else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let node =
        node
        .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
        .with(\.subject, tupleElement.with(\.trailingTrivia, .space))
      return super.visit(node)
    }

    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
      guard node.conditions.containSuperfluousParens else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let node =
        node
        .with(\.whileKeyword, node.whileKeyword.with(\.trailingTrivia, .space))
        .with(\.conditions, node.conditions.withoutParens)
      return super.visit(node)
    }
  }
}

extension ExprSyntax {
  fileprivate var unwrapped: ExprSyntax? {
    if let expr = `as`(TupleExprSyntax.self)?.elements.onlyElement?.expression {
      return containsTrailingClosure(Syntax(expr)) ? nil : expr
    }
    return nil
  }

  private func containsTrailingClosure(_ node: Syntax) -> Bool {
    switch node.as(SyntaxEnum.self) {
    case .functionCallExpr(let node):
      node.trailingClosure != nil || node.calledExpression.is(ClosureExprSyntax.self)
    case .sequenceExpr(let node):
      node.elements.contains { containsTrailingClosure(Syntax($0)) }
    default: false
    }
  }
}

extension ConditionElementListSyntax {
  fileprivate var containSuperfluousParens: Bool {
    contains {
      if case .expression(let wrapped) = $0.condition {
        return wrapped.unwrapped != nil
      }
      return false
    }
  }

  fileprivate var withoutParens: Self {
    let conditions = map { (element: ConditionElementSyntax) -> ConditionElementSyntax in
      if let expression = element.condition.as(ExprSyntax.self)?.unwrapped {
        return
          element
          .with(\.condition, .expression(expression))
          .with(\.leadingTrivia, element.leadingTrivia)
          .with(\.trailingTrivia, element.trailingTrivia)
      }
      return element
    }
    return Self(conditions)
      .with(\.leadingTrivia, leadingTrivia)
      .with(\.trailingTrivia, trailingTrivia)
  }
}

extension CatchItemListSyntax {
  fileprivate var containSuperfluousParens: Bool {
    contains { $0.unwrapped != nil }
  }

  fileprivate var withoutParens: Self {
    let items = map { (item: CatchItemSyntax) -> CatchItemSyntax in
      if let expression = item.unwrapped {
        return
          item
          .with(
            \.pattern,
            PatternSyntax(ExpressionPatternSyntax(expression: expression)),
          )
          .with(\.leadingTrivia, item.leadingTrivia)
          .with(\.trailingTrivia, item.trailingTrivia)
      }
      return item
    }
    return Self(items)
      .with(\.leadingTrivia, leadingTrivia)
      .with(\.trailingTrivia, trailingTrivia)
  }
}

extension CatchItemSyntax {
  fileprivate var unwrapped: ExprSyntax? {
    pattern?.as(ExpressionPatternSyntax.self)?.expression.unwrapped
  }
}
