//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension TokenStream {
    func visitAssociatedTypeDecl(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BreakBetweenDeclAttributes.self]
        )

        after(node.associatedtypeKeyword, tokens: .break)

        if let genericWhereClause = node.genericWhereClause {
            arrangeGenericWhereClause(genericWhereClause, trailingClose: nil)
        }
        return .visitChildren
    }

    func visitBooleanLiteralExpr(_: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitGenericWhereClause(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {
        guard node.whereKeyword != node.lastToken(viewMode: .sourceAccurate) else {
            verbatimToken(Syntax(node))
            return .skipChildren
        }

        let isMultiLine = multiLineWhereClauses.contains(node.id)
        let listConsistency: GroupBreakStyle =
            if isMultiLine { .consistent }
            else { genericRequirementListConsistency() }

        if isMultiLine {
            // Close the outer group from `arrangeGenericWhereClause` BEFORE emitting the forced
            // break, so the break-before-where chunk is bounded by the `where` keyword alone —
            // keeping `where` glued to the preceding decl token. Both tokens are emitted in a
            // single `after()` call so afterMap reversal preserves order.
            after(node.whereKeyword, tokens: .close, .break(.open, newlines: .soft))
        } else {
            after(node.whereKeyword, tokens: .break(.open))
        }
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .break(.close, size: 0))

        before(
            node.requirements.firstToken(viewMode: .sourceAccurate),
            tokens: .open(listConsistency)
        )
        after(node.requirements.lastToken(viewMode: .sourceAccurate), tokens: .close)

        return .visitChildren
    }

    /// Emits the `before`/`after` tokens around a generic-where clause, choosing between two
    /// layouts based on whether its requirements will fit on a single wrapped line:
    ///
    /// 1. **Single-line wrap** (default): a `.break(.continue)` precedes `where`, allowing it and
    ///    the requirements to flow to the next line together when the parent group breaks.
    /// 2. **Multi-line wrap**: when the requirements would not fit on a single subsequent line,
    ///    `where` is glued to the preceding decl token and each requirement is forced onto its own
    ///    line.
    ///
    /// The `trailingClose` token is the source-token AFTER which the closing `.close` of the
    /// surrounding group should be emitted (typically the brace of the body, or the last token of
    /// the where clause itself when there is no body).
    func arrangeGenericWhereClause(
        _ clause: GenericWhereClauseSyntax,
        trailingClose: TokenSyntax?
    ) {
        let firstToken = clause.firstToken(viewMode: .sourceAccurate)

        if shouldForceMultiLineWhereClause(clause) {
            multiLineWhereClauses.insert(clause.id)
            // Wrap only `where` itself in the outer group so that the break before `where` has a
            // tiny chunk and almost never fires — keeping `where` glued to the preceding decl
            // token. The matching `.close` and the forced newline are emitted in
            // `visitGenericWhereClause` (in a single `after()` call so the afterMap reversal
            // preserves their relative order).
            before(firstToken, tokens: .break(.continue), .open)
        } else {
            let closeAnchor = trailingClose ?? clause.lastToken(viewMode: .sourceAccurate)
            before(firstToken, tokens: .break(.continue), .open)
            after(closeAnchor, tokens: .close)
        }
    }

    /// Decides whether a generic-where clause's requirements list should be forced onto multiple
    /// lines. The heuristic compares the rendered width of `where <requirements>` against the
    /// available width on a wrapped line (line length minus one continuation indent). When the
    /// where-clause text would not fit on a single subsequent line, return true so that the caller
    /// emits the multi-line layout.
    private func shouldForceMultiLineWhereClause(_ clause: GenericWhereClauseSyntax) -> Bool {
        let requirementsText = clause.requirements.trimmedDescription
        let whereWidth = "where ".count + requirementsText.count
        let indentWidth: Int =
            switch config[IndentationSetting.self] {
                case let .spaces(n): n
                case let .tabs(n): n * config[TabWidth.self]
            }
        let available = max(0, maxLineLength - indentWidth)
        return whereWidth > available
    }

    func visitIntegerLiteralExpr(_: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitImportPathComponent(_: ImportPathComponentSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitGenericRequirement(_ node: GenericRequirementSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitSameTypeRequirement(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
        before(node.equal, tokens: .break)
        after(node.equal, tokens: .space)

        return .visitChildren
    }

    func visitConformanceRequirement(
        _ node: ConformanceRequirementSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .break)

        return .visitChildren
    }

    func visitTuplePatternElement(_ node: TuplePatternElementSyntax) -> SyntaxVisitorContinueKind {
        after(node.trailingComma, tokens: .break(.same))
        return .visitChildren
    }

    func visitMemberType(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
        before(node.period, tokens: .break(.continue, size: 0))
        return .visitChildren
    }

    func visitOptionalChainingExpr(_: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitIdentifierType(_: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitAvailabilityCondition(_: AvailabilityConditionSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitDiscardAssignmentExpr(_: DiscardAssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitEditorPlaceholderExpr(_: EditorPlaceholderExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitBorrowExpr(_ node: BorrowExprSyntax) -> SyntaxVisitorContinueKind {
        // The `borrow` keyword cannot be separated from the following token or it will be parsed as
        // an identifier.
        after(node.borrowKeyword, tokens: .space)
        return .visitChildren
    }

    func visitConsumeExpr(_ node: ConsumeExprSyntax) -> SyntaxVisitorContinueKind {
        // The `consume` keyword cannot be separated from the following token or it will be parsed
        // as an identifier.
        after(node.consumeKeyword, tokens: .space)
        return .visitChildren
    }

    func visitCopyExpr(_ node: CopyExprSyntax) -> SyntaxVisitorContinueKind {
        // The `copy` keyword cannot be separated from the following token or it will be parsed as
        // an identifier.
        after(node.copyKeyword, tokens: .space)
        return .visitChildren
    }

    func visitDiscardStmt(_ node: DiscardStmtSyntax) -> SyntaxVisitorContinueKind {
        // The `discard` keyword cannot be separated from the following token or it will be parsed
        // as an identifier.
        after(node.discardKeyword, tokens: .space)
        return .visitChildren
    }

    func visitInheritanceClause(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        // Normally, the open-break is placed before the open token. In this case, it's
        // intentionally ordered differently so that the inheritance list can start on the current
        // line and only breaks if the first item in the list would overflow the column limit.
        before(
            node.inheritedTypes.firstToken(viewMode: .sourceAccurate),
            tokens: .open,
            .break(.open, size: 1)
        )
        after(
            node.inheritedTypes.lastToken(viewMode: .sourceAccurate),
            tokens: .break(.close, size: 0),
            .close
        )
        return .visitChildren
    }

    func visitPatternExpr(_: PatternExprSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitCompositionTypeElement(
        _ node: CompositionTypeElementSyntax
    ) -> SyntaxVisitorContinueKind {
        before(node.ampersand, tokens: .break)
        after(node.ampersand, tokens: .space)
        return .visitChildren
    }

    func visitMatchingPatternCondition(
        _ node: MatchingPatternConditionSyntax
    ) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.caseKeyword, tokens: .break)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitOptionalBindingCondition(
        _ node: OptionalBindingConditionSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.bindingSpecifier, tokens: .break)

        if let typeAnnotation = node.typeAnnotation {
            after(
                typeAnnotation.colon,
                tokens: .break(
                    .open(kind: .continuation),
                    newlines: .elective(ignoresDiscretionary: true)
                )
            )
            after(
                typeAnnotation.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        if let initializer = node.initializer {
            if let (unindentingNode, _, breakKind, shouldGroup) =
                stackedIndentationBehavior(rhs: initializer.value)
            {
                var openTokens: [Token] = [.break(.open(kind: breakKind))]
                if shouldGroup { openTokens.append(.open) }
                after(initializer.equal, tokens: openTokens)

                var closeTokens: [Token] = [.break(.close(mustBreak: false), size: 0)]
                if shouldGroup { closeTokens.append(.close) }
                after(unindentingNode.lastToken(viewMode: .sourceAccurate), tokens: closeTokens)
            } else {
                after(initializer.equal, tokens: .break(.continue))
            }
        }

        return .visitChildren
    }

    func visitImplicitlyUnwrappedOptionalType(
        _: ImplicitlyUnwrappedOptionalTypeSyntax
    ) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitDifferentiableAttributeArguments(
        _ node: DifferentiableAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        // This node encapsulates the entire list of arguments in a `@differentiable(...)`
        // attribute.
        var needsBreakBeforeWhereClause = false

        if let diffParamsComma = node.argumentsComma {
            after(diffParamsComma, tokens: .break(.same))
        } else if node.arguments != nil
        {
            needsBreakBeforeWhereClause = true
        }

        if let whereClause = node.genericWhereClause {
            if needsBreakBeforeWhereClause {
                before(whereClause.firstToken(viewMode: .sourceAccurate), tokens: .break(.same))
            }
            before(whereClause.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(whereClause.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitDifferentiabilityArguments(
        _ node: DifferentiabilityArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.leftParen, tokens: .break(.open, size: 0), .open)
        before(node.rightParen, tokens: .break(.close, size: 0), .close)
        return .visitChildren
    }

    func visitDifferentiabilityArgument(
        _ node: DifferentiabilityArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.trailingComma, tokens: .break(.same))
        return .visitChildren
    }

    func visitDerivativeAttributeArguments(
        _ node: DerivativeAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        // This node encapsulates the entire list of arguments in a `@derivative(...)` or
        // `@transpose(...)` attribute.
        before(node.ofLabel, tokens: .open)
        after(
            node.colon,
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )
        // The comma after originalDeclName is optional and is only present if there are diffParams.
        after(
            node.comma ?? node.originalDeclName.lastToken(viewMode: .sourceAccurate),
            tokens: .close
        )

        if let diffParams = node.arguments {
            before(diffParams.firstToken(viewMode: .sourceAccurate), tokens: .break(.same), .open)
            after(diffParams.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        return .visitChildren
    }

    func visitDifferentiabilityWithRespectToArgument(
        _ node: DifferentiabilityWithRespectToArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        // This node encapsulates the `wrt:` label and value/variable in a `@differentiable` ,
        // `@derivative` , or `@transpose` attribute.
        after(
            node.colon,
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )
        return .visitChildren
    }

    // MARK: - Nodes representing unexpected or malformed syntax

    func visitUnexpectedNodes(_ node: UnexpectedNodesSyntax) -> SyntaxVisitorContinueKind {
        verbatimToken(Syntax(node))
        return .skipChildren
    }
}
