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

extension FunctionDeclSyntax {
    /// Constructs a name for a function that includes parameter labels, i.e. `foo(_:bar:)` .
    var fullDeclName: String {
        let params = signature.parameterClause.parameters.map { param in
            "\(param.firstName.text):"
        }
        return "\(name.text)(\(params.joined()))"
    }

    /// Returns a copy with a `throws` clause added to the function signature.
    ///
    /// If the function already has effect specifiers (e.g. `async` ), `throws` is appended.
    /// Otherwise, new effect specifiers are created. Leading trivia from the body's `{` is
    /// transferred to the `throws` keyword, and the brace gets a single space.
    ///
    /// Does nothing if the function already throws or has no body.
    func addingThrowsClause() -> FunctionDeclSyntax {
        guard signature.effectSpecifiers?.throwsClause == nil else { return self }

        var result = self
        let throwsClause = ThrowsClauseSyntax(
            throwsSpecifier: .keyword(
                .throws,
                trailingTrivia: []
            ))

        if var effectSpecifiers = result.signature.effectSpecifiers {
            // Has async but no throws — insert throws after async, transfer body's leading trivia.
            if var body = result.body {
                var tc = throwsClause
                tc.throwsSpecifier.leadingTrivia = body.leftBrace.leadingTrivia
                body.leftBrace.leadingTrivia = .space
                effectSpecifiers.throwsClause = tc
                result.signature.effectSpecifiers = effectSpecifiers
                result.body = body
            }
        } else {
            // No effect specifiers — add them, transfer body's leading trivia to throws.
            result.signature.effectSpecifiers = FunctionEffectSpecifiersSyntax(
                throwsClause: throwsClause
            )

            if var body = result.body {
                let bodyTrivia = body.leftBrace.leadingTrivia
                result.signature.effectSpecifiers!.throwsClause!.throwsSpecifier.leadingTrivia =
                    bodyTrivia
                body.leftBrace.leadingTrivia = .space
                result.body = body
            }
        }
        return result
    }
}
