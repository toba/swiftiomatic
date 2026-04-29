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

import Foundation
import SwiftSyntax

/// Documentation comments must use the `///` form.
///
/// This is similar to `NoBlockComments` but is meant to prevent documentation block comments.
///
/// Lint: If a doc block comment appears, a lint error is raised.
///
/// Rewrite: If a doc block comment appears on its own on a line, or if a doc block comment spans
///         multiple lines without appearing on the same line as code, it will be replaced with
///         multiple doc line comments.
final class TripleSlashDocComments: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .comments }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: EnumDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: DeinitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: ClassDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: VariableDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: StructDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: ProtocolDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: TypeAliasDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    static func transform(
        _ node: ExtensionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        convertDocBlockCommentToDocLineComment(DeclSyntax(node), context: context)
    }

    /// If the declaration has a doc block comment, return the declaration with the comment rewritten
    /// as a line comment.
    ///
    /// If the declaration had no comment or had only line comments, it is returned unchanged.
    private static func convertDocBlockCommentToDocLineComment(
        _ decl: DeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard
            let commentInfo = DocumentationCommentText(extractedFrom: decl.leadingTrivia),
            commentInfo.introducer != .line
        else {
            return decl
        }

        Self.diagnose(
            .avoidDocBlockComment,
            on: decl,
            context: context,
            anchor: .leadingTrivia(commentInfo.startIndex)
        )

        // Keep any trivia leading up to the doc comment.
        var pieces = Array(decl.leadingTrivia[..<commentInfo.startIndex])

        // If the comment text ends with a newline, remove it so that we don't end up with an extra
        // blank line after splitting.
        var text = commentInfo.text[...]

        if text.hasSuffix("\n") { text = text.dropLast(1) }

        // Append each line of the doc comment with `///` prefixes.
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            var newLine = "///"

            if !line.isEmpty { newLine.append(" \(line)") }
            pieces.append(.docLineComment(newLine))
            pieces.append(.newlines(1))
        }

        var decl = decl
        decl.leadingTrivia = Trivia(pieces: pieces)
        return decl
    }
}

extension Finding.Message {
    fileprivate static let avoidDocBlockComment: Finding.Message =
        "replace documentation block comments with documentation line comments"
}
