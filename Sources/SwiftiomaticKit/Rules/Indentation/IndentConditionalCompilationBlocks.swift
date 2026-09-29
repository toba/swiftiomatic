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

        // When the `#if` wraps switch cases (the enclosing `IfConfigDecl` is a direct element of a
        // `SwitchCaseListSyntax`), the clause contents are `case` labels, not a fresh code block.
        // Indenting them would push the case one level past its sibling cases, so the
        // conditional-compilation indentation is suppressed here regardless of the setting; the
        // case labels keep their normal switch-case indentation.
        let wrapsSwitchCases = node.parent?.parent?.parent?.is(SwitchCaseListSyntax.self) ?? false
        let continuesPostfixChain = isNestedInPostfixIfConfig(node: Syntax(node))

        if config[IndentConditionalCompilationBlocks.self], !wrapsSwitchCases {
            breakKindOpen = .open
            breakKindClose = .close
        } else if continuesPostfixChain {
            // A modifier guarded by a postfix #if continues the chain above it, so the break into
            // the clause body carries the chain's continuation indentation. A same break would
            // clear that indentation and drop the modifier to the enclosing statement's column. The
            // break before the closing #elseif, #else or #endif stays the same kind, because the
            // contextual break that insertContextualBreaks already emits before each of those
            // tokens sets their column.
            breakKindOpen = .contextual
            breakKindClose = .same
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
        //
        // The closing tokens are normally attached after the last token of the body. If that last
        // token belongs to a formatter-ignored item, however, it is never visited (its node is
        // emitted as a single verbatim token), so an `after` group on it would be dropped and the
        // `.open` above would be left unclosed. In that case, attach the closing tokens before the
        // following token (the next `#elseif`/`#else`/`#endif`) instead, which is always visited.
        if let lastElemTok = node.elements?.lastToken(viewMode: .sourceAccurate),
           !isFormatterIgnored(lastElemTok)
        {
            after(lastElemTok, tokens: .break(breakKindClose, newlines: .soft), .close)
        } else {
            let tokenAfterBody = node.elements?.lastToken(viewMode: .sourceAccurate)?
                .nextToken(viewMode: .all)
                ?? tokenToOpenWith.nextToken(viewMode: .all)
            before(tokenAfterBody, tokens: .break(breakKindClose, newlines: .soft), .close)
        }

        if !continuesPostfixChain, let condition = node.condition {
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
