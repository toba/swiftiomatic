import SwiftSyntax

/// Remove a property that is assigned and immediately returned on the next line.
///
/// When a `let` binding is followed immediately by a `return` of the same identifier,
/// the binding is unnecessary. The expression can be returned directly.
///
/// For example: `let result = expr; return result` → `return expr`.
///
/// This rule only fires when the variable is a simple `let` with one binding, no type
/// annotation, and the very next statement is `return <same identifier>`.
///
/// Lint: If a redundant property-then-return is found, a lint warning is raised.
///
/// Rewrite: The property declaration is removed and its value is inlined into
///         the return statement.
final class RedundantProperty: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  static func transform(
    _ visited: CodeBlockItemListSyntax,
    parent: Syntax?,
    context: Context
  ) -> CodeBlockItemListSyntax {
    let items = Array(visited)
    var newItems = [CodeBlockItemSyntax]()
    var i = 0
    var changed = false

    while i < items.count {
      if i + 1 < items.count,
        let merged = tryMerge(items[i], items[i + 1], context: context)
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

  private static func tryMerge(
    _ declItem: CodeBlockItemSyntax,
    _ returnItem: CodeBlockItemSyntax,
    context: Context
  ) -> CodeBlockItemSyntax? {
    // First item: `let identifier = value` (no type annotation, single binding)
    guard let varDecl = declItem.item.as(VariableDeclSyntax.self),
      varDecl.bindingSpecifier.tokenKind == .keyword(.let),
      varDecl.bindings.count == 1,
      let binding = varDecl.bindings.first,
      let identPattern = binding.pattern.as(IdentifierPatternSyntax.self),
      binding.typeAnnotation == nil,
      let initializer = binding.initializer
    else { return nil }

    let name = identPattern.identifier.text

    // Second item: `return <same identifier>`
    guard let returnStmt = returnItem.item.as(ReturnStmtSyntax.self),
      let returnExpr = returnStmt.expression,
      let declRef = returnExpr.as(DeclReferenceExprSyntax.self),
      declRef.baseName.text == name,
      declRef.argumentNames == nil
    else { return nil }

    Self.diagnose(.removeRedundantProperty(name: name), on: varDecl, context: context)

    // Build: `return value` — transfer declaration's leading trivia (may include
    // preceding comments) to the return keyword, and use the original return
    // expression's trivia on the inlined value.
    var value = initializer.value
    value.leadingTrivia = returnExpr.leadingTrivia
    value.trailingTrivia = returnExpr.trailingTrivia

    var newReturnStmt = returnStmt
    newReturnStmt.returnKeyword = returnStmt.returnKeyword
      .with(\.leadingTrivia, declItem.leadingTrivia)
    newReturnStmt.expression = value

    return CodeBlockItemSyntax(item: .stmt(StmtSyntax(newReturnStmt)))
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantProperty(name: String) -> Finding.Message {
    "remove redundant '\(name)' property; return the expression directly"
  }
}
