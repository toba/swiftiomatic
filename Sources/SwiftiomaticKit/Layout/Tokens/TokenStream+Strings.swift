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
    func visitStringLiteralExpr(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        if node.openingQuote.tokenKind == .multilineStringQuote {
            // Looks up the correct break kind based on prior context.
            let breakKind = pendingMultilineStringBreakKinds[node, default: .same]
            after(node.openingQuote, tokens: .break(breakKind, size: 0, newlines: .hard(count: 1)))
            if !node.segments.isEmpty {
                before(node.closingQuote, tokens: .break(breakKind, newlines: .hard(count: 1)))
            }
            if shouldFormatterIgnore(node: Syntax(node)) {
                appendFormatterIgnored(node: Syntax(node))
                // Mirror the tokens we'd normally append on '"""'
                appendTrailingTrivia(node.closingQuote)
                appendAfterTokensAndTrailingComments(node.closingQuote)
                return .skipChildren
            }
        }
        return .visitChildren
    }

    func visitSimpleStringLiteralExpr(_ node: SimpleStringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        if node.openingQuote.tokenKind == .multilineStringQuote {
            after(node.openingQuote, tokens: .break(.same, size: 0, newlines: .hard(count: 1)))
            if !node.segments.isEmpty {
                before(node.closingQuote, tokens: .break(.same, newlines: .hard(count: 1)))
            }
        }
        return .visitChildren
    }

}
