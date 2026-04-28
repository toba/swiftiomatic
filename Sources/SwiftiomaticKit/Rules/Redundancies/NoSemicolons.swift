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
final class NoSemicolons: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Creates a new version of the given node which doesn't contain any semicolons.
    ///
    /// In the static-transform model, child items have already been recursed by the combined
    /// rewriter (or by `super.visit` in the legacy delegator). We just process each item
    /// in-place, removing semicolons and re-flowing trivia where needed.
    private static func nodeByRemovingSemicolons<
        ItemType: SyntaxProtocol & WithSemicolonSyntax & Equatable,
        NodeType: SyntaxCollection
    >(from node: NodeType, context: Context) -> NodeType where NodeType.Element == ItemType {
        var newItems = Array(node)

        // Keeps track of trailing trivia after a semicolon when it needs to be moved to precede the
        // next statement.
        var pendingTrivia = Trivia()

        for (idx, item) in node.enumerated() {
            // Children have already been recursed; the item is the post-recursion view.
            var newItem = item

            // Check if we need to make any modifications (removing semicolon/adding newlines).
            guard item.semicolon != nil || !pendingTrivia.isEmpty else { continue }

            // Check if the leading trivia for this statement needs a new line.
            if !pendingTrivia.isEmpty {
                newItem.leadingTrivia = pendingTrivia + newItem.leadingTrivia
            }
            pendingTrivia = []

            // If there's a semicolon, diagnose and remove it. Exception: Do not remove the
            // semicolon if it is separating a `do` statement from a `while` statement.
            if let semicolon = item.semicolon,
               !(idx < node.count - 1
                   && isCodeBlockItem(item, containingStmtType: DoStmtSyntax.self)
                   && isCodeBlockItem(newItems[idx + 1], containingStmtType: WhileStmtSyntax.self))
            {
                // When emitting the finding, tell the user to move the next statement down if there
                // is another statement following this one. Otherwise, just tell them to remove the
                // semicolon.
                var hasNextStatement: Bool

                if let nextToken = semicolon.nextToken(viewMode: .sourceAccurate),
                   nextToken.tokenKind != .rightBrace, nextToken.tokenKind != .endOfFile,
                   !nextToken.leadingTrivia.containsNewlines
                {
                    hasNextStatement = true
                    pendingTrivia = [.newlines(1)]
                    Self.diagnose(.removeSemicolonAndMove, on: semicolon, context: context)
                } else {
                    hasNextStatement = false
                    Self.diagnose(.removeSemicolon, on: semicolon, context: context)
                }

                // We treat block comments after the semicolon slightly differently from end-of-line
                // comments. Assume that an end-of-line comment should stay on the same line when a
                // semicolon is removed, but if we have something like `f(); /* blah */ g()` ,
                // assume that the comment is meant to be associated with `g()` (because it's not
                // separated from that statement).
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

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: CodeBlockItemListSyntax,
        parent: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        nodeByRemovingSemicolons(from: node, context: context)
    }

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: MemberBlockItemListSyntax,
        parent: Syntax?,
        context: Context
    ) -> MemberBlockItemListSyntax {
        nodeByRemovingSemicolons(from: node, context: context)
    }

    /// Returns true if the given syntax node is a `CodeBlockItem` containing a statement node of
    /// the given type.
    private static func isCodeBlockItem(
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
