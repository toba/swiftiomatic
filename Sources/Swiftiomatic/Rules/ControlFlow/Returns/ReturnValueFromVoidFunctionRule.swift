import SwiftBasicFormat
import SwiftSyntax

struct ReturnValueFromVoidFunctionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ReturnValueFromVoidFunctionConfiguration()

  static let description = RuleDescription(
    identifier: "return_value_from_void_function",
    name: "Return Value from Void Function",
    description: "Returning values from Void functions should be avoided",
    isOptIn: true,
    nonTriggeringExamples: ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples,
    triggeringExamples: ReturnValueFromVoidFunctionRuleExamples.triggeringExamples,
  )
}

extension ReturnValueFromVoidFunctionRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ReturnValueFromVoidFunctionRule {}

extension ReturnValueFromVoidFunctionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ReturnStmtSyntax) {
      if node.expression != nil,
        let functionNode = Syntax(node).enclosingFunction(),
        functionNode.returnsVoid
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
      guard let returnStmt = statements.last?.item.as(ReturnStmtSyntax.self),
        let expr = returnStmt.expression,
        Syntax(statements).enclosingFunction()?.returnsVoid == true
      else {
        return super.visit(statements)
      }
      numberOfCorrections += 1
      let newStmtList =
        Array(statements.dropLast()) + [
          CodeBlockItemSyntax(item: .expr(expr))
            .with(\.leadingTrivia, returnStmt.leadingTrivia),
          CodeBlockItemSyntax(
            item: .stmt(
              StmtSyntax(
                returnStmt
                  .with(\.expression, nil)
                  .with(
                    \.leadingTrivia,
                    .newline
                      + (returnStmt.leadingTrivia
                        .indentation(isOnNewline: false) ?? []),
                  )
                  .with(\.trailingTrivia, returnStmt.trailingTrivia),
              ),
            ),
          ),
        ]
      return super.visit(CodeBlockItemListSyntax(newStmtList))
    }
  }
}

extension Syntax {
  fileprivate func enclosingFunction() -> FunctionDeclSyntax? {
    if let node = `as`(FunctionDeclSyntax.self) {
      return node
    }

    if `is`(ClosureExprSyntax.self) || `is`(VariableDeclSyntax.self)
      || `is`(InitializerDeclSyntax.self)
    {
      return nil
    }

    return parent?.enclosingFunction()
  }
}

extension FunctionDeclSyntax {
  fileprivate var returnsVoid: Bool {
    guard let type = signature.returnClause?.type else {
      return true
    }
    return type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
      || type.as(TupleTypeSyntax.self)?.elements.isEmpty == true
  }
}
