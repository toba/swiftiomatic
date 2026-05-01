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
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )

        after(node.associatedtypeKeyword, tokens: .break)

        if let genericWhereClause = node.genericWhereClause {
            before(
                genericWhereClause.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.same),
                .open
            )
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
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

        after(node.whereKeyword, tokens: .break(.open))
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .break(.close, size: 0))

        before(
            node.requirements.firstToken(viewMode: .sourceAccurate),
            tokens: .open(genericRequirementListConsistency())
        )
        after(node.requirements.lastToken(viewMode: .sourceAccurate), tokens: .close)

        return .visitChildren
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
        } else if node.arguments != nil {
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
