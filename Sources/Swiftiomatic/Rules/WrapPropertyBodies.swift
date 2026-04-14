import SwiftSyntax

/// Single-line computed property and observer bodies are wrapped onto multiple
/// lines.
///
/// Lint: A single-line property accessor block raises a warning.
///
/// Format: The accessor block is wrapped onto a new line with indentation.
@_spi(Rules)
public final class WrapPropertyBodies: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    guard let accessorBlock = node.accessorBlock else { return node }

    switch accessorBlock.accessors {
    case .getter(let statements):
      // Implicit getter: `var foo: String { "bar" }`
      guard !statements.isEmpty else { return node }
      guard let firstStmt = statements.first,
        !firstStmt.leadingTrivia.containsNewlines
      else { return node }
      let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
      guard !closingOnNewLine else { return node }

      diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace)

      let baseIndent = resolveVarIndent(node)
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
      return result

    case .accessors(let accessors):
      // Explicit accessors: `{ didSet { ... } }` or `{ get set }` (protocol)
      // Skip protocol requirements — accessors without bodies
      guard accessors.contains(where: { $0.body != nil }) else { return node }

      // Check if the outer accessor block needs wrapping
      guard let firstAccessor = accessors.first,
        !firstAccessor.leadingTrivia.containsNewlines
      else { return node }
      let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
      guard !closingOnNewLine else { return node }

      diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace)

      let baseIndent = resolveVarIndent(node)
      let bodyIndent = baseIndent + "    "

      var result = node
      var block = accessorBlock

      block.leftBrace = block.leftBrace.with(
        \.trailingTrivia, block.leftBrace.trailingTrivia.trimmingTrailingWhitespace)

      var items = Array(accessors)
      items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
      let lastIdx = items.count - 1
      items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
      block.accessors = .accessors(AccessorDeclListSyntax(items))

      block.rightBrace = block.rightBrace.with(
        \.leadingTrivia, .newline + Trivia(stringLiteral: baseIndent))

      result.accessorBlock = block
      return result
    }
  }

  /// Resolves indentation for a property binding by finding the enclosing
  /// `VariableDeclSyntax`'s keyword trivia.
  private func resolveVarIndent(_ node: PatternBindingSyntax) -> String {
    if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self) {
      return varDecl.bindingSpecifier.leadingTrivia.indentation
    }
    return ""
  }
}

extension Finding.Message {
  fileprivate static let wrapPropertyBody: Finding.Message =
    "wrap property body onto a new line"
}
