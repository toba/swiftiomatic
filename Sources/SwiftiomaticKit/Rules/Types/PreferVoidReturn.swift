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

/// Return `Void`, not `()`, in signatures.
///
/// Note that this rule does *not* apply to function declaration signatures in order to avoid
/// conflicting with `NoVoidReturnOnFunctionSignature`.
///
/// Lint: Returning `()` in a signature yields a lint error.
///
/// Rewrite: `-> ()` is replaced with `-> Void`
final class PreferVoidReturn: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    // MARK: - Compact pipeline (willEnter diagnoses on the pre-traversal node so
    // finding source locations come from the original tree, not the post-rewrite
    // detached subtree). The applyTo overloads below only perform the rewrite —
    // they no longer diagnose.

    static func willEnter(_ node: FunctionTypeSyntax, context: Context) {
        guard let returnType = node.returnClause.type.as(TupleTypeSyntax.self),
            returnType.elements.isEmpty
        else { return }
        Self.diagnose(.returnVoid, on: returnType, context: context)
    }

    static func willEnter(_ node: ClosureSignatureSyntax, context: Context) {
        guard let returnClause = node.returnClause,
            let returnType = returnClause.type.as(TupleTypeSyntax.self),
            returnType.elements.isEmpty
        else { return }
        Self.diagnose(.returnVoid, on: returnType, context: context)
    }

    /// Replace `-> ()` with `-> Void` on a function-type signature.
    static func apply(_ node: FunctionTypeSyntax, context: Context) -> FunctionTypeSyntax {
        guard let returnType = node.returnClause.type.as(TupleTypeSyntax.self),
              returnType.elements.isEmpty
        else { return node }

        if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
            || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading)
        {
            return node
        }

        let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
        var rewritten = node
        rewritten.returnClause.type = TypeSyntax(voidKeyword)
        return rewritten
    }

    /// Replace `-> ()` with `-> Void` on a closure signature.
    static func apply(_ node: ClosureSignatureSyntax, context: Context) -> ClosureSignatureSyntax {
        guard let returnClause = node.returnClause,
              let returnType = returnClause.type.as(TupleTypeSyntax.self),
              returnType.elements.isEmpty
        else { return node }

        if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
            || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading)
        {
            return node
        }

        let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
        var newReturnClause = returnClause
        newReturnClause.type = TypeSyntax(voidKeyword)

        var result = node
        result.returnClause = newReturnClause
        return result
    }

    private static func hasNonWhitespaceTrivia(
        _ token: TokenSyntax,
        at position: TriviaPosition
    ) -> Bool {
        for piece in position == .leading ? token.leadingTrivia : token.trailingTrivia {
            switch piece {
                case .blockComment, .docBlockComment, .docLineComment, .unexpectedText, .lineComment:
                    return true
                default: break
            }
        }
        return false
    }

    private static func makeVoidIdentifierType(
        toReplace node: TupleTypeSyntax
    ) -> IdentifierTypeSyntax {
        IdentifierTypeSyntax(
            name: TokenSyntax.identifier(
                "Void",
                leadingTrivia: node.firstToken(viewMode: .sourceAccurate)?.leadingTrivia ?? [],
                trailingTrivia: node.lastToken(viewMode: .sourceAccurate)?.trailingTrivia ?? []
            ),
            genericArgumentClause: nil
        )
    }
}

extension Finding.Message {
    fileprivate static let returnVoid: Finding.Message = "replace '()' with 'Void'"
}
