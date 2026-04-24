import SwiftSyntax

/// Consecutive single-return `if` statements followed by a final `return` should
/// be expressed as a chained `if/else` expression.
///
/// When a sequence of `if` statements each contain only a `return` and are
/// followed by a trailing `return`, the chain is converted into a single
/// `if/else if/.../else` expression (two or more `if` branches required).
///
/// ```swift
/// // Before
/// if case .spaces = $0 { return true }
/// if case .tabs = $0 { return true }
/// return false
///
/// // After
/// if case .spaces = $0 {
///     true
/// } else if case .tabs = $0 {
///     true
/// } else {
///     false
/// }
/// ```
///
/// Lint: A chain of early-return `if` statements raises a warning.
///
/// Format: The chain is replaced with an `if/else` expression.
final class PreferIfElseChain: RewriteSyntaxRule<BasicRuleValue> {
  override class var group: ConfigurationGroup? { .conditions }

  override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    let visited = super.visit(node)
    let items = Array(visited)
    var newItems = [CodeBlockItemSyntax]()
    var i = 0
    var changed = false

    while i < items.count {
      if let chain = tryBuildChain(items: items, startingAt: i) {
        diagnose(.useIfElseChain, on: chain.firstIf)
        newItems.append(
          CodeBlockItemSyntax(
            leadingTrivia: items[i].leadingTrivia,
            item: .expr(ExprSyntax(chain.ifExpr)),
            trailingTrivia: items[chain.endIndex - 1].trailingTrivia
          )
        )
        changed = true
        i = chain.endIndex
      } else {
        newItems.append(items[i])
        i += 1
      }
    }

    guard changed else { return visited }
    return CodeBlockItemListSyntax(newItems)
  }

  // MARK: - Chain detection

  private struct Chain {
    let ifExpr: IfExprSyntax
    let firstIf: IfExprSyntax
    /// Index past the last consumed item (exclusive).
    let endIndex: Int
  }

  /// Tries to build a chain starting at `startIndex`. Requires at least two `if`
  /// statements (each with a single `return` body and no `else`) followed by a
  /// trailing `return` statement.
  private func tryBuildChain(
    items: [CodeBlockItemSyntax],
    startingAt startIndex: Int
  ) -> Chain? {
    var ifBranches: [(conditions: ConditionElementListSyntax, value: ExprSyntax, leading: Trivia)] = []
    var j = startIndex

    // Collect consecutive single-return if statements without else.
    while j < items.count {
      guard
        let ifStmt = extractIfStatement(from: items[j]),
        ifStmt.elseBody == nil,
        let returnValue = singleReturnValue(from: ifStmt.body)
      else {
        break
      }
      ifBranches.append((ifStmt.conditions, returnValue, ifStmt.ifKeyword.leadingTrivia))
      j += 1
    }

    // Need at least 2 if-branches.
    guard ifBranches.count >= 2 else { return nil }

    // The next item must be a trailing return statement.
    guard j < items.count, let fallbackValue = extractReturnValue(from: items[j]) else {
      return nil
    }

    let endIndex = j + 1

    // Build the if/else chain from the bottom up.
    // Start with the else block (the fallback return value).
    let elseBlock = CodeBlockSyntax(
      leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax([
        CodeBlockItemSyntax(
          leadingTrivia: .spaces(2),
          item: .expr(fallbackValue.with(\.leadingTrivia, []).with(\.trailingTrivia, [])),
          trailingTrivia: .newline
        ),
      ]),
      rightBrace: .rightBraceToken()
    )

    // Build from last if-branch backward.
    var currentElse: IfExprSyntax.ElseBody = .codeBlock(elseBlock)

    for i in stride(from: ifBranches.count - 1, through: 0, by: -1) {
      let branch = ifBranches[i]

      let body = CodeBlockSyntax(
        leftBrace: .leftBraceToken(trailingTrivia: .newline),
        statements: CodeBlockItemListSyntax([
          CodeBlockItemSyntax(
            leadingTrivia: .spaces(2),
            item: .expr(branch.value.with(\.leadingTrivia, []).with(\.trailingTrivia, [])),
            trailingTrivia: .newline
          ),
        ]),
        rightBrace: .rightBraceToken()
      )

      let isFirst = i == 0
      let ifKeyword: TokenSyntax = isFirst
        ? .keyword(.if, trailingTrivia: .space)
        : .keyword(.if, leadingTrivia: .space, trailingTrivia: .space)

      let ifExpr = IfExprSyntax(
        ifKeyword: ifKeyword,
        conditions: branch.conditions,
        body: body,
        elseKeyword: .keyword(.else, leadingTrivia: .space),
        elseBody: currentElse
      )

      if !isFirst {
        currentElse = .ifExpr(ifExpr)
      } else {
        // Extract the first if for the finding location.
        let firstIf = extractIfStatement(from: items[startIndex])!
        return Chain(ifExpr: ifExpr, firstIf: firstIf, endIndex: endIndex)
      }
    }

    return nil  // unreachable
  }

  // MARK: - Helpers

  private func extractIfStatement(from item: CodeBlockItemSyntax) -> IfExprSyntax? {
    if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
      return exprStmt.expression.as(IfExprSyntax.self)
    }
    return item.item.as(ExprSyntax.self)?.as(IfExprSyntax.self)
  }

  /// Returns the single return value from an if body, or nil if the body isn't
  /// a single return statement.
  private func singleReturnValue(from body: CodeBlockSyntax) -> ExprSyntax? {
    guard let onlyItem = body.statements.firstAndOnly else { return nil }

    if let returnStmt = onlyItem.item.as(ReturnStmtSyntax.self) {
      return returnStmt.expression
    }
    if let stmtItem = onlyItem.item.as(StmtSyntax.self),
      let returnStmt = ReturnStmtSyntax(stmtItem)
    {
      return returnStmt.expression
    }
    return nil
  }

  /// Extracts the return value from a standalone return statement.
  private func extractReturnValue(from item: CodeBlockItemSyntax) -> ExprSyntax? {
    if let returnStmt = item.item.as(ReturnStmtSyntax.self) {
      return returnStmt.expression
    }
    if let stmtItem = item.item.as(StmtSyntax.self),
      let returnStmt = ReturnStmtSyntax(stmtItem)
    {
      return returnStmt.expression
    }
    return nil
  }
}

extension Finding.Message {
  fileprivate static let useIfElseChain: Finding.Message =
    "replace early-return chain with if/else expression"
}
