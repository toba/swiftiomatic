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
    func visitGenericParameterClause(
        _ node: GenericParameterClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.leftAngle, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
        before(node.rightAngle, tokens: .break(.close, size: 0), .close)
        return .visitChildren
    }

    func visitGenericParameterList(
        _ node: GenericParameterListSyntax
    ) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitPrimaryAssociatedTypeClause(
        _ node: PrimaryAssociatedTypeClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.leftAngle, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
        before(node.rightAngle, tokens: .break(.close, size: 0), .close)
        return .visitChildren
    }

    func visitArrayType(_: ArrayTypeSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitInlineArrayType(_ node: InlineArrayTypeSyntax) -> SyntaxVisitorContinueKind {
        after(node.leftSquare, tokens: .break(.open, size: 0), .open)
        before(node.separator, tokens: .space)
        after(node.separator, tokens: .break)
        before(node.rightSquare, tokens: .break(.close, size: 0), .close)
        return .visitChildren
    }

    func visitTupleType(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
        arrangeBlockBreaks(left: node.leftParen, right: node.rightParen)
        return .visitChildren
    }

    func visitTupleTypeElementList(
        _ node: TupleTypeElementListSyntax
    ) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitTupleTypeElement(_ node: TupleTypeElementSyntax) -> SyntaxVisitorContinueKind {
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

    func visitFunctionType(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        arrangeBlockBreaks(left: node.leftParen, right: node.rightParen)
        return .visitChildren
    }

    func visitGenericArgumentClause(
        _ node: GenericArgumentClauseSyntax
    ) -> SyntaxVisitorContinueKind {
        // Generic argument clauses ignore source-driven newlines: a wrapped `<...>` in source
        // should collapse back to one line when the inlined form fits, instead of being preserved
        // by `RespectExistingLineBreaks` .
        //
        // When the only generic argument is a type that brings its own paren/brace delimiters
        // (currently: tuple types), the inner break around `<` and `>` is suppressed so the angle
        // brackets stay glued to that inner type's opening / closing delimiter. The inner type
        // wraps via its own `(` / `)` mechanism — matching the idiomatic source layout
        // `Regex<(\n  ...\n)>` instead of producing a four-line `Regex<\n  (\n    ...\n  )\n>`.
        //
        // When the only generic argument is a type that brings its own paren / brace delimiters
        // (currently: tuple types), the inner break around `<` and `>` is suppressed so the angle
        // brackets stay glued to that inner type's opening / closing delimiter. The inner type
        // wraps via its own `(` / `)` mechanism — matching the idiomatic source layout
        // `Regex<(\n  ...\n)>` instead of producing a four-line `Regex<\n  (\n    ...\n  )\n>` .
        let glueAngleToInnerDelimiter: Bool = {
            guard node.arguments.count == 1,
                  let onlyArg = node.arguments.first,
                  case let .type(innerType) = onlyArg.argument
            else { return false }
            return innerType.is(TupleTypeSyntax.self)
        }()

        if glueAngleToInnerDelimiter {
            after(node.leftAngle, tokens: .open)
            before(node.rightAngle, tokens: .close)
        } else {
            after(
                node.leftAngle,
                tokens: .break(.open, size: 0, newlines: .elective(ignoresDiscretionary: true)),
                .open
            )
            before(
                node.rightAngle,
                tokens: .break(.close, size: 0, newlines: .elective(ignoresDiscretionary: true)),
                .close
            )
        }
        return .visitChildren
    }

    func visitTuplePattern(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind {
        arrangeBlockBreaks(left: node.leftParen, right: node.rightParen)
        return .visitChildren
    }

    func visitTuplePatternElementList(
        _ node: TuplePatternElementListSyntax
    ) -> SyntaxVisitorContinueKind {
        markCommaDelimitedRegion(node, isCollectionLiteral: false)
        return .visitChildren
    }

    func visitTryExpr(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
        before(
            node.expression.firstToken(viewMode: .sourceAccurate),
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )

        // Check for an anchor token inside of the expression to end a group starting with the `try`
        // keyword.
        if !(node.parent?.isProtocol(KeywordModifiedExprSyntax.self) ?? false),
           let anchorToken = connectingTokenForKeywordModifiedExpr(inSubExpr: node.expression)
        {
            before(node.tryKeyword, tokens: .open)
            after(anchorToken, tokens: .close)
        }

        return .visitChildren
    }

    func visitAwaitExpr(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
        before(
            node.expression.firstToken(viewMode: .sourceAccurate),
            tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true))
        )

        // Check for an anchor token inside of the expression to end a group starting with the
        // `await` keyword.
        if !(node.parent?.isProtocol(KeywordModifiedExprSyntax.self) ?? false),
           let anchorToken = connectingTokenForKeywordModifiedExpr(inSubExpr: node.expression)
        {
            before(node.awaitKeyword, tokens: .open)
            after(anchorToken, tokens: .close)
        }

        return .visitChildren
    }

    func visitUnsafeExpr(_ node: UnsafeExprSyntax) -> SyntaxVisitorContinueKind {
        // Unlike `try` and `await` , `unsafe` is a contextual keyword that may not be separated
        // from the following token by a line break. Keep them glued together with `.space` .
        before(node.expression.firstToken(viewMode: .sourceAccurate), tokens: .space)

        // Check for an anchor token inside of the expression to end a group starting with the
        // `unsafe` keyword.
        if !(node.parent?.isProtocol(KeywordModifiedExprSyntax.self) ?? false),
           let anchorToken = connectingTokenForKeywordModifiedExpr(inSubExpr: node.expression)
        {
            before(node.unsafeKeyword, tokens: .open)
            after(anchorToken, tokens: .close)
        }

        return .visitChildren
    }

    /// Searches within a subexpression of a keyword-modified expression to find the last token in a
    /// range that should be grouped with the leading keyword modifier.
    ///
    /// - Parameter expr: An expression that is wrapped by a keyword-modified expression.
    /// - Returns: The token that should end the group that is started by the modifier keyword, or
    ///   nil if there should be no group.
    func connectingTokenForKeywordModifiedExpr(inSubExpr expr: ExprSyntax) -> TokenSyntax? {
        if let modifiedExpr = expr.asProtocol(KeywordModifiedExprSyntax.self) {
            // If we were called from a keyword-modified expression like `try` , `await` , or
            // `unsafe` , recursively drill into the child expression.
            return connectingTokenForKeywordModifiedExpr(inSubExpr: modifiedExpr.expression)
        }
        if let callingExpr = expr.asProtocol(CallingExprSyntax.self) {
            return connectingTokenForKeywordModifiedExpr(inSubExpr: callingExpr.calledExpression)
        }
        if let memberAccessExpr = expr.as(MemberAccessExprSyntax.self),
           let base = memberAccessExpr.base
        {
            // When there's a simple base (i.e. identifier), group the entire
            // `try/await <base>.<name>` sequence. This check has to happen here so that the
            // `MemberAccessExprSyntax.name` is available.
            //
            // Exception: when the head of the chain participates in a multi-step chain (its
            // FunctionCall parent is the base of an outer `MemberAccessExpr` ), end the group after
            // `base` (e.g. `try Citation` ) instead of after `<name>` (e.g. `try Citation.join` ).
            // The .close needs to land BEFORE the first contextual chain break so that, when
            // discretionary newlines in the source make that break `.soft(discretionary:)` , the
            // keyword-modifier group has already closed and the soft break's
            // `total += maxLineLength` bump doesn't inflate the chunk-length of an outer `=` (or
            // `guard` ) break.
            if base.is(DeclReferenceExprSyntax.self) {
                if let headCall = memberAccessExpr.parent?.as(FunctionCallExprSyntax.self),
                   headCall.calledExpression.id == memberAccessExpr.id,
                   shouldRetargetChainHeadCloseForAssignmentRHS(headCall)
                {
                    return base.lastToken(viewMode: .sourceAccurate)
                }
                return memberAccessExpr.declName.baseName.lastToken(viewMode: .sourceAccurate)
            }
            return connectingTokenForKeywordModifiedExpr(inSubExpr: base)
        }
        return expr.is(DeclReferenceExprSyntax.self)
            ? expr.lastToken(viewMode: .sourceAccurate)
            : nil
    }

    func visitTypeExpr(_: TypeExprSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitAttribute(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        switch node.arguments {
            case .argumentList(let argumentList)?:
                if let leftParen = node.leftParen, let rightParen = node.rightParen {
                    arrangeFunctionCallArgumentList(
                        argumentList,
                        leftDelimiter: leftParen,
                        rightDelimiter: rightParen,
                        forcesBreakBeforeRightDelimiter: false
                    )
                }
            case .some:
                // Wrap the attribute's arguments in their own group, so arguments stay together
                // with a higher affinity than the overall attribute (e.g. allows a break after the
                // opening "(" and then having the entire argument list on 1 line). Necessary spaces
                // and breaks are added inside of the argument, using type specific visitor methods.
                after(
                    node.leftParen, tokens: .break(.open, size: 0), .open(argumentListConsistency())
                )
                before(node.rightParen, tokens: .break(.close, size: 0), .close)
            case nil: break
        }
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitAvailabilityArgumentList(
        _ node: AvailabilityArgumentListSyntax
    ) -> SyntaxVisitorContinueKind {
        insertTokens(.break(.same, size: 1), betweenElementsOf: node)
        return .visitChildren
    }

    func visitOriginallyDefinedInAttributeArguments(
        _ node: OriginallyDefinedInAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.colon.lastToken(viewMode: .sourceAccurate), tokens: .break(.same, size: 1))
        after(node.comma.lastToken(viewMode: .sourceAccurate), tokens: .break(.same, size: 1))
        return .visitChildren
    }

    func visitDocumentationAttributeArgument(
        _ node: DocumentationAttributeArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .break(.same, size: 1))
        return .visitChildren
    }

    func visitAvailabilityLabeledArgument(
        _ node: AvailabilityLabeledArgumentSyntax
    ) -> SyntaxVisitorContinueKind {
        before(node.label, tokens: .open)

        let tokensAfterColon: [Token]
        let endTokens: [Token]

        if case let .string(string) = node.value,
           string.openingQuote.tokenKind == .multilineStringQuote
        {
            tokensAfterColon = [
                .break(.open(kind: .block), newlines: .elective(ignoresDiscretionary: true))
            ]
            endTokens = [.break(.close(mustBreak: false), size: 0), .close]
        } else {
            tokensAfterColon = [.break(.continue, newlines: .elective(ignoresDiscretionary: true))]
            endTokens = [.close]
        }

        after(node.colon, tokens: tokensAfterColon)
        after(node.value.lastToken(viewMode: .sourceAccurate), tokens: endTokens)
        return .visitChildren
    }

    func visitPlatformVersionItemList(
        _ node: PlatformVersionItemListSyntax
    ) -> SyntaxVisitorContinueKind {
        insertTokens(.break(.same, size: 1), betweenElementsOf: node)
        return .visitChildren
    }

    func visitPlatformVersion(_ node: PlatformVersionSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.platform, tokens: .break(.continue, size: 1))
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitBackDeployedAttributeArguments(
        _ node: BackDeployedAttributeArgumentsSyntax
    ) -> SyntaxVisitorContinueKind {
        before(
            node.platforms.firstToken(viewMode: .sourceAccurate),
            tokens: .break(.open, size: 1),
            .open(argumentListConsistency())
        )
        after(
            node.platforms.lastToken(viewMode: .sourceAccurate),
            tokens: .break(.close, size: 0),
            .close
        )
        return .visitChildren
    }

    func visitConditionElement(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        if let comma = node.trailingComma {
            after(comma, tokens: .close, .break(.same))
            closingDelimiterTokens.insert(comma)
        } else {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        return .visitChildren
    }

    func visitInOutExpr(_: InOutExprSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitImportDecl(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        // Import declarations should never be wrapped.
        before(
            node.firstToken(viewMode: .sourceAccurate),
            tokens: .printerControl(kind: .disableBreaking(allowDiscretionary: false))
        )

        arrangeAttributeList(node.attributes)
        after(node.importKeyword, tokens: .space)
        after(node.importKindSpecifier, tokens: .space)

        after(
            node.lastToken(viewMode: .sourceAccurate),
            tokens: .printerControl(kind: .enableBreaking)
        )
        return .visitChildren
    }

    func visitKeyPathExpr(_ node: KeyPathExprSyntax) -> SyntaxVisitorContinueKind {
        before(node.backslash, tokens: .open)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitKeyPathComponent(_ node: KeyPathComponentSyntax) -> SyntaxVisitorContinueKind {
        // If this is the first component (immediately after the backslash), allow a break after the
        // slash only if a typename follows it. Do not break in the middle of `\.` .
        var breakBeforePeriod = true

        if let keyPathComponents = node.parent?.as(KeyPathComponentListSyntax.self),
           let keyPathExpr = keyPathComponents.parent?.as(KeyPathExprSyntax.self),
           node == keyPathExpr.components.first,
           keyPathExpr.root == nil { breakBeforePeriod = false }
        if breakBeforePeriod { before(node.period, tokens: .break(.continue, size: 0)) }
        return .visitChildren
    }

    func visitKeyPathSubscriptComponent(
        _ node: KeyPathSubscriptComponentSyntax
    ) -> SyntaxVisitorContinueKind {
        var breakBeforeRightParen = !isCompactSingleFunctionCallArgument(node.arguments)

        if let component = node.parent?.as(KeyPathComponentSyntax.self) {
            breakBeforeRightParen = !isLastKeyPathComponent(component)
        }

        arrangeFunctionCallArgumentList(
            node.arguments,
            leftDelimiter: node.leftSquare,
            rightDelimiter: node.rightSquare,
            forcesBreakBeforeRightDelimiter: breakBeforeRightParen
        )
        return .visitChildren
    }

    /// Returns a value indicating whether the given key path component was the last component in
    /// the list containing it.
    func isLastKeyPathComponent(_ component: KeyPathComponentSyntax) -> Bool {
        guard let componentList = component.parent?.as(KeyPathComponentListSyntax.self),
              let lastComponent = componentList.last
        else { return false }
        return component == lastComponent
    }

    func visitTernaryExpr(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        // Wrapping decisions for ternaries belong to the WrapTernaryBranches format rule, which
        // inserts discretionary newlines into the leading trivia of `?` and `:` when the expression
        // would overflow the configured line length. The pretty printer only emits the
        // operator-relative breaks here. Using
        // `.break(.open(kind: .continuation)) ... .break(.close)` pairs lets the wrapped branches
        // push a continuation indent so wrapped sub-expressions (e.g. `+` chains inside a branch)
        // align relative to the branch keyword, and keeps the breaks eligible for discretionary
        // newlines via `RespectExistingLineBreaks` .
        //
        // The extra `.open` after each operator's break (matched by `.close, .close` at the end of
        // the else expression) bounds the chunk of break tokens *inside* each branch — so when the
        // ternary itself wraps, sub-expression breaks within a branch (e.g., the `[` / `]` breaks
        // of a single-element array literal) don't fire just because the outer ternary did. Mirrors
        // upstream apple/swift-format's `visit(_:TernaryExprSyntax)` .
        before(node.questionMark, tokens: .break(.open(kind: .continuation)), .open)
        after(node.questionMark, tokens: .space)
        before(
            node.colon,
            tokens: .break(.close(mustBreak: false), size: 0),
            .break(.open(kind: .continuation)),
            .open
        )
        after(node.colon, tokens: .space)

        let closeScopeToken: TokenSyntax?

        if let parenExpr = outermostEnclosingNode(from: Syntax(node.elseExpression)) {
            closeScopeToken = parenExpr.lastToken(viewMode: .sourceAccurate)
        } else {
            closeScopeToken = node.elseExpression.lastToken(viewMode: .sourceAccurate)
        }
        after(closeScopeToken, tokens: .break(.close(mustBreak: false), size: 0), .close, .close)
        return .visitChildren
    }

    func visitWhereClause(_ node: WhereClauseSyntax) -> SyntaxVisitorContinueKind {
        // We need to special case `where` -clauses associated with `catch` blocks when
        // `placeElseCatchOnNewLine == false` , because that's the one situation where we want the
        // `where` keyword to be treated as a continuation; that way, we get this:
        //
        // } catch LongExceptionName where longCondition { ... }
        //
        // instead of this:
        //
        // } catch LongExceptionName where longCondition { ... }
        //
        let wherePrecedingBreak: Token
        let whereTrailingBreak: Token

        if !config[PlaceElseCatchOnNewLine.self],
           let parent = node.parent,
           parent.is(CatchItemSyntax.self)
        {
            wherePrecedingBreak = .break(.continue)
            whereTrailingBreak = .break
        } else if let parent = node.parent, parent.is(SwitchCaseItemSyntax.self) {
            // Indent `where` past `case` when it wraps, and indent the condition continuation one
            // further level if it also wraps.
            wherePrecedingBreak = .break(.continue)
            whereTrailingBreak = .break(.continue)
        } else if let parent = node.parent, parent.is(ForStmtSyntax.self) {
            // j0l-do5: a `for ... where ...` clause's break tokens and grouping are emitted by
            // `visitForStmt`, which needs to coordinate the `in`-clause, `where`-clause, and brace
            // together. Skip here to avoid emitting them twice.
            return .visitChildren
        } else {
            wherePrecedingBreak = .break(.same)
            whereTrailingBreak = .break
        }
        before(node.whereKeyword, tokens: wherePrecedingBreak, .open)
        after(node.whereKeyword, tokens: whereTrailingBreak)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitDeclModifier(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
        // Due to the way we currently use spaces after let/var keywords in variable bindings, we
        // need this special exception for `async let` statements to avoid breaking prematurely
        // between the `async` and `let` keywords.
        let breakOrSpace: Token
        breakOrSpace = node.name.tokenKind == .keyword(.async)
            ? .space
            : .break
        after(node.lastToken(viewMode: .sourceAccurate), tokens: breakOrSpace)
        return .visitChildren
    }

    func visitFunctionSignature(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
        // When KeepReturnTypeWithSignature is enabled, the rule's purpose is to keep the return
        // clause attached to the closing paren / effect specifiers. Ignore any pre-existing
        // discretionary newline before `->` so a previously-broken signature gets re-attached.
        let newlines: NewlineBehavior = config[KeepReturnTypeWithSignature.self]
            ? .elective(ignoresDiscretionary: true)
            : .elective
        before(
            node.returnClause?.firstToken(viewMode: .sourceAccurate),
            tokens: .break(.continue, newlines: newlines)
        )
        return .visitChildren
    }

    func visitMetatypeType(_: MetatypeTypeSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

    func visitOptionalType(_: OptionalTypeSyntax) -> SyntaxVisitorContinueKind { .visitChildren }
}
