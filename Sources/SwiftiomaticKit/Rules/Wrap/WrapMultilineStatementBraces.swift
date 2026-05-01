import SwiftSyntax

// sm:ignore functionBodyLength

/// Opening braces of multiline statements are wrapped to their own line.
///
/// When a statement signature (conditions, parameters, etc.) spans multiple lines, the opening `{`
/// is moved to its own line, aligned with the statement keyword.
///
/// Lint: A `{` on the same line as a multiline statement signature raises a warning.
///
/// Rewrite: The `{` is moved to a new line aligned with the closing `}` .
final class WrapMultilineStatementBraces: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var key: String { "multilineStatementBraces" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Control flow statements

    static func transform(
        _ node: IfExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.body.leftBrace,
            rightBrace: node.body.rightBrace,
            context: context
        ) else { return ExprSyntax(node) }
        var result = node
        result.body.leftBrace = newBrace
        stripBeforeBrace(&result, leftBraceKeyPath: \.body.leftBrace)
        return ExprSyntax(result)
    }

    static func transform(
        _ node: GuardStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        guard let newBrace = wrappedBrace(
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

    static func transform(
        _ node: ForStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        guard let newBrace = wrappedBrace(
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

    static func transform(
        _ node: WhileStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        guard let newBrace = wrappedBrace(
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

    static func transform(
        _ node: DoStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        guard let newBrace = wrappedBrace(
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

    static func transform(
        _ node: SwitchExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let newBrace = wrappedBrace(
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

    static func transform(
        _ node: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body,
              let newBrace = wrappedBrace(
                  leftBrace: body.leftBrace,
                  rightBrace: body.rightBrace,
                  context: context
              ) else { return DeclSyntax(node) }
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

    static func transform(
        _ node: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body,
              let newBrace = wrappedBrace(
                  leftBrace: body.leftBrace,
                  rightBrace: body.rightBrace,
                  context: context
              ) else { return DeclSyntax(node) }
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

    static func transform(
        _ node: DeinitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body,
              let newBrace = wrappedBrace(
                  leftBrace: body.leftBrace,
                  rightBrace: body.rightBrace,
                  context: context
              ) else { return DeclSyntax(node) }
        var result = node
        result.body!.leftBrace = newBrace
        result.deinitKeyword = result.deinitKeyword.with(
            \.trailingTrivia,
            result.deinitKeyword.trailingTrivia.trimmingTrailingWhitespace
        )
        return DeclSyntax(result)
    }

    // MARK: - Type declarations

    static func transform(
        _ node: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.memberBlock.leftBrace,
            rightBrace: node.memberBlock.rightBrace,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    static func transform(
        _ node: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.memberBlock.leftBrace,
            rightBrace: node.memberBlock.rightBrace,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    static func transform(
        _ node: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.memberBlock.leftBrace,
            rightBrace: node.memberBlock.rightBrace,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    static func transform(
        _ node: ActorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.memberBlock.leftBrace,
            rightBrace: node.memberBlock.rightBrace,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    static func transform(
        _ node: ProtocolDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.memberBlock.leftBrace,
            rightBrace: node.memberBlock.rightBrace,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    static func transform(
        _ node: ExtensionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let newBrace = wrappedBrace(
            leftBrace: node.memberBlock.leftBrace,
            rightBrace: node.memberBlock.rightBrace,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.memberBlock.leftBrace = newBrace
        stripTrailingOnLastSigToken(&result)
        return DeclSyntax(result)
    }

    // MARK: - Core helpers

    /// Returns a wrapped `leftBrace` token if the statement signature is multiline, or `nil` if no
    /// wrapping is needed.
    private static func wrappedBrace(
        leftBrace: TokenSyntax,
        rightBrace: TokenSyntax,
        context: Context
    ) -> TokenSyntax? {
        // Already on its own line.
        guard !leftBrace.leadingTrivia.containsNewlines else { return nil }

        // Body must be multiline.
        guard rightBrace.leadingTrivia.containsNewlines else { return nil }

        // Compare indentation: the line containing the token before `{` must be indented more than
        // the closing `}` line.
        guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return nil }
        let prevIndent = lineIndentation(of: prevToken)
        let closingIndent = rightBrace.leadingTrivia.indentation
        guard prevIndent.count > closingIndent.count else { return nil }

        Self.diagnose(.wrapOpeningBrace, on: leftBrace, context: context)

        return leftBrace.with(\.leadingTrivia, .newline + Trivia(stringLiteral: closingIndent))
    }

    /// Strips trailing whitespace from the last token of a type declaration's signature (before the
    /// member block).
    private static func stripTrailingOnLastSigToken<D: DeclSyntaxProtocol>(_ decl: inout D) {
        guard let leftBrace = decl.children(viewMode: .sourceAccurate)
            .compactMap({ $0.as(MemberBlockSyntax.self) }).first?.leftBrace,
              let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return }

        let trimmed = prevToken.trailingTrivia.trimmingTrailingWhitespace
        guard trimmed != prevToken.trailingTrivia else { return }

        let rewritten = TokenStripper(targetID: prevToken.id, newTrailing: trimmed)
            .rewrite(
                Syntax(decl)
            )
        decl = rewritten.cast(D.self)
    }

    /// Returns the indentation string of the line on which `token` resides.
    private static func lineIndentation(of token: TokenSyntax) -> String {
        var current = token

        while !current.leadingTrivia.containsNewlines {
            guard let prev = current.previousToken(viewMode: .sourceAccurate) else { return "" }
            current = prev
        }
        return current.leadingTrivia.indentation
    }

    /// Strips trailing whitespace from the token preceding a wrapped brace.
    private static func stripBeforeBrace<N: SyntaxProtocol>(
        _ node: inout N,
        leftBraceKeyPath: KeyPath<N, TokenSyntax>
    ) {
        let leftBrace = node[keyPath: leftBraceKeyPath]
        guard let prevToken = leftBrace.previousToken(viewMode: .sourceAccurate) else { return }
        let trimmed = prevToken.trailingTrivia.trimmingTrailingWhitespace
        guard trimmed != prevToken.trailingTrivia else { return }
        node = TokenStripper(targetID: prevToken.id, newTrailing: trimmed)
            .rewrite(
                Syntax(node)
            ).cast(N.self)
    }
}

/// A rewriter that replaces a single token's trailing trivia.
private final class TokenStripper: SyntaxRewriter {
    let targetID: SyntaxIdentifier
    let newTrailing: Trivia

    init(targetID: SyntaxIdentifier, newTrailing: Trivia) {
        self.targetID = targetID
        self.newTrailing = newTrailing
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        token.id == targetID ? token.with(\.trailingTrivia, newTrailing) : token
    }
}

fileprivate extension Finding.Message {
    static let wrapOpeningBrace: Finding.Message =
        "move opening brace to its own line for multiline statement"
}
