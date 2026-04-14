import SwiftSyntax

/// Single-line function, initializer, and subscript bodies are wrapped onto
/// multiple lines.
///
/// Lint: A single-line function/init/subscript body raises a warning.
///
/// Format: The body is wrapped onto a new line with indentation.
@_spi(Rules)
public final class WrapFunctionBodies: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard let body = node.body, body.bodyNeedsWrapping else { return DeclSyntax(node) }

    diagnose(.wrapFunctionBody, on: body.leftBrace)

    let baseIndent = node.funcKeyword.leadingTrivia.indentation
    var result = node
    result.body = body.wrappingBody(baseIndent: baseIndent)
    return DeclSyntax(result)
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard let body = node.body, body.bodyNeedsWrapping else { return DeclSyntax(node) }

    diagnose(.wrapFunctionBody, on: body.leftBrace)

    let baseIndent = node.initKeyword.leadingTrivia.indentation
    var result = node
    result.body = body.wrappingBody(baseIndent: baseIndent)
    return DeclSyntax(result)
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    guard let accessorBlock = node.accessorBlock,
      case .getter(let statements) = accessorBlock.accessors,
      !statements.isEmpty
    else { return DeclSyntax(node) }

    guard let firstStmt = statements.first,
      !firstStmt.leadingTrivia.containsNewlines
    else { return DeclSyntax(node) }

    let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
    guard !closingOnNewLine else { return DeclSyntax(node) }

    diagnose(.wrapFunctionBody, on: accessorBlock.leftBrace)

    let baseIndent = node.subscriptKeyword.leadingTrivia.indentation
    let bodyIndent = baseIndent + "    "

    var result = node
    var block = accessorBlock

    block.leftBrace = block.leftBrace.with(
      \.trailingTrivia, block.leftBrace.trailingTrivia.trimmingTrailingWhitespace)

    var items = Array(statements)
    items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
    let lastIdx = items.count - 1
    items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
    block.accessors = .getter(CodeBlockItemListSyntax(items))

    block.rightBrace = block.rightBrace.with(
      \.leadingTrivia, .newline + Trivia(stringLiteral: baseIndent))

    result.accessorBlock = block
    return DeclSyntax(result)
  }
}

extension Finding.Message {
  fileprivate static let wrapFunctionBody: Finding.Message =
    "wrap function body onto a new line"
}
