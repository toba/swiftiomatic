import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Stateless helpers for the inlined `WrapMultilineStatementBraces` rule. Each
/// `static transform(_ N, parent:context:)` overload on the rule class
/// delegates to one of the `applyWrapMultilineStatementBraces(_ N, context:)`
/// overloads below.

// MARK: - Control flow statements

func applyWrapMultilineStatementBraces(
    _ node: IfExprSyntax, context: Context
) -> ExprSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.body.leftBrace,
        rightBrace: node.body.rightBrace,
        context: context
    ) else { return ExprSyntax(node) }
    var result = node
    result.body.leftBrace = newBrace
    wrapMultilineStatementBracesStripBeforeBrace(&result, leftBraceKeyPath: \.body.leftBrace)
    return ExprSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: GuardStmtSyntax, context: Context
) -> StmtSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.body.leftBrace,
        rightBrace: node.body.rightBrace,
        context: context
    ) else { return StmtSyntax(node) }
    var result = node
    result.body.leftBrace = newBrace
    result.elseKeyword = result.elseKeyword.with(
        \.trailingTrivia,
        result.elseKeyword.trailingTrivia.trimmingTrailingWhitespace
    )
    return StmtSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: ForStmtSyntax, context: Context
) -> StmtSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.body.leftBrace,
        rightBrace: node.body.rightBrace,
        context: context
    ) else { return StmtSyntax(node) }
    var result = node
    result.body.leftBrace = newBrace
    if let whereClause = result.whereClause {
        result.whereClause = whereClause.with(
            \.trailingTrivia,
            whereClause.trailingTrivia.trimmingTrailingWhitespace
        )
    } else {
        result.sequence = result.sequence.with(
            \.trailingTrivia,
            result.sequence.trailingTrivia.trimmingTrailingWhitespace
        )
    }
    return StmtSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: WhileStmtSyntax, context: Context
) -> StmtSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.body.leftBrace,
        rightBrace: node.body.rightBrace,
        context: context
    ) else { return StmtSyntax(node) }
    var result = node
    result.body.leftBrace = newBrace
    var conditions = Array(result.conditions)
    if var last = conditions.last {
        last.trailingTrivia = last.trailingTrivia.trimmingTrailingWhitespace
        conditions[conditions.count - 1] = last
        result.conditions = ConditionElementListSyntax(conditions)
    }
    return StmtSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: DoStmtSyntax, context: Context
) -> StmtSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.body.leftBrace,
        rightBrace: node.body.rightBrace,
        context: context
    ) else { return StmtSyntax(node) }
    var result = node
    result.body.leftBrace = newBrace
    result.doKeyword = result.doKeyword.with(
        \.trailingTrivia,
        result.doKeyword.trailingTrivia.trimmingTrailingWhitespace
    )
    return StmtSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: SwitchExprSyntax, context: Context
) -> ExprSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.leftBrace,
        rightBrace: node.rightBrace,
        context: context
    ) else { return ExprSyntax(node) }
    var result = node
    result.leftBrace = newBrace
    result.subject = result.subject.with(
        \.trailingTrivia,
        result.subject.trailingTrivia.trimmingTrailingWhitespace
    )
    return ExprSyntax(result)
}

// MARK: - Function-like declarations

func applyWrapMultilineStatementBraces(
    _ node: FunctionDeclSyntax, context: Context
) -> DeclSyntax {
    guard let body = node.body,
        let newBrace = wrapMultilineStatementBracesWrappedBrace(
            leftBrace: body.leftBrace,
            rightBrace: body.rightBrace,
            context: context
        )
    else { return DeclSyntax(node) }
    var result = node
    result.body!.leftBrace = newBrace
    if let whereClause = result.genericWhereClause {
        result.genericWhereClause = whereClause.with(
            \.trailingTrivia,
            whereClause.trailingTrivia.trimmingTrailingWhitespace
        )
    } else {
        result.signature = result.signature.with(
            \.trailingTrivia,
            result.signature.trailingTrivia.trimmingTrailingWhitespace
        )
    }
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: InitializerDeclSyntax, context: Context
) -> DeclSyntax {
    guard let body = node.body,
        let newBrace = wrapMultilineStatementBracesWrappedBrace(
            leftBrace: body.leftBrace,
            rightBrace: body.rightBrace,
            context: context
        )
    else { return DeclSyntax(node) }
    var result = node
    result.body!.leftBrace = newBrace
    if let whereClause = result.genericWhereClause {
        result.genericWhereClause = whereClause.with(
            \.trailingTrivia,
            whereClause.trailingTrivia.trimmingTrailingWhitespace
        )
    } else {
        result.signature = result.signature.with(
            \.trailingTrivia,
            result.signature.trailingTrivia.trimmingTrailingWhitespace
        )
    }
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: DeinitializerDeclSyntax, context: Context
) -> DeclSyntax {
    guard let body = node.body,
        let newBrace = wrapMultilineStatementBracesWrappedBrace(
            leftBrace: body.leftBrace,
            rightBrace: body.rightBrace,
            context: context
        )
    else { return DeclSyntax(node) }
    var result = node
    result.body!.leftBrace = newBrace
    result.deinitKeyword = result.deinitKeyword.with(
        \.trailingTrivia,
        result.deinitKeyword.trailingTrivia.trimmingTrailingWhitespace
    )
    return DeclSyntax(result)
}

// MARK: - Type declarations

func applyWrapMultilineStatementBraces(
    _ node: ClassDeclSyntax, context: Context
) -> DeclSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        context: context
    ) else { return DeclSyntax(node) }
    var result = node
    result.memberBlock.leftBrace = newBrace
    wrapMultilineStatementBracesStripTrailingOnLastSigToken(&result)
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: StructDeclSyntax, context: Context
) -> DeclSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        context: context
    ) else { return DeclSyntax(node) }
    var result = node
    result.memberBlock.leftBrace = newBrace
    wrapMultilineStatementBracesStripTrailingOnLastSigToken(&result)
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: EnumDeclSyntax, context: Context
) -> DeclSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        context: context
    ) else { return DeclSyntax(node) }
    var result = node
    result.memberBlock.leftBrace = newBrace
    wrapMultilineStatementBracesStripTrailingOnLastSigToken(&result)
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: ActorDeclSyntax, context: Context
) -> DeclSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        context: context
    ) else { return DeclSyntax(node) }
    var result = node
    result.memberBlock.leftBrace = newBrace
    wrapMultilineStatementBracesStripTrailingOnLastSigToken(&result)
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: ProtocolDeclSyntax, context: Context
) -> DeclSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        context: context
    ) else { return DeclSyntax(node) }
    var result = node
    result.memberBlock.leftBrace = newBrace
    wrapMultilineStatementBracesStripTrailingOnLastSigToken(&result)
    return DeclSyntax(result)
}

func applyWrapMultilineStatementBraces(
    _ node: ExtensionDeclSyntax, context: Context
) -> DeclSyntax {
    guard let newBrace = wrapMultilineStatementBracesWrappedBrace(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        context: context
    ) else { return DeclSyntax(node) }
    var result = node
    result.memberBlock.leftBrace = newBrace
    wrapMultilineStatementBracesStripTrailingOnLastSigToken(&result)
    return DeclSyntax(result)
}

// MARK: - Core helpers

/// Returns a wrapped `leftBrace` token if the statement signature is multiline,
/// or `nil` if no wrapping is needed.
private func wrapMultilineStatementBracesWrappedBrace(
    leftBrace: TokenSyntax,
    rightBrace: TokenSyntax,
    context: Context
) -> TokenSyntax? {
    // Already on its own line.
    guard !leftBrace.leadingTrivia.containsNewlines else { return nil }

    // Body must be multiline.
    guard rightBrace.leadingTrivia.containsNewlines else { return nil }

    // Compare indentation: the line containing the token before `{` must be
    // indented more than the closing `}` line.
    guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return nil }
    let prevIndent = wrapMultilineStatementBracesLineIndentation(of: prevToken)
    let closingIndent = rightBrace.leadingTrivia.indentation
    guard prevIndent.count > closingIndent.count else { return nil }

    WrapMultilineStatementBraces.diagnose(
        .wrapOpeningBrace, on: leftBrace, context: context
    )

    return leftBrace.with(\.leadingTrivia, .newline + Trivia(stringLiteral: closingIndent))
}

/// Strips trailing whitespace from the last token of a type declaration's
/// signature (before the member block).
private func wrapMultilineStatementBracesStripTrailingOnLastSigToken<D: DeclSyntaxProtocol>(
    _ decl: inout D
) {
    guard let leftBrace = decl.children(viewMode: .sourceAccurate)
        .compactMap({ $0.as(MemberBlockSyntax.self) }).first?.leftBrace,
        let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate)
    else { return }

    let trimmed = prevToken.trailingTrivia.trimmingTrailingWhitespace
    guard trimmed != prevToken.trailingTrivia else { return }

    let rewritten = WrapMultilineStatementBracesTokenStripper(
        targetID: prevToken.id, newTrailing: trimmed
    ).rewrite(Syntax(decl))
    decl = rewritten.cast(D.self)
}

/// Returns the indentation string of the line on which `token` resides.
private func wrapMultilineStatementBracesLineIndentation(of token: TokenSyntax) -> String {
    var current = token
    while !current.leadingTrivia.containsNewlines {
        guard let prev = current.previousToken(viewMode: .sourceAccurate) else { return "" }
        current = prev
    }
    return current.leadingTrivia.indentation
}

/// Strips trailing whitespace from the token preceding a wrapped brace.
private func wrapMultilineStatementBracesStripBeforeBrace<N: SyntaxProtocol>(
    _ node: inout N,
    leftBraceKeyPath: KeyPath<N, TokenSyntax>
) {
    let leftBrace = node[keyPath: leftBraceKeyPath]
    guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return }
    let trimmed = prevToken.trailingTrivia.trimmingTrailingWhitespace
    guard trimmed != prevToken.trailingTrivia else { return }
    node = WrapMultilineStatementBracesTokenStripper(targetID: prevToken.id, newTrailing: trimmed)
        .rewrite(Syntax(node)).cast(N.self)
}

/// A rewriter that replaces a single token's trailing trivia.
private final class WrapMultilineStatementBracesTokenStripper: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrailing: Trivia

    init(targetID: SyntaxIdentifier, newTrailing: Trivia) {
        self.targetID = targetID
        self.newTrailing = newTrailing
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        if token.id == targetID { return token.with(\.trailingTrivia, newTrailing) }
        return token
    }
}

extension Finding.Message {
    fileprivate static let wrapOpeningBrace: Finding.Message =
        "move opening brace to its own line for multiline statement"
}
