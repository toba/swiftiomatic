import SwiftSyntax

/// Opening braces of multiline statements are wrapped to their own line.
///
/// When a statement signature (conditions, parameters, etc.) spans multiple lines, the opening `{`
/// is moved to its own line, aligned with the statement keyword.
///
/// Lint: A `{` on the same line as a multiline statement signature raises a warning.
///
/// Rewrite: The `{` is moved to a new line aligned with the closing `}` .
final class WrapMultilineStatementBraces: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var key: String { "multilineStatementBraces" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Compact-pipeline static transforms

    static func transform(
        _ node: IfExprSyntax, parent: Syntax?, context: Context
    ) -> ExprSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: GuardStmtSyntax, parent: Syntax?, context: Context
    ) -> StmtSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: ForStmtSyntax, parent: Syntax?, context: Context
    ) -> StmtSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: WhileStmtSyntax, parent: Syntax?, context: Context
    ) -> StmtSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: DoStmtSyntax, parent: Syntax?, context: Context
    ) -> StmtSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: SwitchExprSyntax, parent: Syntax?, context: Context
    ) -> ExprSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: FunctionDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: InitializerDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: DeinitializerDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: ClassDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: StructDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: EnumDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: ActorDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: ProtocolDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
    static func transform(
        _ node: ExtensionDeclSyntax, parent: Syntax?, context: Context
    ) -> DeclSyntax {
        _ = parent
        return applyWrapMultilineStatementBraces(node, context: context)
    }
}
