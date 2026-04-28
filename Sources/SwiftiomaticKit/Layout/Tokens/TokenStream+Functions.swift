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
    func visitFunctionDecl(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let hasArguments = !node.signature.parameterClause.parameters.isEmpty

        let hasBody = node.body != nil

        // Prioritize keeping ") throws -> <return_type>" together (or ") throws -> <return_type> {"
        // when there's a body). We can only do this if the function has arguments.
        if hasArguments, config[KeepFunctionOutputTogether.self], !hasBody {
            // Due to visitation order, the matching .open break is added in ParameterClauseSyntax.
            after(node.signature.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        let mustBreak = hasBody || node.signature.returnClause != nil
        arrangeParameterClause(
            node.signature.parameterClause,
            forcesBreakBeforeRightParen: mustBreak
        )

        // Prioritize keeping "<modifiers> func <name>(" together. Also include the ")" if the
        // parameter list is empty.
        let firstTokenAfterAttributes = node.modifiers.firstToken(viewMode: .sourceAccurate)
            ?? node.funcKeyword
        before(firstTokenAfterAttributes, tokens: .open)
        after(node.funcKeyword, tokens: .break)
        if hasArguments || node.genericParameterClause != nil {
            after(node.signature.parameterClause.leftParen, tokens: .close)
        } else {
            after(node.signature.parameterClause.rightParen, tokens: .close)
        }

        // Add a non-breaking space after the identifier if it's an operator, to separate it
        // visually from the following parenthesis or generic argument list. Note that even if the
        // function is defining a prefix or postfix operator, the token kind always comes through as
        // `binaryOperator` .
        if case .binaryOperator = node.name.tokenKind {
            after(node.name.lastToken(viewMode: .sourceAccurate), tokens: .space)
        }

        arrangeFunctionLikeDecl(
            Syntax(node),
            attributes: node.attributes,
            genericWhereClause: node.genericWhereClause,
            body: node.body,
            bodyContentsKeyPath: \.statements
        )

        // When the function has a body, close the keepFunctionOutputTogether group after the
        // opening brace. This must be called after arrangeFunctionLikeDecl so that (due to afterMap
        // reversal) the .close is emitted immediately after '{', before the body's .break/.open
        // tokens.
        if hasArguments, config[KeepFunctionOutputTogether.self], hasBody {
            after(node.body!.leftBrace, tokens: .close)
        }

        return .visitChildren
    }

    func visitInitializerDecl(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let hasArguments = !node.signature.parameterClause.parameters.isEmpty
        let hasBody = node.body != nil

        // Prioritize keeping ") throws" together (or ") throws {" when there's a body). We can only
        // do this if the initializer has arguments.
        if hasArguments, config[KeepFunctionOutputTogether.self], !hasBody {
            after(node.signature.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        arrangeParameterClause(
            node.signature.parameterClause,
            forcesBreakBeforeRightParen: hasBody
        )

        // Prioritize keeping "<modifiers> init<punctuation>" together.
        let firstTokenAfterAttributes = node.modifiers.firstToken(viewMode: .sourceAccurate)
            ?? node.initKeyword
        before(firstTokenAfterAttributes, tokens: .open)

        if hasArguments || node.genericParameterClause != nil {
            after(node.signature.parameterClause.leftParen, tokens: .close)
        } else {
            after(node.signature.parameterClause.rightParen, tokens: .close)
        }

        arrangeFunctionLikeDecl(
            Syntax(node),
            attributes: node.attributes,
            genericWhereClause: node.genericWhereClause,
            body: node.body,
            bodyContentsKeyPath: \.statements
        )

        // When the initializer has a body, close the keepFunctionOutputTogether group after the
        // opening brace (must be after arrangeFunctionLikeDecl for correct afterMap ordering).
        if hasArguments, config[KeepFunctionOutputTogether.self], hasBody {
            after(node.body!.leftBrace, tokens: .close)
        }

        return .visitChildren
    }

    func visitDeinitializerDecl(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeFunctionLikeDecl(
            Syntax(node),
            attributes: node.attributes,
            genericWhereClause: nil,
            body: node.body,
            bodyContentsKeyPath: \.statements
        )
        return .visitChildren
    }

    func visitSubscriptDecl(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        let hasArguments = !node.parameterClause.parameters.isEmpty

        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        // Prioritize keeping "<modifiers> subscript" together.
        if let firstModifierToken = node.modifiers.firstToken(viewMode: .sourceAccurate) {
            before(firstModifierToken, tokens: .open)

            if hasArguments || node.genericParameterClause != nil {
                after(node.parameterClause.leftParen, tokens: .close)
            } else {
                after(node.parameterClause.rightParen, tokens: .close)
            }
        }

        // Prioritize keeping ") -> <return_type>" together. We can only do this if the subscript
        // has arguments.
        if hasArguments, config[KeepFunctionOutputTogether.self] {
            // Due to visitation order, the matching .open break is added in ParameterClauseSyntax.
            after(node.returnClause.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )

        if let genericWhereClause = node.genericWhereClause {
            before(
                genericWhereClause.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.same),
                .open
            )
            after(genericWhereClause.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        before(node.returnClause.firstToken(viewMode: .sourceAccurate), tokens: .break)

        if let accessorBlock = node.accessorBlock {
            switch accessorBlock.accessors {
                case let .accessors(accessors):
                    arrangeBracesAndContents(
                        leftBrace: accessorBlock.leftBrace,
                        accessors: accessors,
                        rightBrace: accessorBlock.rightBrace
                    )
                case .getter:
                    arrangeBracesAndContents(
                        of: accessorBlock, contentsKeyPath: \.getterCodeBlockItems)
            }
        }

        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)

        arrangeParameterClause(node.parameterClause, forcesBreakBeforeRightParen: true)

        return .visitChildren
    }

    func visitAccessorEffectSpecifiers(
        _ node: AccessorEffectSpecifiersSyntax
    ) -> SyntaxVisitorContinueKind {
        arrangeEffectSpecifiers(node)
        return .visitChildren
    }

    func visitFunctionEffectSpecifiers(
        _ node: FunctionEffectSpecifiersSyntax
    ) -> SyntaxVisitorContinueKind {
        arrangeEffectSpecifiers(node)
        return .visitChildren
    }

    func visitTypeEffectSpecifiers(
        _ node: TypeEffectSpecifiersSyntax
    ) -> SyntaxVisitorContinueKind {
        arrangeEffectSpecifiers(node)
        return .visitChildren
    }

    /// Applies formatting tokens to the tokens in the given function or function-like declaration
    /// node (e.g., initializers, deinitiailizers, and subscripts).
    func arrangeFunctionLikeDecl<Node: BracedSyntax, BodyContents: SyntaxCollection>(
        _ node: Syntax,
        attributes: AttributeListSyntax?,
        genericWhereClause: GenericWhereClauseSyntax?,
        body: Node?,
        bodyContentsKeyPath: KeyPath<Node, BodyContents>?
    ) where BodyContents.Element: SyntaxProtocol {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        arrangeAttributeList(
            attributes,
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )
        arrangeBracesAndContents(of: body, contentsKeyPath: bodyContentsKeyPath)

        if let genericWhereClause {
            before(
                genericWhereClause.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.continue),
                .open
            )
            after(
                body?.leftBrace ?? genericWhereClause.lastToken(viewMode: .sourceAccurate),
                tokens: .close
            )
        }

        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
    }

    /// Arranges the `async` and `throws` effect specifiers of a function or accessor declaration.
    func arrangeEffectSpecifiers<Node: EffectSpecifiersSyntax>(_ node: Node) {
        before(node.asyncSpecifier, tokens: .break)
        before(node.throwsClause?.throwsSpecifier, tokens: .break)
        // Keep them together if both `async` and `throws` are present.
        if let asyncSpecifier = node.asyncSpecifier,
           let throwsSpecifier = node.throwsClause?.throwsSpecifier
        {
            before(asyncSpecifier, tokens: .open)
            after(throwsSpecifier, tokens: .close)
        }
    }

    // MARK: - Property and subscript accessor block nodes

    func visitAccessorDeclList(_ node: AccessorDeclListSyntax) -> SyntaxVisitorContinueKind {
        for child in node.dropLast() {
            // If the child doesn't have a body (it's just the `get` / `set` keyword), then we're in
            // a protocol and we want to let them be placed on the same line if possible. Otherwise,
            // we place a newline between each accessor.
            let newlines: NewlineBehavior = child.body == nil ? .elective : .soft
            after(
                child.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.same, size: 1, newlines: newlines)
            )
        }
        return .visitChildren
    }

    func visitAccessorDecl(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BetweenDeclarationAttributes.self]
        )
        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
        return .visitChildren
    }

    func visitAccessorParameters(_: AccessorParametersSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }
}
