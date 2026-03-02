import SwiftSyntax

struct DirectReturnRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = DirectReturnConfiguration()
}

extension DirectReturnRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension DirectReturnRule {}

extension DirectReturnRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ statements: CodeBlockItemListSyntax) {
      if let (binding, _) = statements.violation {
        violations.append(binding.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
      guard let (binding, returnStmt) = statements.violation,
        let bindingList = binding.parent?.as(PatternBindingListSyntax.self),
        let varDecl = bindingList.parent?.as(VariableDeclSyntax.self),
        var initExpression = binding.initializer?.value
      else {
        return super.visit(statements)
      }
      numberOfCorrections += 1
      var newStmtList = Array(statements.dropLast(2))
      let newBindingList =
        bindingList
        .filter { $0 != binding }
        .enumerated()
        .map { index, item in
          if index == bindingList.count - 2 {
            return item.with(\.trailingComma, nil)
          }
          return item
        }
      if let type = binding.typeAnnotation?.type {
        initExpression = ExprSyntax(
          fromProtocol: AsExprSyntax(
            expression: initExpression.trimmed,
            asKeyword: .keyword(.as).with(\.leadingTrivia, .space).with(
              \.trailingTrivia,
              .space,
            ),
            type: type.trimmed,
          ),
        )
      }
      if newBindingList.isNotEmpty {
        newStmtList.append(
          CodeBlockItemSyntax(
            item: .decl(
              DeclSyntax(
                varDecl.with(
                  \.bindings,
                  PatternBindingListSyntax(newBindingList),
                )),
            ),
          ),
        )
        newStmtList.append(
          CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(returnStmt.with(\.expression, initExpression))),
          ),
        )
      } else {
        let leadingTrivia =
          varDecl.leadingTrivia.withoutTrailingIndentation
          + returnStmt.leadingTrivia.withFirstEmptyLineRemoved
        let trailingTrivia =
          varDecl.trailingTrivia.withoutTrailingIndentation + returnStmt.trailingTrivia

        newStmtList.append(
          CodeBlockItemSyntax(
            item: .stmt(
              StmtSyntax(
                returnStmt
                  .with(\.expression, initExpression)
                  .with(\.leadingTrivia, leadingTrivia)
                  .with(\.trailingTrivia, trailingTrivia),
              ),
            ),
          ),
        )
      }
      return super.visit(CodeBlockItemListSyntax(newStmtList))
    }
  }
}

extension CodeBlockItemListSyntax {
  fileprivate var violation: (PatternBindingSyntax, ReturnStmtSyntax)? {
    guard count >= 2, let last = last?.item,
      let returnStmt = last.as(ReturnStmtSyntax.self),
      let identifier = returnStmt.expression?.as(DeclReferenceExprSyntax.self)?.baseName
        .text,
      let varDecl = dropLast().last?.item.as(VariableDeclSyntax.self)
    else {
      return nil
    }
    let binding = varDecl.bindings.first {
      $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == identifier
    }
    if let binding {
      return (binding, returnStmt)
    }
    return nil
  }
}
