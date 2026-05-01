import SwiftSyntax

/// Indent #if/#elseif/#else blocks.
package struct IndentConditionalCompilationBlocks: LayoutRule {
    package static let group: ConfigurationGroup? = .indentation
    package static let description = "Indent #if/#elseif/#else blocks."
    package static let defaultValue = false
}

extension TokenStream {
    func visitIfConfigClause(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
        switch node.poundKeyword.tokenKind {
            case .poundIf, .poundElseif: after(node.poundKeyword, tokens: .space)
            case .poundElse: break
            default: preconditionFailure()
        }

        let breakKindOpen: BreakKind
        let breakKindClose: BreakKind

        if config[IndentConditionalCompilationBlocks.self] {
            breakKindOpen = .open
            breakKindClose = .close
        } else {
            breakKindOpen = .same
            breakKindClose = .same
        }

        let tokenToOpenWith = node.condition?.lastToken(viewMode: .sourceAccurate)
            ?? node.poundKeyword
        after(tokenToOpenWith, tokens: .break(breakKindOpen), .open)

        // Unlike other code blocks, where we may want a single statement to be laid out on the same
        // line as a parent construct, the content of an `#if` block must always be on its own line;
        // the newline token inserted at the end enforces this.
        if let lastElemTok = node.elements?.lastToken(viewMode: .sourceAccurate) {
            after(lastElemTok, tokens: .break(breakKindClose, newlines: .soft), .close)
        } else {
            before(
                tokenToOpenWith.nextToken(viewMode: .all),
                tokens: .break(breakKindClose, newlines: .soft),
                .close
            )
        }

        if !isNestedInPostfixIfConfig(node: Syntax(node)), let condition = node.condition {
            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .printerControl(kind: .disableBreaking(allowDiscretionary: true))
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .printerControl(kind: .enableBreaking),
                .break(.reset, size: 0)
            )
        }

        return .visitChildren
    }
}
