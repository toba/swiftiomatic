import SwiftSyntax

/// Single-line bodies in conditionals, functions, loops, and properties are
/// wrapped onto multiple lines.
///
/// This rule combines wrapping for:
/// - **Conditionals**: `if`, `else`, `guard` bodies
/// - **Functions**: function, initializer, and subscript bodies
/// - **Loops**: `for`, `while`, `repeat` loop bodies
/// - **Properties**: computed property and observer bodies
///
/// Lint: A single-line body raises a warning.
///
/// Format: The body is wrapped onto a new line with indentation.
@_spi(Rules)
public final class WrapBodies: SyntaxFormatRule {
  public override class var group: ConfigGroup? { .wrap }

  public override class var isOptIn: Bool { true }

  // MARK: - Conditional body state

  /// Tracks the current body indentation for nested inline structures.
  private var currentIndent = ""

  /// Tracks the base indentation for if/else-if chains so that `else if` bodies
  /// use the same base as the outermost `if`.
  private var chainBaseIndent: String?

  // MARK: - Conditionals

  public override func visit(_ node: IfExprSyntax) -> ExprSyntax {
    let isElseIf = node.parent?.is(IfExprSyntax.self) == true

    let baseIndent: String
    if isElseIf, let chainIndent = chainBaseIndent {
      baseIndent = chainIndent
    } else {
      baseIndent = resolveIndent(from: node.ifKeyword.leadingTrivia)
    }

    let savedChainIndent = chainBaseIndent
    let savedIndent = currentIndent
    chainBaseIndent = baseIndent
    currentIndent = baseIndent + "    "
    defer {
      currentIndent = savedIndent
      chainBaseIndent = savedChainIndent
    }

    let needsBodyWrap = node.body.bodyNeedsWrapping
    if needsBodyWrap {
      diagnose(.wrapConditionalBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsBodyWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }

    if let elseBody = node.elseBody {
      switch elseBody {
      case .ifExpr(let nestedIf):
        result.elseBody = .ifExpr(visit(nestedIf).cast(IfExprSyntax.self))
      case .codeBlock(var block):
        let needsElseWrap = block.bodyNeedsWrapping
        if needsElseWrap {
          diagnose(.wrapConditionalBody, on: block.leftBrace)
        }
        block.statements = visit(block.statements)
        if needsElseWrap {
          block = block.wrappingBody(baseIndent: baseIndent)
        }
        result.elseBody = .codeBlock(block)
      }
    }

    return ExprSyntax(result)
  }

  public override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.guardKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapConditionalBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  // MARK: - Functions

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard let body = node.body, body.bodyNeedsWrapping else { return super.visit(node) }

    diagnose(.wrapFunctionBody, on: body.leftBrace)

    let baseIndent = node.funcKeyword.leadingTrivia.indentation
    var result = node
    result.body = body.wrappingBody(baseIndent: baseIndent)
    return DeclSyntax(result)
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard let body = node.body, body.bodyNeedsWrapping else { return super.visit(node) }

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
    else { return super.visit(node) }

    guard let firstStmt = statements.first,
      !firstStmt.leadingTrivia.containsNewlines
    else { return super.visit(node) }

    let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
    guard !closingOnNewLine else { return super.visit(node) }

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

  // MARK: - Loops

  public override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.forKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapLoopBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  public override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.whileKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapLoopBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  public override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.repeatKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapLoopBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  // MARK: - Properties

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
      // Skip protocol requirements -- accessors without bodies
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

  // MARK: - Helpers

  private func resolveIndent(from trivia: Trivia) -> String {
    if trivia.containsNewlines { return trivia.indentation }
    return currentIndent
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
  fileprivate static let wrapConditionalBody: Finding.Message =
    "wrap conditional body onto a new line"

  fileprivate static let wrapFunctionBody: Finding.Message =
    "wrap function body onto a new line"

  fileprivate static let wrapLoopBody: Finding.Message =
    "wrap loop body onto a new line"

  fileprivate static let wrapPropertyBody: Finding.Message =
    "wrap property body onto a new line"
}
