import SwiftiomaticSyntax

struct PreferTypeCheckingRule {
  static let id = "prefer_type_checking"
  static let name = "Prefer Type Checking"
  static let summary = "Prefer `a is X` to `a as? X != nil`"
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let foo = bar as? Foo"),
      Example("bar is Foo"),
      Example("2*x is X"),
      Example(
        """
        if foo is Bar {
            doSomeThing()
        }
        """,
      ),
      Example(
        """
        if let bar = foo as? Bar {
            foo.run()
        }
        """,
      ),
      Example("bar as Foo != nil"),
      Example("nil != bar as Foo"),
      Example("bar as Foo? != nil"),
      Example("bar as? Foo? != nil"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("bar ↓as? Foo != nil"),
      Example("2*x as? X != nil"),
      Example(
        """
        if foo ↓as? Bar != nil {
            doSomeThing()
        }
        """,
      ),
      Example("nil != bar ↓as? Foo"),
      Example("nil != 2*x ↓as? X"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("bar ↓as? Foo != nil"): Example("bar is Foo"),
      Example("nil != bar ↓as? Foo"): Example("bar is Foo"),
      Example("2*x ↓as? X != nil"): Example("2*x is X"),
      Example(
        """
        if foo ↓as? Bar != nil {
            doSomeThing()
        }
        """,
      ): Example(
        """
        if foo is Bar {
            doSomeThing()
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferTypeCheckingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferTypeCheckingRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension PreferTypeCheckingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      if let asExpr = node.asExprWithOptionalTypeChecking {
        violations.append(asExpr.asKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
      guard let asExpr = node.asExprWithOptionalTypeChecking else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let expression = asExpr.expression.trimmed
      let type = asExpr.type.trimmed
      return ExprSyntax(stringLiteral: "\(expression) is \(type)")
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
    }
  }
}

extension InfixOperatorExprSyntax {
  fileprivate var asExprWithOptionalTypeChecking: AsExprSyntax? {
    if let asExpr = leftOperand.as(AsExprSyntax.self) ?? rightOperand.as(AsExprSyntax.self),
      asExpr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark,
      !asExpr.type.is(OptionalTypeSyntax.self),
      `operator`.as(BinaryOperatorExprSyntax.self)?.operator
        .tokenKind == .binaryOperator("!="),
      rightOperand.is(NilLiteralExprSyntax.self) || leftOperand.is(NilLiteralExprSyntax.self)
    {
      asExpr
    } else {
      nil
    }
  }
}
