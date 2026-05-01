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

extension TokenStream {
    func visitClosureExpr(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        let newlineBehavior: NewlineBehavior
        newlineBehavior = forcedBreakingClosures.remove(node.id) != nil || node.statements.count > 1
            ? .soft
            : .elective

        if let signature = node.signature {
            after(node.leftBrace, tokens: .break(.open))

            if !node.statements.isEmpty {
                after(signature.inKeyword, tokens: .break(.same, newlines: newlineBehavior))
            } else {
                after(
                    signature.inKeyword,
                    tokens: .break(.same, size: 0, newlines: newlineBehavior)
                )
            }
            before(node.rightBrace, tokens: .break(.close))
        } else {
            // Closures without signatures can have their contents laid out identically to any other
            // braced structure. The leading reset is skipped because the layout depends on whether
            // it is a trailing closure of a function call (in which case that function call
            // supplies the reset) or part of some other expression (where we want that expression's
            // same/continue behavior to apply).
            arrangeBracesAndContents(
                of: node,
                contentsKeyPath: \.statements,
                shouldResetBeforeLeftBrace: false,
                openBraceNewlineBehavior: newlineBehavior
            )
        }
        return .visitChildren
    }

    func visitClosureShorthandParameter(
        _ node: ClosureShorthandParameterSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.trailingComma, tokens: .break(.same))
        return .visitChildren
    }

    func visitClosureSignature(_ node: ClosureSignatureSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        arrangeAttributeList(
            node.attributes,
            suppressFinalBreak: node.parameterClause == nil && node.capture == nil
        )

        if let parameterClause = node.parameterClause {
            // We unconditionally put a break before the `in` keyword below, so we should only put a
            // break after the capture list's right bracket if there are arguments following it or
            // we'll end up with an extra space if the line doesn't wrap.
            after(node.capture?.rightSquare, tokens: .break(.same))

            // When it's parenthesized, the parameterClause is a `ParameterClauseSyntax` .
            // Otherwise, it's a `ClosureParamListSyntax` . The parenthesized version is wrapped in
            // open/close breaks so that the parens create an extra level of indentation.
            if let closureParameterClause = parameterClause.as(ClosureParameterClauseSyntax.self) {
                // Whether we should prioritize keeping ") throws -> <return_type>" together. We can
                // only do this if the closure has arguments.
                let keepOutputTogether = !closureParameterClause.parameters.isEmpty
                    && config[KeepReturnTypeWithSignature.self]

                // Keep the output together by grouping from the right paren to the end of the
                // output.
                if keepOutputTogether {
                    // Due to visitation order, the matching .open break is added in
                    // ParameterClauseSyntax. Since the output clause is optional but the in-token
                    // is required, placing the .close before `inTok` ensures the close gets into
                    // the token stream.
                    before(node.inKeyword, tokens: .close)
                } else {
                    // Group outside of the parens, so that the argument list together, preferring
                    // to break between the argument list and the output.
                    before(parameterClause.firstToken(viewMode: .sourceAccurate), tokens: .open)
                    after(parameterClause.lastToken(viewMode: .sourceAccurate), tokens: .close)
                }

                arrangeClosureParameterClause(
                    closureParameterClause,
                    forcesBreakBeforeRightParen: true
                )
            } else {
                // Group around the arguments, but don't use open/close breaks because there are no
                // parens to create a new scope.
                before(
                    parameterClause.firstToken(viewMode: .sourceAccurate),
                    tokens: .open(argumentListConsistency())
                )
                after(parameterClause.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }
        }

        before(node.returnClause?.arrow, tokens: .break)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        before(node.inKeyword, tokens: .break(.same))
        return .visitChildren
    }

    func visitClosureCaptureClause(
        _ node: ClosureCaptureClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.leftSquare, tokens: .break(.open, size: 0), .open)
        before(node.rightSquare, tokens: .break(.close, size: 0), .close)
        return .visitChildren
    }

    func visitClosureCaptureList(_ node: ClosureCaptureListSyntax) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitClosureCapture(_ node: ClosureCaptureSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.specifier?.lastToken(viewMode: .sourceAccurate), tokens: .break)

        if let trailingComma = node.trailingComma {
            before(trailingComma, tokens: .close)
            after(trailingComma, tokens: .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitSubscriptCallExpr(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind {
        preVisitInsertingContextualBreaks(node)

        if let calledMemberAccessExpr = node.calledExpression.as(MemberAccessExprSyntax.self) {
            if let base = calledMemberAccessExpr.base, base.is(DeclReferenceExprSyntax.self) {
                before(base.firstToken(viewMode: .sourceAccurate), tokens: .open)
                after(
                    calledMemberAccessExpr.declName.baseName.lastToken(viewMode: .sourceAccurate),
                    tokens: .close
                )
            }
        }

        let arguments = node.arguments

        // If there is a trailing closure, force the right bracket down to the next line so it stays
        // with the open curly brace.
        let breakBeforeRightBracket = node.trailingClosure != nil
            || mustBreakBeforeClosingDelimiter(of: node, argumentListPath: \.arguments)

        before(
            node.trailingClosure?.leftBrace,
            tokens: .break(.same, newlines: .elective(ignoresDiscretionary: true))
        )

        arrangeFunctionCallArgumentList(
            arguments,
            leftDelimiter: node.leftSquare,
            rightDelimiter: node.rightSquare,
            forcesBreakBeforeRightDelimiter: breakBeforeRightBracket
        )

        return .visitChildren
    }

    func visitPostSubscriptCallExpr(_ node: SubscriptCallExprSyntax) {
        clearContextualBreakState(node)
    }

    func visitExpressionSegment(_ node: ExpressionSegmentSyntax) -> SyntaxVisitorContinueKind {
        // TODO: For now, just use the raw text of the node and don't try to format it deeper. In the
        // future, we should find a way to format the expression but without wrapping so that at least
        // internal whitespace is fixed.
        appendToken(.syntax(node.description))
        // Visiting children is not needed here.
        return .skipChildren
    }

    func visitMacroExpansionDecl(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BreakBetweenDeclAttributes.self]
        )

        before(
            node.trailingClosure?.leftBrace,
            tokens: .break(.same, newlines: .elective(ignoresDiscretionary: true))
        )

        arrangeFunctionCallArgumentList(
            node.arguments,
            leftDelimiter: node.leftParen,
            rightDelimiter: node.rightParen,
            forcesBreakBeforeRightDelimiter: false
        )
        return .visitChildren
    }

    func visitMacroExpansionExpr(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
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

    func visitClosureParameterClause(
        _ node: ClosureParameterClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        // Prioritize keeping ") throws -> <return_type>" together. We can only do this if the
        // function has arguments.
        if !node.parameters.isEmpty, config[KeepReturnTypeWithSignature.self] {
            before(node.rightParen, tokens: .open)
        }

        return .visitChildren
    }

    func visitEnumCaseParameterClause(
        _: EnumCaseParameterClauseSyntax
    ) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitEnumCaseParameterList(
        _ node: EnumCaseParameterListSyntax
    ) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitFunctionParameterClause(
        _ node: FunctionParameterClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        // Prioritize keeping ") throws -> <return_type>" together. We can only do this if the
        // function has arguments.
        if !node.parameters.isEmpty, config[KeepReturnTypeWithSignature.self] {
            before(node.rightParen, tokens: .open)
        }

        return .visitChildren
    }

    func visitFunctionParameterList(
        _ node: FunctionParameterListSyntax
    ) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitClosureParameter(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        arrangeAttributeList(node.attributes)
        before(
            node.secondName,
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )
        after(node.colon, tokens: .break)

        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitEnumCaseParameter(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        before(
            node.secondName,
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )
        after(node.colon, tokens: .break)

        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitFunctionParameter(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        arrangeAttributeList(node.attributes)
        before(
            node.secondName,
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )
        after(node.colon, tokens: .break)

        if let trailingComma = node.trailingComma {
            after(trailingComma, tokens: .close, .break(.same))
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitReturnClause(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
        if node.parent?.is(FunctionTypeSyntax.self) ?? false {
            // `FunctionTypeSyntax` used to not use `ReturnClauseSyntax` and had slightly different
            // formatting behavior than the normal `ReturnClauseSyntax` . To maintain the previous
            // formatting behavior, add a special case.
            before(node.arrow, tokens: .break)
            before(node.type.firstToken(viewMode: .sourceAccurate), tokens: .break)
        } else {
            after(node.arrow, tokens: .space)
        }

        // Member type identifier is used when the return type is a member of another type. Add a
        // group here so that the base, dot, and member type are kept together when they fit.
        if node.type.is(MemberTypeSyntax.self) {
            before(node.type.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(node.type.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }
}
