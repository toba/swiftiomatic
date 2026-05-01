// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import SwiftSyntax

/// Semicolons should not be present in Swift code.
///
/// Lint: If a semicolon appears anywhere, a lint error is raised.
///
/// Rewrite: All semicolons will be replaced with line breaks.
final class NoSemicolons: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ node: CodeBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        Self.removingSemicolons(from: node, context: context, diagnose: false)
    }

    static func transform(
        _ node: MemberBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> MemberBlockItemListSyntax {
        Self.removingSemicolons(from: node, context: context, diagnose: false)
    }

    // Diagnose against the pre-traversal (still-attached) node so finding source locations are
    // accurate. The transform handles the rewrite only.
    static func willEnter(_ node: CodeBlockItemListSyntax, context: Context) {
        _ = Self.removingSemicolons(from: node, context: context, diagnose: true)
    }

    static func willEnter(_ node: MemberBlockItemListSyntax, context: Context) {
        _ = Self.removingSemicolons(from: node, context: context, diagnose: true)
    }

    /// Static counterpart of `nodeByRemovingSemicolons` for the compact pipeline. Children have
    /// already been visited by the combined rewriter, so no manual recursion is performed.
    fileprivate static func removingSemicolons<
        ItemType: SyntaxProtocol & WithSemicolonSyntax & Equatable,
        NodeType: SyntaxCollection
    >(
        from node: NodeType,
        context: Context,
        diagnose: Bool = true
    ) -> NodeType
        where NodeType.Element == ItemType
    {
        var newItems = Array(node)
        var pendingTrivia = Trivia()

        for (idx, item) in node.enumerated() {
            var newItem = item

            guard newItem != item || item.semicolon != nil || !pendingTrivia.isEmpty else {
                continue
            }

            if !pendingTrivia.isEmpty {
                newItem.leadingTrivia = pendingTrivia + newItem.leadingTrivia
            }
            pendingTrivia = []

            if let semicolon = item.semicolon,
               !(idx < node.count - 1
                   && Self.isCodeBlockItem(item, containingStmtType: DoStmtSyntax.self)
                   && Self.isCodeBlockItem(
                       newItems[idx + 1], containingStmtType: WhileStmtSyntax.self))
            {
                var hasNextStatement: Bool

                if let nextToken = semicolon.nextToken(viewMode: .sourceAccurate),
                   nextToken.tokenKind != .rightBrace,
                   nextToken.tokenKind != .endOfFile,
                   !nextToken.leadingTrivia.containsNewlines
                {
                    hasNextStatement = true
                    pendingTrivia = [.newlines(1)]

                    if diagnose {
                        Self.diagnose(.removeSemicolonAndMove, on: semicolon, context: context)
                    }
                } else {
                    hasNextStatement = false

                    if diagnose {
                        Self.diagnose(.removeSemicolon, on: semicolon, context: context)
                    }
                }

                let trailingTrivia = newItem.trailingTrivia
                newItem.semicolon = nil

                if trailingTrivia.hasLineComment || !hasNextStatement {
                    newItem.trailingTrivia = trailingTrivia
                } else {
                    pendingTrivia += trailingTrivia.withoutLeadingSpaces()
                }
            }
            newItems[idx] = newItem
        }

        return NodeType(newItems)
    }

    fileprivate static func isCodeBlockItem(
        _ node: some SyntaxProtocol,
        containingStmtType stmtType: StmtSyntaxProtocol.Type
    ) -> Bool {
        if let codeBlockItem = node.as(CodeBlockItemSyntax.self),
           case let .stmt(stmt) = codeBlockItem.item,
           stmt.is(stmtType)
        {
            return true
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let removeSemicolon: Finding.Message = "remove ';'"

    static let removeSemicolonAndMove: Finding.Message =
        "remove ';' and move the next statement to a new line"
}
