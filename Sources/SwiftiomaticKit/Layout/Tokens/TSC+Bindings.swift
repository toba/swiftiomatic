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

extension TokenStreamCreator {
    func visitVariableDecl(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )

        if node.bindings.count == 1 {
            // If there is only a single binding, don't allow a break between the `let/var` keyword and
            // the identifier; there are better places to break later on.
            after(node.bindingSpecifier, tokens: .space)
        } else {
            // If there is more than one binding, we permit an open-break after `let/var` so that each of
            // the comma-delimited items will potentially receive indentation. We also add a group around
            // the individual bindings to bind them together better. (This is done here, not in
            // `visit(_: PatternBindingSyntax)`, because we only want that behavior when there are
            // multiple bindings.)
            after(node.bindingSpecifier, tokens: .break(.open))

            for binding in node.bindings {
                before(binding.firstToken(viewMode: .sourceAccurate), tokens: .open)
                after(binding.trailingComma, tokens: .break(.same))
                after(binding.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }

            after(node.lastToken(viewMode: .sourceAccurate), tokens: .break(.close, size: 0))
        }

        return .visitChildren
    }

    func visitPatternBinding(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        // If the type annotation and/or the initializer clause need to wrap, we want those
        // continuations to stack to improve readability. So, we need to keep track of how many open
        // breaks we create (so we can close them at the end of the binding) and also keep track of the
        // right-most token that will anchor the close breaks.
        var closesNeeded: Int = 0
        var closeAfterToken: TokenSyntax? = nil

        if let typeAnnotation = node.typeAnnotation, !typeAnnotation.type.is(MissingTypeSyntax.self)
        {
            after(
                typeAnnotation.colon,
                tokens: .break(
                    .open(kind: .continuation),
                    newlines: .elective(ignoresDiscretionary: true)
                )
            )
            closesNeeded += 1
            closeAfterToken = typeAnnotation.lastToken(viewMode: .sourceAccurate)
        }
        if let initializer = node.initializer {
            let expr = initializer.value

            if let (unindentingNode, _, breakKind, shouldGroup) = stackedIndentationBehavior(
                rhs: expr
            ) {
                var openTokens: [Token] = [.break(.open(kind: breakKind))]
                if shouldGroup {
                    openTokens.append(.open)
                }
                after(initializer.equal, tokens: openTokens)
                var closeTokens: [Token] = [.break(.close(mustBreak: false), size: 0)]
                if shouldGroup {
                    closeTokens.append(.close)
                }
                after(unindentingNode.lastToken(viewMode: .sourceAccurate), tokens: closeTokens)
            } else {
                after(initializer.equal, tokens: .break(.continue))
            }
            closeAfterToken = initializer.lastToken(viewMode: .sourceAccurate)

            // When the RHS is a simple expression, even if is requires multiple lines, we don't add a
            // group so that as much of the expression as possible can stay on the same line as the
            // operator token.
            if isCompoundExpression(expr) && leftmostMultilineStringLiteral(of: expr) == nil {
                before(expr.firstToken(viewMode: .sourceAccurate), tokens: .open)
                after(expr.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }
        }

        if let accessorBlock = node.accessorBlock {
            switch accessorBlock.accessors {
            case .accessors(let accessors):
                arrangeBracesAndContents(
                    leftBrace: accessorBlock.leftBrace,
                    accessors: accessors,
                    rightBrace: accessorBlock.rightBrace
                )
            case .getter:
                arrangeBracesAndContents(of: accessorBlock, contentsKeyPath: \.getterCodeBlockItems)
            }
        } else if let trailingComma = node.trailingComma {
            // If this is one of multiple comma-delimited bindings, move any pending close breaks to
            // follow the comma so that it doesn't get separated from the tokens before it.
            closeAfterToken = trailingComma
            closingDelimiterTokens.insert(trailingComma)
        }

        if closeAfterToken != nil && closesNeeded > 0 {
            let closeTokens = [Token](repeatElement(.break(.close, size: 0), count: closesNeeded))
            after(closeAfterToken, tokens: closeTokens)
        }

        return .visitChildren
    }

    func visitInheritedType(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
        after(node.trailingComma, tokens: .break(.same))
        return .visitChildren
    }

    func visitIsTypePattern(_ node: IsTypePatternSyntax) -> SyntaxVisitorContinueKind {
        after(node.isKeyword, tokens: .space)
        return .visitChildren
    }

    func visitTypeAliasDecl(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )

        after(node.typealiasKeyword, tokens: .break)

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

    func visitTypeInitializerClause(_ node: TypeInitializerClauseSyntax)
        -> SyntaxVisitorContinueKind
    {
        before(node.equal, tokens: .space)
        after(node.equal, tokens: .break)
        return .visitChildren
    }

    func visitAttributedType(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        let breakToken: Token = .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        for specifier in node.specifiers {
            after(
                specifier.lastToken(viewMode: .sourceAccurate),
                tokens: breakToken
            )
        }
        arrangeAttributeList(
            node.attributes,
            suppressFinalBreak: false,
            lineBreak: breakToken,
            shouldGroup: false
        )
        for specifier in node.lateSpecifiers {
            after(
                specifier.lastToken(viewMode: .sourceAccurate),
                tokens: breakToken
            )
        }

        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitDeclReferenceExpr(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitNilLiteralExpr(_ node: NilLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitGenericSpecializationExpr(_ node: GenericSpecializationExprSyntax)
        -> SyntaxVisitorContinueKind
    {
        return .visitChildren
    }

    func visitTypeAnnotation(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        before(node.type.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.type.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitSomeOrAnyType(_ node: SomeOrAnyTypeSyntax) -> SyntaxVisitorContinueKind {
        after(node.someOrAnySpecifier, tokens: .space)
        return .visitChildren
    }

    func visitCompositionType(_ node: CompositionTypeSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitFallThroughStmt(_ node: FallThroughStmtSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitForceUnwrapExpr(_ node: ForceUnwrapExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitGenericArgument(_ node: GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitWildcardPattern(_ node: WildcardPatternSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitDeclNameArgument(_ node: DeclNameArgumentSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitFloatLiteralExpr(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitGenericParameter(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.specifier, tokens: .break)
        after(node.colon, tokens: .break)
        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitPrimaryAssociatedType(_ node: PrimaryAssociatedTypeSyntax)
        -> SyntaxVisitorContinueKind
    {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitPackElementExpr(_ node: PackElementExprSyntax) -> SyntaxVisitorContinueKind {
        // `each` cannot be separated from the following token, or it is parsed as an identifier itself.
        after(node.eachKeyword, tokens: .space)
        return .visitChildren
    }

    func visitPackElementType(_ node: PackElementTypeSyntax) -> SyntaxVisitorContinueKind {
        // `each` cannot be separated from the following token, or it is parsed as an identifier itself.
        after(node.eachKeyword, tokens: .space)
        return .visitChildren
    }

    func visitPackExpansionExpr(_ node: PackExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        after(node.repeatKeyword, tokens: .break)
        return .visitChildren
    }

    func visitPackExpansionType(_ node: PackExpansionTypeSyntax) -> SyntaxVisitorContinueKind {
        after(node.repeatKeyword, tokens: .break)
        return .visitChildren
    }

    func visitExpressionPattern(_ node: ExpressionPatternSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitValueBindingPattern(_ node: ValueBindingPatternSyntax) -> SyntaxVisitorContinueKind {
        after(node.bindingSpecifier, tokens: .break)
        return .visitChildren
    }

    func visitIdentifierPattern(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitInitializerClause(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        before(node.equal, tokens: .space)

        // InitializerClauses that are children of a PatternBindingSyntax, EnumCaseElementSyntax, or
        // OptionalBindingConditionSyntax are already handled in the latter node, to ensure that
        // continuations stack appropriately.
        if let parent = node.parent,
            !parent.is(PatternBindingSyntax.self)
                && !parent.is(OptionalBindingConditionSyntax.self)
                && !parent.is(EnumCaseElementSyntax.self)
        {
            after(node.equal, tokens: .break)
        }
        return .visitChildren
    }
}
