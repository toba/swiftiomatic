import SwiftSyntax

/// Collapses multi-line `if`/`else` (and `else if` chains) onto a single line
/// when every branch contains exactly one statement and the collapsed form fits
/// within the configured line length.
///
/// Complements `PreferTernary` for cases ternary can't reach: `if let`/`if case`
/// conditional bindings, `if #available`, and multi-clause conditions.
///
/// ```swift
/// // Before
/// if let defaultValue = last?.defaultValue {
///     defaultValue
/// } else {
///     last?.type
/// }
///
/// // After
/// if let defaultValue = last?.defaultValue { defaultValue } else { last?.type }
/// ```
///
/// Lint: A multi-line if/else where each branch has a single statement and the
///       collapsed form fits within line length raises a warning.
///
/// Format: The chain is collapsed onto a single line.
final class CollapseSimpleIfElse: RewriteSyntaxRule<BasicRuleValue> {
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue {
        BasicRuleValue(rewrite: false, lint: .no)
    }

    private var maxLength: Int { context.configuration[LineLength.self] }

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        // Recurse first so nested ifs collapse before we measure ourselves.
        let visited = super.visit(node)
        guard let ifNode = visited.as(IfExprSyntax.self) else { return visited }

        // Only act at the chain top — `else if` links are reached through the outer if.
        if node.parent?.is(IfExprSyntax.self) == true { return visited }

        // Bare `if` with no else is `WrapSingleLineBodies`'s territory.
        guard ifNode.elseBody != nil else { return visited }

        if isAlreadyInline(ifNode) { return visited }
        guard validateChain(ifNode) else { return visited }

        let indent = ifNode.ifKeyword.leadingTrivia.indentation
        guard indent.count + collapsedTextLength(of: ifNode) <= maxLength else {
            return visited
        }

        diagnose(.collapseIfElse, on: ifNode.ifKeyword)

        return ExprSyntax(collapseChain(ifNode))
    }
}

// MARK: - Validation

extension CollapseSimpleIfElse {

    /// Whether the entire chain is already on a single source line.
    private func isAlreadyInline(_ node: IfExprSyntax) -> Bool {
        var current = node
        while true {
            if current.body.leftBrace.trailingTrivia.containsNewlines { return false }
            if current.body.rightBrace.leadingTrivia.containsNewlines { return false }
            switch current.elseBody {
            case nil:
                return true
            case .ifExpr(let next):
                if next.ifKeyword.leadingTrivia.containsNewlines { return false }
                current = next
            case .codeBlock(let block):
                if block.leftBrace.leadingTrivia.containsNewlines { return false }
                if block.leftBrace.trailingTrivia.containsNewlines { return false }
                if block.rightBrace.leadingTrivia.containsNewlines { return false }
                return true
            }
        }
    }

    /// Validates that every branch in the chain has exactly one statement and no comments.
    private func validateChain(_ node: IfExprSyntax) -> Bool {
        var current = node
        while true {
            guard validateBody(current.body) else { return false }
            switch current.elseBody {
            case nil:
                return true
            case .ifExpr(let next):
                current = next
            case .codeBlock(let block):
                return validateBody(block)
            }
        }
    }

    private func validateBody(_ body: CodeBlockSyntax) -> Bool {
        guard body.statements.count == 1, let stmt = body.statements.first else { return false }
        if hasComment(body.leftBrace.leadingTrivia) { return false }
        if hasComment(body.leftBrace.trailingTrivia) { return false }
        if hasComment(stmt.leadingTrivia) { return false }
        if hasComment(stmt.trailingTrivia) { return false }
        if hasComment(body.rightBrace.leadingTrivia) { return false }
        if hasComment(body.rightBrace.trailingTrivia) { return false }
        return true
    }

    private func hasComment(_ trivia: Trivia) -> Bool {
        for piece in trivia {
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                return true
            default:
                continue
            }
        }
        return false
    }
}

// MARK: - Length

extension CollapseSimpleIfElse {

    /// Length of the rendered collapsed chain (excluding leading indentation).
    private func collapsedTextLength(of node: IfExprSyntax) -> Int {
        var text = ""
        var current = node
        var first = true
        while true {
            if first {
                text += "if " + current.conditions.trimmedDescription
                first = false
            } else {
                text += " else if " + current.conditions.trimmedDescription
            }
            text += " { " + current.body.statements.first!.trimmedDescription + " }"
            switch current.elseBody {
            case nil:
                return text.count
            case .ifExpr(let next):
                current = next
            case .codeBlock(let block):
                text += " else { " + block.statements.first!.trimmedDescription + " }"
                return text.count
            }
        }
    }
}

// MARK: - Transformation

extension CollapseSimpleIfElse {

    private func collapseChain(_ node: IfExprSyntax) -> IfExprSyntax {
        var result = node
        result.conditions = clearTrailingTrivia(result.conditions)
        let isTerminal = result.elseBody == nil
        result.body = inlineBody(result.body, terminal: isTerminal)

        switch result.elseBody {
        case nil:
            return result
        case .ifExpr(let next):
            var collapsedNext = collapseChain(next)
            collapsedNext.ifKeyword = collapsedNext.ifKeyword.with(\.leadingTrivia, [])
            if let elseKeyword = result.elseKeyword {
                result.elseKeyword =
                    elseKeyword
                    .with(\.leadingTrivia, .space)
                    .with(\.trailingTrivia, .space)
            }
            result.elseBody = .ifExpr(collapsedNext)
            return result
        case .codeBlock(let block):
            var newBlock = inlineBody(block, terminal: true)
            newBlock.leftBrace = newBlock.leftBrace.with(\.leadingTrivia, .space)
            if let elseKeyword = result.elseKeyword {
                result.elseKeyword =
                    elseKeyword
                    .with(\.leadingTrivia, .space)
                    .with(\.trailingTrivia, [])
            }
            result.elseBody = .codeBlock(newBlock)
            return result
        }
    }

    /// Inlines a code block's content onto a single line. When `terminal` is
    /// false, strips the trailing trivia of the closing brace so the next
    /// `else` keyword sits one space away.
    private func inlineBody(_ body: CodeBlockSyntax, terminal: Bool) -> CodeBlockSyntax {
        var result = body
        result.leftBrace =
            result.leftBrace
            .with(\.leadingTrivia, .space)
            .with(\.trailingTrivia, .space)

        var stmts = Array(result.statements)
        stmts[0].leadingTrivia = []
        stmts[stmts.count - 1].trailingTrivia = []
        result.statements = CodeBlockItemListSyntax(stmts)

        if terminal {
            result.rightBrace = result.rightBrace.with(\.leadingTrivia, .space)
        } else {
            result.rightBrace =
                result.rightBrace
                .with(\.leadingTrivia, .space)
                .with(\.trailingTrivia, [])
        }
        return result
    }

    /// Clears trailing trivia on the last condition element so the following
    /// left brace's leading `.space` doesn't produce a double space.
    private func clearTrailingTrivia(
        _ conditions: ConditionElementListSyntax
    ) -> ConditionElementListSyntax {
        guard var last = conditions.last else { return conditions }
        last.trailingTrivia = []
        var list = Array(conditions)
        list[list.count - 1] = last
        return ConditionElementListSyntax(list)
    }
}

// MARK: - Finding Messages

extension Finding.Message {
    fileprivate static let collapseIfElse: Finding.Message =
        "collapse simple if/else onto a single line"
}
