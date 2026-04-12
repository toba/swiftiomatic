import SwiftiomaticSyntax

struct RedundantClosureRule {
  static let id = "redundant_closure"
  static let name = "Redundant Closure"
  static let summary = "Immediately-invoked closures with a single expression can be simplified"
  static let scope: Scope = .format
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        let x = {
          let y = 10
          return y + 1
        }()
        """,
      ),
      Example(
        """
        let x = { (a: Int) in a + 1 }(5)
        """,
      ),
      Example(
        """
        let x: Int = { fatalError() }()
        """,
      ),
      Example(
        """
        let x: Int = { preconditionFailure() }()
        """,
      ),
      Example(
        """
        var x: Void = { doSomething() }()
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        let x: Int = ↓{
          return 42
        }()
        """,
      )
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension FunctionCallExprSyntax {
  /// Whether this call is `{ ... }()` assigned to a property with explicit `Void` type annotation
  fileprivate var isVoidTypedPropertyInitializer: Bool {
    // Walk up: FunctionCallExpr → InitializerClause → PatternBinding → check type annotation
    guard let initClause = parent?.as(InitializerClauseSyntax.self),
      let binding = initClause.parent?.as(PatternBindingSyntax.self),
      let typeAnnotation = binding.typeAnnotation
    else { return false }
    let typeText = typeAnnotation.type.trimmedDescription
    return typeText == "Void" || typeText == "()"
  }
}

extension ExprSyntax {
  /// Whether this expression is a call to a known Never-returning function
  fileprivate var isNeverReturningCall: Bool {
    guard let call = self.as(FunctionCallExprSyntax.self),
      let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
    else { return false }
    return name == "fatalError" || name == "preconditionFailure"
  }
}

extension RedundantClosureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      // Looking for `{ ... }()` pattern (immediately-invoked closure)
      guard let closureExpr = node.calledExpression.as(ClosureExprSyntax.self),
        node.arguments.isEmpty,
        node.trailingClosure == nil
      else { return }

      // Must be a single-statement closure
      guard closureExpr.statements.count == 1 else { return }

      // Must not have parameters (closure signature)
      guard closureExpr.signature == nil else { return }

      // The single statement should be a return or a simple expression
      guard let onlyStmt = closureExpr.statements.first else { return }
      let isReturn = onlyStmt.item.is(ReturnStmtSyntax.self)
      let isExpr = onlyStmt.item.is(ExprSyntax.self)
      guard isReturn || isExpr else { return }

      // Exclude Void-typed properties — removing closure could break @discardableResult calls
      if node.isVoidTypedPropertyInitializer {
        return
      }

      // Exclude Never-returning functions — removing the closure would lose the Never type
      let innerExpr: ExprSyntax? =
        if let ret = onlyStmt.item.as(ReturnStmtSyntax.self) { ret.expression }
        else { onlyStmt.item.as(ExprSyntax.self) }
      if let innerExpr, innerExpr.isNeverReturningCall {
        return
      }

      violations.append(closureExpr.positionAfterSkippingLeadingTrivia)
    }
  }
}
