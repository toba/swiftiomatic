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
    func visitClassDecl(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeTypeDeclBlock(
            Syntax(node),
            attributes: node.attributes,
            modifiers: node.modifiers,
            typeKeyword: node.classKeyword,
            identifier: node.name,
            genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(
                Syntax.init
            ),
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock
        )
        return .visitChildren
    }

    func visitActorDecl(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeTypeDeclBlock(
            Syntax(node),
            attributes: node.attributes,
            modifiers: node.modifiers,
            typeKeyword: node.actorKeyword,
            identifier: node.name,
            genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(
                Syntax.init
            ),
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock
        )
        return .visitChildren
    }

    func visitStructDecl(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeTypeDeclBlock(
            Syntax(node),
            attributes: node.attributes,
            modifiers: node.modifiers,
            typeKeyword: node.structKeyword,
            identifier: node.name,
            genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(
                Syntax.init
            ),
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock
        )
        return .visitChildren
    }

    func visitEnumDecl(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeTypeDeclBlock(
            Syntax(node),
            attributes: node.attributes,
            modifiers: node.modifiers,
            typeKeyword: node.enumKeyword,
            identifier: node.name,
            genericParameterOrPrimaryAssociatedTypeClause: node.genericParameterClause.map(
                Syntax.init
            ),
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock
        )
        return .visitChildren
    }

    func visitProtocolDecl(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        arrangeTypeDeclBlock(
            Syntax(node),
            attributes: node.attributes,
            modifiers: node.modifiers,
            typeKeyword: node.protocolKeyword,
            identifier: node.name,
            genericParameterOrPrimaryAssociatedTypeClause:
                node.primaryAssociatedTypeClause.map(Syntax.init),
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock
        )
        return .visitChildren
    }

    func visitExtensionDecl(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Parser recovery on a malformed `extension` declaration can occasionally yield an
        // extendedType with no tokens; skip rather than crash so the rest of the file still
        // formats.
        guard let lastTokenOfExtendedType = node.extendedType.lastToken(viewMode: .sourceAccurate)
        else {
            assertionFailure("ExtensionDeclSyntax.extendedType must have at least one token")
            return .visitChildren
        }
        arrangeTypeDeclBlock(
            Syntax(node),
            attributes: node.attributes,
            modifiers: node.modifiers,
            typeKeyword: node.extensionKeyword,
            identifier: lastTokenOfExtendedType,
            genericParameterOrPrimaryAssociatedTypeClause: nil,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock
        )
        return .visitChildren
    }

    func visitMacroDecl(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
        // Macro declarations have a syntax that combines the best parts of types and functions
        // while adding their own unique flavor, so we have to copy and adapt the relevant parts of
        // those `arrange*` functions here.
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        arrangeAttributeList(
            node.attributes,
            separateByLineBreaks: config[BreakBeforeEachArgument.self]
        )

        let hasArguments = !node.signature.parameterClause.parameters.isEmpty

        // Prioritize keeping ") -> <return_type>" together. We can only do this if the macro has
        // arguments.
        if hasArguments, config[KeepReturnTypeWithSignature.self] {
            // Due to visitation order, the matching .open break is added in ParameterClauseSyntax.
            after(node.signature.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        let mustBreak = node.signature.returnClause != nil || node.definition != nil
        arrangeParameterClause(
            node.signature.parameterClause,
            forcesBreakBeforeRightParen: mustBreak
        )

        // Prioritize keeping "<modifiers> macro <name>(" together. Also include the ")" if the
        // parameter list is empty.
        let firstTokenAfterAttributes = node.modifiers.firstToken(viewMode: .sourceAccurate)
            ?? node.macroKeyword
        before(firstTokenAfterAttributes, tokens: .open)
        after(node.macroKeyword, tokens: .break)

        if hasArguments || node.genericParameterClause != nil {
            after(node.signature.parameterClause.leftParen, tokens: .close)
        } else {
            after(node.signature.parameterClause.rightParen, tokens: .close)
        }

        if let genericWhereClause = node.genericWhereClause {
            before(
                genericWhereClause.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.continue),
                .open
            )
            after(genericWhereClause.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        if let definition = node.definition {
            // Start the group *after* the `=` so that it all wraps onto its own line if it doesn't
            // fit.
            after(definition.equal, tokens: .open)
            after(definition.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    /// Applies formatting tokens to the tokens in the given type declaration node (i.e., a class,
    /// struct, enum, protocol, or extension).
    func arrangeTypeDeclBlock(
        _ node: Syntax,
        attributes: AttributeListSyntax?,
        modifiers: DeclModifierListSyntax?,
        typeKeyword: TokenSyntax,
        identifier: TokenSyntax,
        genericParameterOrPrimaryAssociatedTypeClause: Syntax?,
        inheritanceClause: InheritanceClauseSyntax?,
        genericWhereClause: GenericWhereClauseSyntax?,
        memberBlock: MemberBlockSyntax
    ) {
        before(node.firstToken(viewMode: .sourceAccurate), tokens: .open)

        arrangeAttributeList(
            attributes,
            separateByLineBreaks: config[BreakBetweenDeclAttributes.self]
        )

        // Prioritize keeping "<modifiers> <keyword> <name>:" together (corresponding group close is
        // below at `lastTokenBeforeBrace` ).
        let firstTokenAfterAttributes = modifiers?.firstToken(viewMode: .sourceAccurate)
            ?? typeKeyword
        before(firstTokenAfterAttributes, tokens: .open)
        after(typeKeyword, tokens: .break)

        arrangeBracesAndContents(of: memberBlock, contentsKeyPath: \.members)

        if let genericWhereClause {
            before(
                genericWhereClause.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.continue),
                .open
            )
            after(memberBlock.leftBrace, tokens: .close)
        }

        let lastTokenBeforeBrace = inheritanceClause?.colon
            ?? genericParameterOrPrimaryAssociatedTypeClause?.lastToken(viewMode: .sourceAccurate)
            ?? identifier
        after(lastTokenBeforeBrace, tokens: .close)

        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
    }
}
