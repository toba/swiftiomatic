import SwiftSyntax

struct PreferConditionListRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferConditionListConfiguration()
}

extension PreferConditionListRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferConditionListRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension PreferConditionListRule {}

extension PreferConditionListRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ConditionElementSyntax) {
      if case .expression(let expr) = node.condition {
        collectViolations(for: expr)
      }
    }

    private func collectViolations(for expr: ExprSyntax) {
      if let opExpr = expr.unwrap.as(InfixOperatorExprSyntax.self),
        let opToken = opExpr.operator.as(BinaryOperatorExprSyntax.self)?.operator,
        opToken.text == "&&"
      {
        violations.append(opToken.positionAfterSkippingLeadingTrivia)
        collectViolations(for: opExpr.leftOperand)  // Expressions are left-recursive.
      }
    }
  }

  private final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
      var elements = Array(node)
      var modifiedIndices = Set<Int>()
      var index = 0

      while index < elements.count {
        let element = elements[index]
        guard case .expression(let expr) = element.condition else {
          index += 1
          continue
        }
        if let opExpr = expr.as(InfixOperatorExprSyntax.self),
          let opToken = opExpr.operator.as(BinaryOperatorExprSyntax.self)?.operator,
          opToken.text == "&&"
        {
          numberOfCorrections += 1

          elements[index] = ConditionElementSyntax(
            condition: .expression(opExpr.leftOperand.with(\.trailingTrivia, [])),
            trailingComma: .commaToken(),
            trailingTrivia: opToken.trailingTrivia,
          )
          modifiedIndices.insert(index)

          elements.insert(
            ConditionElementSyntax(
              condition: .expression(opExpr.rightOperand.with(\.trailingTrivia, [])),
              trailingComma: index == elements.count - 1 ? nil : .commaToken(),
              trailingTrivia: .space,
            ),
            at: index + 1,
          )
          modifiedIndices.insert(index + 1)
          // Don't increment the index to re-evaluate `elements[index]`.
        } else if expr.is(TupleExprSyntax.self) {
          // Unwrap parenthesized expression and repeat the loop for the inner expression (i.e. without
          // incrementing the index).
          let unwrappedExpr = expr.unwrap
          elements[index] = element.with(\.condition, .expression(unwrappedExpr))
          if unwrappedExpr != expr {
            modifiedIndices.insert(index)
          }
        } else {
          index += 1
        }
      }
      for (index, element) in elements.enumerated() where modifiedIndices.contains(index) {
        if case .expression(let expr) = element.condition {
          // If the expression contains function calls with trailing closures, we need to wrap them in
          // parentheses. That might not be exactly how the author created the expression, but it is
          // necessary to ensure no compiler warning appears after the transformations.
          elements[index] = element.with(
            \.condition,
            .expression(ParenthesizedTrailingClosureRewriter().visit(expr))
              .with(\.leadingTrivia, expr.leadingTrivia)
              .with(\.trailingTrivia, expr.trailingTrivia),
          )
        }
      }
      return super.visit(ConditionElementListSyntax(elements))
    }
  }
}

extension ExprSyntax {
  fileprivate var unwrap: ExprSyntax {
    `as`(TupleExprSyntax.self)?.elements.onlyElement?.expression
      .with(\.leadingTrivia, leadingTrivia)
      .with(\.trailingTrivia, trailingTrivia)
      ?? self
  }
}

private final class ParenthesizedTrailingClosureRewriter: SyntaxRewriter {
  override func visitAny(_ node: Syntax) -> Syntax? {
    if let opToken = node.as(InfixOperatorExprSyntax.self)?.operator.as(
      BinaryOperatorExprSyntax.self,
    )?.operator,
      ["&&", "||"].contains(opToken.text)
    {
      nil
    } else if let opToken = node.as(PrefixOperatorExprSyntax.self)?.operator,
      ["!"].contains(opToken.text)
    {
      nil
    } else if node.is(FunctionCallExprSyntax.self) {
      nil
    } else {
      node
    }
  }

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    if node.trailingClosure != nil || node.additionalTrailingClosures.isNotEmpty {
      return ExprSyntax(
        TupleExprSyntax(
          elements: LabeledExprListSyntax([
            LabeledExprSyntax(label: nil, expression: node.with(\.trailingTrivia, []))
          ]),
        ),
      )
      .with(\.leadingTrivia, node.leadingTrivia)
      .with(\.trailingTrivia, node.trailingTrivia)
    }
    return super.visit(node)
  }
}
