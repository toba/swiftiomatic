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
    func visitDeclNameArguments(_ node: DeclNameArgumentsSyntax) -> SyntaxVisitorContinueKind {
        after(node.leftParen, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
        before(node.rightParen, tokens: .break(.close(mustBreak: false), size: 0), .close)
        insertTokens(.break(.same, size: 0), betweenElementsOf: node.arguments)
        return .visitChildren
    }

    func visitTupleExpr(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
        // We'll do nothing if it's a zero-element tuple, because we just want to keep the empty `()`
        // together.
        let elementCount = node.elements.count

        if elementCount == 1 {
            // A tuple with one element is a parenthesized expression; add a group around it to keep it
            // together when possible, but breaks are handled elsewhere (see calls to
            // `stackedIndentationBehavior`).
            after(node.leftParen, tokens: .open)
            before(node.rightParen, tokens: .close)
            closingDelimiterTokens.insert(node.rightParen)

            // When there's a comment inside of a parenthesized expression, we want to allow the comment
            // to exist at the EOL with the left paren or on its own line. The contents are always
            // indented on the following lines, since parens always create a scope. An open/close break
            // pair isn't used here to avoid forcing the closing paren down onto a new line.
            if node.leftParen.nextToken(viewMode: .all)?.hasPrecedingLineComment ?? false {
                after(node.leftParen, tokens: .break(.continue, size: 0))
            }
        } else if elementCount > 1 {
            // Tuples with more than one element are "true" tuples, and should indent as block structures.
            after(node.leftParen, tokens: .break(.open, size: 0), .open)
            before(node.rightParen, tokens: .break(.close, size: 0), .close)

            insertTokens(.break(.same), betweenElementsOf: node.elements)

            for element in node.elements {
                arrangeAsTupleExprElement(element)
            }
        }

        return .visitChildren
    }

    func visitLabeledExprList(_ node: LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitLabeledExpr(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        // Intentionally do nothing here. Since `TupleExprElement`s are used both in tuple expressions
        // and function argument lists, which need to be formatted, differently, those nodes manually
        // loop over the nodes and arrange them in those contexts.
        return .visitChildren
    }

    /// Arranges the given tuple expression element as a tuple element (rather than a function call
    /// argument).
    ///
    /// - Parameter node: The tuple expression element to be arranged.
    func arrangeAsTupleExprElement(_ node: LabeledExprSyntax) {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.colon, tokens: .break)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        if let trailingComma = node.trailingComma {
            closingDelimiterTokens.insert(trailingComma)
        }
    }

    func visitArrayExpr(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        if !node.elements.isEmpty || node.rightSquare.hasAnyPrecedingComment {
            after(node.leftSquare, tokens: .break(.open, size: 0), .open)
            before(node.rightSquare, tokens: .break(.close, size: 0), .close)
        }
        return .visitChildren
    }

    func visitArrayElementList(_ node: ArrayElementListSyntax) -> SyntaxVisitorContinueKind {
        insertTokens(.break(.same), betweenElementsOf: node)

        for element in node {
            before(element.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(element.lastToken(viewMode: .sourceAccurate), tokens: .close)
            if let trailingComma = element.trailingComma {
                closingDelimiterTokens.insert(trailingComma)
            }
        }

        markCommaDelimitedRegion(node, isCollectionLiteral: true)
        return .visitChildren
    }

    func visitArrayElement(_ node: ArrayElementSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitDictionaryExpr(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
        // The node's content is either a `DictionaryElementListSyntax` or a `TokenSyntax` for a colon
        // token (for an empty dictionary).
        if !(node.content.as(DictionaryElementListSyntax.self)?.isEmpty ?? true)
            || node.content.hasAnyPrecedingComment
            || node.rightSquare.hasAnyPrecedingComment
        {
            after(node.leftSquare, tokens: .break(.open, size: 0), .open)
            before(node.rightSquare, tokens: .break(.close, size: 0), .close)
        }
        return .visitChildren
    }

    func visitDictionaryElementList(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
        insertTokens(.break(.same), betweenElementsOf: node)

        for element in node {
            before(element.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(element.colon, tokens: .break)
            after(element.lastToken(viewMode: .sourceAccurate), tokens: .close)
            if let trailingComma = element.trailingComma {
                closingDelimiterTokens.insert(trailingComma)
            }
        }

        markCommaDelimitedRegion(node, isCollectionLiteral: true)
        return .visitChildren
    }

    func visitDictionaryType(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .break)
        return .visitChildren
    }

    func visitDictionaryElement(_ node: DictionaryElementSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitMemberAccessExpr(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        preVisitInsertingContextualBreaks(node)
        return .visitChildren
    }

    func visitPostMemberAccessExpr(_ node: MemberAccessExprSyntax) {
        clearContextualBreakState(node)
    }

    func visitPostfixIfConfigExpr(_ node: PostfixIfConfigExprSyntax) -> SyntaxVisitorContinueKind {
        preVisitInsertingContextualBreaks(node)
        return .visitChildren
    }

    func visitPostPostfixIfConfigExpr(_ node: PostfixIfConfigExprSyntax) {
        clearContextualBreakState(node)
    }

    func visitFunctionCallExpr(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        preVisitInsertingContextualBreaks(node)

        // If there are multiple trailing closures, force all the closures in the call to break.
        if !node.additionalTrailingClosures.isEmpty {
            if let closure = node.trailingClosure {
                forcedBreakingClosures.insert(closure.id)
            }
            for additionalTrailingClosure in node.additionalTrailingClosures {
                forcedBreakingClosures.insert(additionalTrailingClosure.closure.id)
            }
        }

        if let calledMemberAccessExpr = node.calledExpression.as(MemberAccessExprSyntax.self) {
            if let base = calledMemberAccessExpr.base, base.is(DeclReferenceExprSyntax.self) {
                // When this function call is wrapped by a keyword-modified expression, the group applied
                // when visiting that wrapping expression is sufficient. Adding another group here in that
                // case can result in unnecessarily breaking after the modifier keyword.
                if !(base.firstToken(viewMode: .sourceAccurate)?.previousToken(viewMode: .all)?
                    .parent?.isProtocol(
                        KeywordModifiedExprSyntax.self
                    ) ?? false)
                {
                    before(base.firstToken(viewMode: .sourceAccurate), tokens: .open)
                    after(
                        calledMemberAccessExpr.declName.baseName.lastToken(
                            viewMode: .sourceAccurate
                        ),
                        tokens: .close
                    )
                }
            }
        }

        let arguments = node.arguments

        // If there is a trailing closure, force the right parenthesis down to the next line so it
        // stays with the open curly brace.
        let breakBeforeRightParen =
            (node.trailingClosure != nil && !isCompactSingleFunctionCallArgument(arguments))
            || mustBreakBeforeClosingDelimiter(of: node, argumentListPath: \.arguments)

        before(
            node.trailingClosure?.leftBrace,
            tokens: .break(.same, newlines: .elective(ignoresDiscretionary: true))
        )

        arrangeFunctionCallArgumentList(
            arguments,
            leftDelimiter: node.leftParen,
            rightDelimiter: node.rightParen,
            forcesBreakBeforeRightDelimiter: breakBeforeRightParen
        )

        return .visitChildren
    }

    func visitPostFunctionCallExpr(_ node: FunctionCallExprSyntax) {
        clearContextualBreakState(node)
    }

    func visitMultipleTrailingClosureElement(
        _ node: MultipleTrailingClosureElementSyntax
    ) -> SyntaxVisitorContinueKind {
        before(node.label, tokens: .space)
        after(node.colon, tokens: .space)
        return .visitChildren
    }

    /// Arrange the given argument list (or equivalently, tuple expression list) as a list of function
    /// arguments.
    ///
    /// - Parameters:
    ///   - arguments: The argument list/tuple expression list to arrange.
    ///   - leftDelimiter: The left parenthesis or bracket surrounding the arguments, if any.
    ///   - rightDelimiter: The right parenthesis or bracket surrounding the arguments, if any.
    ///   - forcesBreakBeforeRightDelimiter: True if a line break should be forced before the right
    ///     right delimiter if a line break occurred after the left delimiter, or false if the right
    ///     delimiter is allowed to hang on the same line as the final argument. # ignore-unacceptable-language
    func arrangeFunctionCallArgumentList(
        _ arguments: LabeledExprListSyntax,
        leftDelimiter: TokenSyntax?,
        rightDelimiter: TokenSyntax?,
        forcesBreakBeforeRightDelimiter: Bool
    ) {
        if !arguments.isEmpty {
            var afterLeftDelimiter: [Token] = [.break(.open, size: 0)]
            var beforeRightDelimiter: [Token] = [
                .break(.close(mustBreak: forcesBreakBeforeRightDelimiter), size: 0)
            ]

            if shouldGroupAroundArgumentList(arguments) {
                afterLeftDelimiter.append(.open(argumentListConsistency()))
                beforeRightDelimiter.append(.close)
            }

            after(leftDelimiter, tokens: afterLeftDelimiter)
            before(rightDelimiter, tokens: beforeRightDelimiter)
        }

        let shouldGroupAroundArgument = !isCompactSingleFunctionCallArgument(arguments)
        for argument in arguments {
            if let trailingComma = argument.trailingComma {
                closingDelimiterTokens.insert(trailingComma)
            }
            arrangeAsFunctionCallArgument(argument, shouldGroup: shouldGroupAroundArgument)
        }
    }

    /// Arranges the given tuple expression element as a function call argument.
    ///
    /// - Parameters:
    ///   - node: The tuple expression element.
    ///   - shouldGroup: If true, group around the argument to prefer keeping it together if possible.
    func arrangeAsFunctionCallArgument(
        _ node: LabeledExprSyntax,
        shouldGroup: Bool
    ) {
        if shouldGroup {
            before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        }

        var additionalEndTokens = [Token]()
        if let colon = node.colon {
            // If we have an open delimiter following the colon, use a space instead of a continuation
            // break so that we don't awkwardly shift the delimiter down and indent it further if it
            // wraps.
            var tokensAfterColon: [Token] = [
                startsWithOpenDelimiter(Syntax(node.expression)) ? .space : .break
            ]

            if leftmostMultilineStringLiteral(of: node.expression) != nil {
                tokensAfterColon.append(.break(.open(kind: .block), size: 0))
                additionalEndTokens = [.break(.close(mustBreak: false), size: 0)]
            }

            after(colon, tokens: tokensAfterColon)
        }

        if let trailingComma = node.trailingComma {
            before(trailingComma, tokens: additionalEndTokens)
            var afterTrailingComma: [Token] = [.break(.same)]
            if shouldGroup {
                afterTrailingComma.insert(.close, at: 0)
            }
            after(trailingComma, tokens: afterTrailingComma)
        } else if shouldGroup {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: additionalEndTokens + [.close])
        }
    }
}
