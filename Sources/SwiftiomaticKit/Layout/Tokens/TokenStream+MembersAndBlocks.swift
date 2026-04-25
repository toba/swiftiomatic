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
    func visitIfConfigDecl(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        // there has to be a break after an #endif
        after(node.poundEndif, tokens: .break(.same, size: 0))
        return .visitChildren
    }

    func visitMemberBlock(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitMemberBlockItemList(_ node: MemberBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        // Skip ignored items, because the tokens after `item.lastToken` would be ignored and leave
        // unclosed open tokens.
        for item in node where !shouldFormatterIgnore(node: Syntax(item)) {
            before(item.firstToken(viewMode: .sourceAccurate), tokens: .open)
            let newlines: NewlineBehavior =
                item != node.last && shouldInsertNewline(basedOn: item.semicolon)
                ? .soft : .elective
            let resetSize = item.semicolon != nil ? 1 : 0
            after(
                item.lastToken(viewMode: .sourceAccurate),
                tokens: .close,
                .break(.reset, size: resetSize, newlines: newlines)
            )
        }
        return .visitChildren
    }

    func visitMemberBlockItem(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if shouldFormatterIgnore(node: Syntax(node)) {
            appendFormatterIgnored(node: Syntax(node))
            return .skipChildren
        }
        return .visitChildren
    }

    func visitSourceFile(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        if shouldFormatterIgnore(file: node) {
            appendToken(.verbatim(Verbatim(text: "\(node)", indentingBehavior: .none)))
            return .skipChildren
        }
        after(node.shebang, tokens: .break(.same, newlines: .soft))
        after(node.endOfFileToken, tokens: .break(.same, newlines: .soft))
        return .visitChildren
    }

    func visitEnumCaseDecl(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )

        after(node.caseKeyword, tokens: .break)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitOperatorDecl(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        after(node.fixitySpecifier, tokens: .break)
        after(node.operatorKeyword, tokens: .break)
        return .visitChildren
    }

    func visitOperatorPrecedenceAndTypes(_ node: OperatorPrecedenceAndTypesSyntax) -> SyntaxVisitorContinueKind {
        before(node.colon, tokens: .space)
        after(node.colon, tokens: .break(.open), .open)
        after(
            node.designatedTypes.lastToken(viewMode: .sourceAccurate)
                ?? node.lastToken(viewMode: .sourceAccurate),
            tokens: .break(.close, size: 0),
            .close
        )
        return .visitChildren
    }

    func visitDesignatedType(_ node: DesignatedTypeSyntax) -> SyntaxVisitorContinueKind {
        after(node.leadingComma, tokens: .break(.same))
        return .visitChildren
    }

    func visitEnumCaseElement(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
        after(node.trailingComma, tokens: .break)

        if let associatedValue = node.parameterClause {
            arrangeEnumCaseParameterClause(associatedValue, forcesBreakBeforeRightParen: false)
        }

        if let initializer = node.rawValue {
            if let (unindentingNode, _, breakKind, shouldGroup) =
                stackedIndentationBehavior(rhs: initializer.value)
            {
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
        }

        return .visitChildren
    }

    func visitObjCSelectorPieceList(_ node: ObjCSelectorPieceListSyntax) -> SyntaxVisitorContinueKind {
        insertTokens(.break(.same, size: 0), betweenElementsOf: node)
        return .visitChildren
    }

    func visitPrecedenceGroupDecl(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
        after(node.precedencegroupKeyword, tokens: .break)
        after(node.name, tokens: .break(.reset))
        after(node.leftBrace, tokens: .break(.open, newlines: .soft))
        before(node.rightBrace, tokens: .break(.close))
        return .visitChildren
    }

    func visitPrecedenceGroupRelation(_ node: PrecedenceGroupRelationSyntax) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .break(.open))
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .break(.close, newlines: .soft))
        return .visitChildren
    }

    func visitPrecedenceGroupAssignment(_ node: PrecedenceGroupAssignmentSyntax) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .break(.open))
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .break(.close, newlines: .soft))
        return .visitChildren
    }

    func visitPrecedenceGroupName(_ node: PrecedenceGroupNameSyntax) -> SyntaxVisitorContinueKind {
        after(node.trailingComma, tokens: .break(.same))
        return .visitChildren
    }

    func visitPrecedenceGroupAssociativity(_ node: PrecedenceGroupAssociativitySyntax) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .break(.open))
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .break(.close, newlines: .soft))
        return .visitChildren
    }

    func visitCodeBlock(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitCodeBlockItemList(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        // Skip ignored items, because the tokens after `item.lastToken` would be ignored and leave
        // unclosed open tokens.
        for item in node where !shouldFormatterIgnore(node: Syntax(item)) {
            before(item.firstToken(viewMode: .sourceAccurate), tokens: .open)
            var newlines: NewlineBehavior =
                item != node.last && shouldInsertNewline(basedOn: item.semicolon)
                ? .soft : .elective
            let resetSize = item.semicolon != nil ? 1 : 0

            // Remove blank lines between consecutive import statements.
            if let nextItem = node[node.index(after: node.index(of: item)!)...].first(where: {
                !shouldFormatterIgnore(node: Syntax($0))
            }),
                item.item.is(ImportDeclSyntax.self),
                nextItem.item.is(ImportDeclSyntax.self)
            {
                newlines = .soft(count: 1, discretionary: false, maxBlankLines: 0)
            }

            after(
                item.lastToken(viewMode: .sourceAccurate),
                tokens: .close,
                .break(.reset, size: resetSize, newlines: newlines)
            )
        }
        return .visitChildren
    }

    func visitCodeBlockItem(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if shouldFormatterIgnore(node: Syntax(node)) {
            appendFormatterIgnored(node: Syntax(node))
            return .skipChildren
        }

        // This group applies to a top-level if-stmt so that all of the bodies will have the same
        // breaking behavior.
        if let exprStmt = node.item.as(ExpressionStmtSyntax.self),
            let ifStmt = exprStmt.expression.as(IfExprSyntax.self)
        {
            before(
                ifStmt.conditions.firstToken(viewMode: .sourceAccurate),
                tokens: .open(.consistent)
            )
            after(ifStmt.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }
}
