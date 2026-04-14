import SwiftSyntax

/// Use if/switch expressions for conditional property assignment.
///
/// When a property with a type annotation and no initializer is immediately
/// followed by an exhaustive `if` or `switch` that assigns the property in
/// every branch, the two statements are merged into a single assignment
/// expression. Nested conditionals are handled recursively.
///
/// Lint: A property followed by an exhaustive conditional assignment raises
///       a warning.
///
/// Format: The separate statements are merged into a conditional expression
///         assignment.
@_spi(Rules)
public final class ConditionalAssignment: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    let visited = super.visit(node)
    let items = Array(visited)
    var newItems = [CodeBlockItemSyntax]()
    var i = 0
    var changed = false

    while i < items.count {
      if i + 1 < items.count,
        let merged = tryMerge(items[i], items[i + 1])
      {
        newItems.append(merged)
        changed = true
        i += 2
      } else {
        newItems.append(items[i])
        i += 1
      }
    }

    guard changed else { return visited }
    return CodeBlockItemListSyntax(newItems)
  }

  // MARK: - Merge

  private func tryMerge(
    _ declItem: CodeBlockItemSyntax,
    _ condItem: CodeBlockItemSyntax
  ) -> CodeBlockItemSyntax? {
    // First item: property with type annotation and no initializer
    guard let varDecl = declItem.item.as(VariableDeclSyntax.self),
      varDecl.bindings.count == 1,
      let binding = varDecl.bindings.first,
      let identPattern = binding.pattern.as(IdentifierPatternSyntax.self),
      binding.typeAnnotation != nil,
      binding.initializer == nil
    else { return nil }

    let name = identPattern.identifier.text

    // Second item: if/switch expression
    let condExpr = extractExpression(from: condItem)
    guard let condExpr else { return nil }

    // Skip if there are comments between the declaration and the conditional
    if let firstToken = condExpr.firstToken(viewMode: .sourceAccurate),
      firstToken.leadingTrivia.hasAnyComments
    {
      return nil
    }

    let conditionalExpr: ExprSyntax
    if let ifExpr = condExpr.as(IfExprSyntax.self) {
      guard isExhaustiveIfAssignment(ifExpr, assigningTo: name) else { return nil }
      conditionalExpr = ExprSyntax(removeAssignments(from: ifExpr, name: name))
    } else if let switchExpr = condExpr.as(SwitchExprSyntax.self) {
      guard isExhaustiveSwitchAssignment(switchExpr, assigningTo: name) else { return nil }
      conditionalExpr = ExprSyntax(removeAssignments(from: switchExpr, name: name))
    } else {
      return nil
    }

    diagnose(.useConditionalExpression, on: condExpr)

    // Build merged declaration: `let x: Type = if/switch { ... }`
    let initializer = InitializerClauseSyntax(
      equal: .binaryOperator("=", leadingTrivia: .space, trailingTrivia: .space),
      value: conditionalExpr.with(\.leadingTrivia, []))

    var newBinding = binding
    newBinding.initializer = initializer

    var newVarDecl = varDecl
    newVarDecl.bindings = PatternBindingListSyntax([newBinding])

    return CodeBlockItemSyntax(
      leadingTrivia: declItem.leadingTrivia,
      item: .decl(DeclSyntax(newVarDecl)),
      trailingTrivia: condItem.trailingTrivia)
  }

  // MARK: - Exhaustive assignment checking

  private func isExhaustiveIfAssignment(
    _ ifExpr: IfExprSyntax,
    assigningTo name: String
  ) -> Bool {
    guard isSingleStatementAssignment(ifExpr.body.statements, assigningTo: name)
    else { return false }

    switch ifExpr.elseBody {
    case .codeBlock(let elseBlock):
      return isSingleStatementAssignment(elseBlock.statements, assigningTo: name)
    case .ifExpr(let elseIf):
      return isExhaustiveIfAssignment(elseIf, assigningTo: name)
    case nil:
      return false
    }
  }

  private func isExhaustiveSwitchAssignment(
    _ switchExpr: SwitchExprSyntax,
    assigningTo name: String
  ) -> Bool {
    guard !switchExpr.cases.isEmpty else { return false }
    for caseItem in switchExpr.cases {
      guard case .switchCase(let switchCase) = caseItem else { return false }
      guard isSingleStatementAssignment(switchCase.statements, assigningTo: name)
      else { return false }
    }
    return true
  }

  private func isSingleStatementAssignment(
    _ statements: CodeBlockItemListSyntax,
    assigningTo name: String
  ) -> Bool {
    guard let onlyItem = statements.firstAndOnly else { return false }

    if isAssignment(onlyItem, to: name) { return true }

    // Nested if/switch expression
    if let expr = extractExpression(from: onlyItem) {
      if let nestedIf = expr.as(IfExprSyntax.self) {
        return isExhaustiveIfAssignment(nestedIf, assigningTo: name)
      }
      if let nestedSwitch = expr.as(SwitchExprSyntax.self) {
        return isExhaustiveSwitchAssignment(nestedSwitch, assigningTo: name)
      }
    }

    return false
  }

  private func isAssignment(_ item: CodeBlockItemSyntax, to name: String) -> Bool {
    guard let infixExpr = extractExpression(from: item)?.as(InfixOperatorExprSyntax.self),
      infixExpr.operator.is(AssignmentExprSyntax.self),
      let lhs = infixExpr.leftOperand.as(DeclReferenceExprSyntax.self),
      lhs.baseName.text == name,
      lhs.argumentNames == nil
    else { return false }
    return true
  }

  // MARK: - Assignment removal

  private func removeAssignments(from ifExpr: IfExprSyntax, name: String) -> IfExprSyntax {
    var result = ifExpr
    result.body = removeAssignment(from: ifExpr.body, name: name)

    switch ifExpr.elseBody {
    case .codeBlock(let elseBlock):
      result.elseBody = .codeBlock(removeAssignment(from: elseBlock, name: name))
    case .ifExpr(let elseIf):
      result.elseBody = .ifExpr(removeAssignments(from: elseIf, name: name))
    case nil:
      break
    }

    return result
  }

  private func removeAssignments(
    from switchExpr: SwitchExprSyntax,
    name: String
  ) -> SwitchExprSyntax {
    var result = switchExpr
    var newCases = [SwitchCaseListSyntax.Element]()

    for caseItem in switchExpr.cases {
      if case .switchCase(var switchCase) = caseItem {
        switchCase.statements = removeAssignmentFromStatements(
          switchCase.statements, name: name)
        newCases.append(.switchCase(switchCase))
      } else {
        newCases.append(caseItem)
      }
    }

    result.cases = SwitchCaseListSyntax(newCases)
    return result
  }

  private func removeAssignment(
    from block: CodeBlockSyntax,
    name: String
  ) -> CodeBlockSyntax {
    var result = block
    result.statements = removeAssignmentFromStatements(block.statements, name: name)
    return result
  }

  private func removeAssignmentFromStatements(
    _ statements: CodeBlockItemListSyntax,
    name: String
  ) -> CodeBlockItemListSyntax {
    guard let onlyItem = statements.firstAndOnly else { return statements }

    // Direct assignment: keep just the value
    if let infixExpr = extractExpression(from: onlyItem)?.as(InfixOperatorExprSyntax.self),
      infixExpr.operator.is(AssignmentExprSyntax.self),
      let lhs = infixExpr.leftOperand.as(DeclReferenceExprSyntax.self),
      lhs.baseName.text == name
    {
      var value = infixExpr.rightOperand
      value.leadingTrivia = onlyItem.leadingTrivia
      return CodeBlockItemListSyntax([
        CodeBlockItemSyntax(item: .expr(value))
      ])
    }

    // Nested if/switch: recurse (expression already carries its own trivia)
    if let expr = extractExpression(from: onlyItem) {
      if let nestedIf = expr.as(IfExprSyntax.self) {
        let modified = removeAssignments(from: nestedIf, name: name)
        return CodeBlockItemListSyntax([
          CodeBlockItemSyntax(item: .expr(ExprSyntax(modified)))
        ])
      }
      if let nestedSwitch = expr.as(SwitchExprSyntax.self) {
        let modified = removeAssignments(from: nestedSwitch, name: name)
        return CodeBlockItemListSyntax([
          CodeBlockItemSyntax(item: .expr(ExprSyntax(modified)))
        ])
      }
    }

    return statements
  }

  // MARK: - Helpers

  private func extractExpression(from item: CodeBlockItemSyntax) -> ExprSyntax? {
    if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
      return exprStmt.expression
    }
    return item.item.as(ExprSyntax.self)
  }
}

extension Finding.Message {
  fileprivate static let useConditionalExpression: Finding.Message =
    "use if/switch expression for conditional assignment"
}
