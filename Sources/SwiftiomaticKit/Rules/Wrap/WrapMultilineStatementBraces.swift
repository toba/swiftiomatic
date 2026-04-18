import SwiftSyntax

/// Opening braces of multiline statements are wrapped to their own line.
///
/// When a statement signature (conditions, parameters, etc.) spans multiple
/// lines, the opening `{` is moved to its own line, aligned with the
/// statement keyword.
///
/// Lint: A `{` on the same line as a multiline statement signature raises a
///       warning.
///
/// Format: The `{` is moved to a new line aligned with the closing `}`.
final class WrapMultilineStatementBraces: SyntaxFormatRule {
    static let group: ConfigGroup? = .wrap
    static let isOptIn = true

    // MARK: - Control flow statements

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard let ifNode = visited.as(IfExprSyntax.self) else { return visited }

        guard
            let newBrace = wrappedBrace(
                leftBrace: ifNode.body.leftBrace,
                rightBrace: ifNode.body.rightBrace
            )
        else { return visited }

        var result = ifNode
        result.body.leftBrace = newBrace
        stripTrailingWhitespaceBeforeBrace(&result, leftBraceKeyPath: \.body.leftBrace)
        return ExprSyntax(result)
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        let visited = super.visit(node)
        guard let guardNode = visited.as(GuardStmtSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: guardNode.body.leftBrace,
                rightBrace: guardNode.body.rightBrace
            )
        else { return visited }
        var result = guardNode
        result.body.leftBrace = newBrace
        // The token before `{` in guard is `else` keyword
        result.elseKeyword = result.elseKeyword.with(
            \.trailingTrivia,
            result.elseKeyword.trailingTrivia.trimmingTrailingWhitespace
        )
        return StmtSyntax(result)
    }

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        let visited = super.visit(node)
        guard let forNode = visited.as(ForStmtSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: forNode.body.leftBrace,
                rightBrace: forNode.body.rightBrace
            )
        else { return visited }
        var result = forNode
        result.body.leftBrace = newBrace
        // Strip trailing whitespace from the token before `{`
        // For a for loop, this is typically the sequence expression or where clause
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

    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        let visited = super.visit(node)
        guard let whileNode = visited.as(WhileStmtSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: whileNode.body.leftBrace,
                rightBrace: whileNode.body.rightBrace
            )
        else { return visited }
        var result = whileNode
        result.body.leftBrace = newBrace
        // Strip trailing whitespace from conditions list
        var conditions = Array(result.conditions)
        if var last = conditions.last {
            last.trailingTrivia = last.trailingTrivia.trimmingTrailingWhitespace
            conditions[conditions.count - 1] = last
            result.conditions = ConditionElementListSyntax(conditions)
        }
        return StmtSyntax(result)
    }

    override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
        let visited = super.visit(node)
        guard let doNode = visited.as(DoStmtSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: doNode.body.leftBrace,
                rightBrace: doNode.body.rightBrace
            )
        else { return visited }
        var result = doNode
        result.body.leftBrace = newBrace
        result.doKeyword = result.doKeyword.with(
            \.trailingTrivia,
            result.doKeyword.trailingTrivia.trimmingTrailingWhitespace
        )
        return StmtSyntax(result)
    }

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard let switchNode = visited.as(SwitchExprSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: switchNode.leftBrace,
                rightBrace: switchNode.rightBrace
            )
        else { return visited }
        var result = switchNode
        result.leftBrace = newBrace
        result.subject = result.subject.with(
            \.trailingTrivia,
            result.subject.trailingTrivia.trimmingTrailingWhitespace
        )
        return ExprSyntax(result)
    }

    // MARK: - Function-like declarations

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let funcNode = visited.as(FunctionDeclSyntax.self),
            let body = funcNode.body
        else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace
            )
        else { return visited }
        var result = funcNode
        result.body!.leftBrace = newBrace
        // Strip from signature or return type or where clause
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

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let initNode = visited.as(InitializerDeclSyntax.self),
            let body = initNode.body
        else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace
            )
        else { return visited }
        var result = initNode
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

    override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let deinitNode = visited.as(DeinitializerDeclSyntax.self),
            let body = deinitNode.body
        else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace
            )
        else { return visited }
        var result = deinitNode
        result.body!.leftBrace = newBrace
        result.deinitKeyword = result.deinitKeyword.with(
            \.trailingTrivia,
            result.deinitKeyword.trailingTrivia.trimmingTrailingWhitespace
        )
        return DeclSyntax(result)
    }

    // MARK: - Type declarations

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let classNode = visited.as(ClassDeclSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: classNode.memberBlock.leftBrace,
                rightBrace: classNode.memberBlock.rightBrace
            )
        else { return visited }
        var result = classNode
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let structNode = visited.as(StructDeclSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: structNode.memberBlock.leftBrace,
                rightBrace: structNode.memberBlock.rightBrace
            )
        else { return visited }
        var result = structNode
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let enumNode = visited.as(EnumDeclSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: enumNode.memberBlock.leftBrace,
                rightBrace: enumNode.memberBlock.rightBrace
            )
        else { return visited }
        var result = enumNode
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let actorNode = visited.as(ActorDeclSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: actorNode.memberBlock.leftBrace,
                rightBrace: actorNode.memberBlock.rightBrace
            )
        else { return visited }
        var result = actorNode
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let protocolNode = visited.as(ProtocolDeclSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: protocolNode.memberBlock.leftBrace,
                rightBrace: protocolNode.memberBlock.rightBrace
            )
        else { return visited }
        var result = protocolNode
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let extNode = visited.as(ExtensionDeclSyntax.self) else { return visited }
        guard
            let newBrace = wrappedBrace(
                leftBrace: extNode.memberBlock.leftBrace,
                rightBrace: extNode.memberBlock.rightBrace
            )
        else { return visited }
        var result = extNode
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    // MARK: - Core helpers

    /// Returns a wrapped `leftBrace` token if the statement signature is
    /// multiline, or `nil` if no wrapping is needed.
    private func wrappedBrace(
        leftBrace: TokenSyntax,
        rightBrace: TokenSyntax
    ) -> TokenSyntax? {
        // Already on its own line
        guard !leftBrace.leadingTrivia.containsNewlines else { return nil }

        // Body must be multiline
        guard rightBrace.leadingTrivia.containsNewlines else { return nil }

        // Compare indentation: the line containing the token before `{`
        // must be indented more than the closing `}` line
        guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return nil }
        let prevIndent = lineIndentation(of: prevToken)
        let closingIndent = rightBrace.leadingTrivia.indentation
        guard prevIndent.count > closingIndent.count else { return nil }

        diagnose(.wrapOpeningBrace, on: leftBrace)

        return leftBrace.with(\.leadingTrivia, .newline + Trivia(stringLiteral: closingIndent))
    }

    /// Strips trailing whitespace from the last token of a type declaration's
    /// signature (before the member block).
    private func stripTrailingOnLastSigToken<D: DeclSyntaxProtocol>(_ decl: inout D) {
        // The leftBrace is now on its own line. The preceding token may have
        // trailing whitespace from the original `... {` layout.
        // We find the token before the member block left brace via the tree.
        guard
            let leftBrace = decl.children(viewMode: .sourceAccurate)
                .compactMap({ $0.as(MemberBlockSyntax.self) }).first?.leftBrace,
            let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate)
        else { return }

        let trimmed = prevToken.trailingTrivia.trimmingTrailingWhitespace
        guard trimmed != prevToken.trailingTrivia else { return }

        // Walk the decl children to find which property contains this token
        // and strip its trailing whitespace
        let rewritten = TokenStripper(targetID: prevToken.id, newTrailing: trimmed)
            .rewrite(Syntax(decl))
        decl = rewritten.cast(D.self)
    }

    /// Returns the indentation string of the line on which `token` resides.
    private func lineIndentation(of token: TokenSyntax) -> String {
        var current = token
        while !current.leadingTrivia.containsNewlines {
            guard let prev = current.previousToken(viewMode: .sourceAccurate) else {
                return ""  // start of file
            }
            current = prev
        }
        return current.leadingTrivia.indentation
    }
}

/// Strips trailing whitespace from a token before a wrapped brace.
private func stripBeforeBrace<N: SyntaxProtocol>(
    _ node: inout N,
    leftBraceKeyPath: KeyPath<N, TokenSyntax>
) {
    let leftBrace = node[keyPath: leftBraceKeyPath]
    guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return }
    let trimmed = prevToken.trailingTrivia.trimmingTrailingWhitespace
    guard trimmed != prevToken.trailingTrivia else { return }
    node = TokenStripper(targetID: prevToken.id, newTrailing: trimmed)
        .rewrite(Syntax(node)).cast(N.self)
}

/// Convenience function that wraps the free function with a key path.
private func stripTrailingWhitespaceBeforeBrace<N: SyntaxProtocol>(
    _ node: inout N,
    leftBraceKeyPath: KeyPath<N, TokenSyntax>
) {
    stripBeforeBrace(&node, leftBraceKeyPath: leftBraceKeyPath)
}

/// A rewriter that replaces a single token's trailing trivia.
private class TokenStripper: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrailing: Trivia

    init(targetID: SyntaxIdentifier, newTrailing: Trivia) {
        self.targetID = targetID
        self.newTrailing = newTrailing
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        if token.id == targetID {
            return token.with(\.trailingTrivia, newTrailing)
        }
        return token
    }
}

extension Finding.Message {
    fileprivate static let wrapOpeningBrace: Finding.Message =
        "move opening brace to its own line for multiline statement"
}
