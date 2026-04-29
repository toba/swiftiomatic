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

/// Unified rule that removes or replaces redundant access control modifiers.
///
/// Combines four checks: redundant `internal`, redundant `public` on members of non-public types,
/// redundant access control on extension members matching the extension's level, and redundant
/// `fileprivate` (converted to `private` in single-type files).
final class RedundantAccessControl: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held in `Context.ruleState`.
    final class State {
        /// The name of the single logical type in the file, if any.
        var singleTypeName: String?
        /// Whether the single logical type (or its extensions) contains nested type declarations.
        var hasNestedTypes = false
        /// Whether `analyzeFileStructure` has been run for this file.
        var analyzed = false
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard !state.analyzed else { return }
        analyzeFileStructure(node.statements, state: state)
        state.analyzed = true
    }

    // MARK: - Static transforms (per-decl)

    static func transform(
        _ node: SourceFileSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SourceFileSyntax {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.singleTypeName != nil, !state.hasNestedTypes else { return node }
        var result = node
        result.statements = rewriteStatements(result.statements, context: context)
        return result
    }

    static func transform(
        _ node: ActorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let afterInternal = removeRedundantInternal(
            from: node, keywordKeyPath: \.actorKeyword, context: context
        )
        return DeclSyntax(removePublicFromMembers(of: afterInternal, context: context))
    }

    static func transform(
        _ node: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let afterInternal = removeRedundantInternal(
            from: node, keywordKeyPath: \.classKeyword, context: context
        )
        return DeclSyntax(removePublicFromMembers(of: afterInternal, context: context))
    }

    static func transform(
        _ node: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let afterInternal = removeRedundantInternal(
            from: node, keywordKeyPath: \.enumKeyword, context: context
        )
        return DeclSyntax(removePublicFromMembers(of: afterInternal, context: context))
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(removeRedundantInternal(
            from: node, keywordKeyPath: \.funcKeyword, context: context
        ))
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(removeRedundantInternal(
            from: node, keywordKeyPath: \.initKeyword, context: context
        ))
    }

    static func transform(
        _ node: ProtocolDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(removeRedundantInternal(
            from: node, keywordKeyPath: \.protocolKeyword, context: context
        ))
    }

    static func transform(
        _ node: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let afterInternal = removeRedundantInternal(
            from: node, keywordKeyPath: \.structKeyword, context: context
        )
        return DeclSyntax(removePublicFromMembers(of: afterInternal, context: context))
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(removeRedundantInternal(
            from: node, keywordKeyPath: \.subscriptKeyword, context: context
        ))
    }

    static func transform(
        _ node: TypeAliasDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(removeRedundantInternal(
            from: node, keywordKeyPath: \.typealiasKeyword, context: context
        ))
    }

    static func transform(
        _ node: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(removeRedundantInternal(
            from: node, keywordKeyPath: \.bindingSpecifier, context: context
        ))
    }

    static func transform(
        _ node: ExtensionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        // Only check extensions that have an explicit access level.
        guard let extensionModifier = node.modifiers.accessLevelModifier,
              case let .keyword(extensionKeyword) = extensionModifier.name.tokenKind
        else { return DeclSyntax(node) }

        var modified = false
        let newMembers = node.memberBlock.members.map { member -> MemberBlockItemSyntax in
            let rewritten = rewrittenDeclForExtensionACL(
                member.decl,
                extensionKeyword: extensionKeyword,
                context: context
            )
            guard rewritten.id != member.decl.id else { return member }
            modified = true
            return member.with(\.decl, rewritten)
        }

        guard modified else { return DeclSyntax(node) }
        let newMemberBlock = node.memberBlock.with(
            \.members,
            MemberBlockItemListSyntax(newMembers)
        )
        return DeclSyntax(node.with(\.memberBlock, newMemberBlock))
    }

    // MARK: - RedundantInternal: Helpers

    private static func removeRedundantInternal<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let internalModifier = decl.modifiers.accessLevelModifier,
              internalModifier.name.tokenKind == .keyword(.internal),
              internalModifier.detail == nil
        else { return decl }

        Self.diagnose(.removeRedundantInternal, on: internalModifier.name, context: context)

        var result = decl
        result.modifiers.remove(anyOf: [.internal])

        if result.modifiers.first != nil {
            result.modifiers[result.modifiers.startIndex].leadingTrivia = internalModifier
                .leadingTrivia
        } else {
            result[keyPath: keywordKeyPath].leadingTrivia = internalModifier.leadingTrivia
        }

        return result
    }

    // MARK: - RedundantPublic: Helpers

    private static func removePublicFromMembers<
        Decl: DeclGroupSyntax & WithModifiersSyntax
    >(of decl: Decl, context: Context) -> Decl {
        if let accessModifier = decl.modifiers.accessLevelModifier,
           case let .keyword(keyword) = accessModifier.name.tokenKind,
           keyword == .public || keyword == .package
        {
            return decl
        }

        var modified = false
        let newMembers = decl.memberBlock.members.map { member -> MemberBlockItemSyntax in
            let rewritten = rewrittenDeclForPublic(member.decl, context: context)
            guard rewritten.id != member.decl.id else { return member }
            modified = true
            return member.with(\.decl, rewritten)
        }

        guard modified else { return decl }
        return decl.with(
            \.memberBlock,
            decl.memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers))
        )
    }

    private static func rewrittenDeclForPublic(
        _ decl: DeclSyntax, context: Context
    ) -> DeclSyntax {
        switch Syntax(decl).as(SyntaxEnum.self) {
            case let .functionDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.funcKeyword, context: context))
            case let .variableDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.bindingSpecifier, context: context))
            case let .classDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.classKeyword, context: context))
            case let .structDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.structKeyword, context: context))
            case let .enumDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.enumKeyword, context: context))
            case let .protocolDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.protocolKeyword, context: context))
            case let .typeAliasDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.typealiasKeyword, context: context))
            case let .initializerDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.initKeyword, context: context))
            case let .subscriptDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.subscriptKeyword, context: context))
            case let .actorDecl(d):
                DeclSyntax(removePublic(from: d, keywordKeyPath: \.actorKeyword, context: context))
            default: decl
        }
    }

    private static func removePublic<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let memberModifier = decl.modifiers.accessLevelModifier,
              memberModifier.detail == nil,
              case .keyword(.public) = memberModifier.name.tokenKind else { return decl }

        Self.diagnose(.removeRedundantPublic, on: memberModifier.name, context: context)

        var result = decl
        let savedTrivia = memberModifier.leadingTrivia
        result.modifiers.remove(anyOf: [.public])
        if result.modifiers.first != nil {
            result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
        } else {
            result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
        }
        return result
    }

    // MARK: - RedundantExtensionACL: Helpers

    private static func rewrittenDeclForExtensionACL(
        _ decl: DeclSyntax, extensionKeyword: Keyword, context: Context
    ) -> DeclSyntax {
        switch Syntax(decl).as(SyntaxEnum.self) {
            case let .functionDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.funcKeyword, context: context
                ))
            case let .variableDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.bindingSpecifier, context: context
                ))
            case let .classDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.classKeyword, context: context
                ))
            case let .structDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.structKeyword, context: context
                ))
            case let .enumDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.enumKeyword, context: context
                ))
            case let .protocolDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.protocolKeyword, context: context
                ))
            case let .typeAliasDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.typealiasKeyword, context: context
                ))
            case let .initializerDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.initKeyword, context: context
                ))
            case let .subscriptDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.subscriptKeyword, context: context
                ))
            case let .actorDecl(d):
                DeclSyntax(removeExtensionACLModifier(
                    from: d, keyword: extensionKeyword,
                    keywordKeyPath: \.actorKeyword, context: context
                ))
            default: decl
        }
    }

    private static func removeExtensionACLModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        keyword extensionKeyword: Keyword,
        keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let memberModifier = decl.modifiers.accessLevelModifier,
              memberModifier.detail == nil,
              case let .keyword(memberKeyword) = memberModifier.name.tokenKind,
              memberKeyword == extensionKeyword else { return decl }

        Self.diagnose(
            .removeRedundantExtensionACL(keyword: memberModifier.name.text),
            on: memberModifier.name,
            context: context
        )

        var result = decl
        let savedTrivia = memberModifier.leadingTrivia
        result.modifiers.remove(anyOf: [extensionKeyword])
        if result.modifiers.first != nil {
            result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
        } else {
            result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
        }
        return result
    }

    // MARK: - RedundantFileprivate: Phase 1 — File Structure Analysis

    private static func analyzeFileStructure(
        _ statements: CodeBlockItemListSyntax,
        state: State
    ) {
        var primaryTypeName: String?

        for item in statements {
            switch item.item {
                case let .decl(decl):
                    if let name = topLevelTypeName(decl) {
                        if primaryTypeName == nil {
                            primaryTypeName = name
                        } else if primaryTypeName != name {
                            state.singleTypeName = nil
                            return
                        }
                    } else if decl.is(ImportDeclSyntax.self) {
                        continue
                    } else if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
                        analyzeIfConfig(ifConfig, primaryTypeName: &primaryTypeName, state: state)
                        if state.singleTypeName == nil, primaryTypeName == nil { return }
                    } else {
                        state.singleTypeName = nil
                        return
                    }
                default:
                    state.singleTypeName = nil
                    return
            }
        }

        state.singleTypeName = primaryTypeName

        guard primaryTypeName != nil else { return }

        // Check for nested types in the primary type and its extensions.
        for item in statements {
            guard case let .decl(decl) = item.item else { continue }
            if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
                if ifConfigHasNestedTypes(ifConfig) {
                    state.hasNestedTypes = true
                    return
                }
            } else if declHasNestedTypes(decl) {
                state.hasNestedTypes = true
                return
            }
        }
    }

    private static func analyzeIfConfig(
        _ ifConfig: IfConfigDeclSyntax,
        primaryTypeName: inout String?,
        state: State
    ) {
        for clause in ifConfig.clauses {
            guard case .statements(let stmts)? = clause.elements else { continue }
            for item in stmts {
                guard case let .decl(decl) = item.item else {
                    state.singleTypeName = nil
                    return
                }
                if let name = topLevelTypeName(decl) {
                    if primaryTypeName == nil {
                        primaryTypeName = name
                    } else if primaryTypeName != name {
                        state.singleTypeName = nil
                        return
                    }
                } else if decl.is(ImportDeclSyntax.self) {
                    continue
                } else if let nested = decl.as(IfConfigDeclSyntax.self) {
                    analyzeIfConfig(nested, primaryTypeName: &primaryTypeName, state: state)
                    if state.singleTypeName == nil, primaryTypeName == nil { return }
                } else {
                    state.singleTypeName = nil
                    return
                }
            }
        }
    }

    private static func topLevelTypeName(_ decl: DeclSyntax) -> String? {
        if let structDecl = decl.as(StructDeclSyntax.self) {
            return structDecl.name.text
        } else if let classDecl = decl.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
            return enumDecl.name.text
        } else if let actorDecl = decl.as(ActorDeclSyntax.self) {
            return actorDecl.name.text
        } else if let extDecl = decl.as(ExtensionDeclSyntax.self) {
            guard extDecl.extendedType.as(IdentifierTypeSyntax.self) != nil else { return nil }
            return extDecl.extendedType.trimmedDescription
        }
        return nil
    }

    private static func declHasNestedTypes(_ decl: DeclSyntax) -> Bool {
        let members: MemberBlockItemListSyntax?
        if let structDecl = decl.as(StructDeclSyntax.self) {
            members = structDecl.memberBlock.members
        } else if let classDecl = decl.as(ClassDeclSyntax.self) {
            members = classDecl.memberBlock.members
        } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
            members = enumDecl.memberBlock.members
        } else if let actorDecl = decl.as(ActorDeclSyntax.self) {
            members = actorDecl.memberBlock.members
        } else if let extensionDecl = decl.as(ExtensionDeclSyntax.self) {
            members = extensionDecl.memberBlock.members
        } else {
            return false
        }

        guard let members else { return false }
        return members.contains { isTypeDeclaration($0.decl) }
    }

    private static func ifConfigHasNestedTypes(_ ifConfig: IfConfigDeclSyntax) -> Bool {
        for clause in ifConfig.clauses {
            guard case .statements(let stmts)? = clause.elements else { continue }
            for item in stmts {
                guard case let .decl(decl) = item.item else { continue }
                if let nested = decl.as(IfConfigDeclSyntax.self) {
                    if ifConfigHasNestedTypes(nested) { return true }
                } else if declHasNestedTypes(decl) {
                    return true
                }
            }
        }
        return false
    }

    private static func isTypeDeclaration(_ decl: DeclSyntax) -> Bool {
        decl.is(StructDeclSyntax.self)
            || decl.is(ClassDeclSyntax.self)
            || decl.is(EnumDeclSyntax.self)
            || decl.is(ActorDeclSyntax.self)
            || decl.is(ProtocolDeclSyntax.self)
    }

    // MARK: - RedundantFileprivate: Phase 2 — Rewriting

    private static func rewriteStatements(
        _ statements: CodeBlockItemListSyntax,
        context: Context
    ) -> CodeBlockItemListSyntax {
        let newItems = statements.map { item -> CodeBlockItemSyntax in
            guard case let .decl(decl) = item.item else { return item }

            if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
                var result = item
                result.item = .decl(DeclSyntax(rewriteIfConfig(ifConfig, context: context)))
                return result
            }

            guard let rewritten = rewriteMembersInDecl(decl, context: context) else { return item }
            var result = item
            result.item = .decl(rewritten)
            return result
        }
        return CodeBlockItemListSyntax(newItems)
    }

    private static func rewriteIfConfig(
        _ ifConfig: IfConfigDeclSyntax,
        context: Context
    ) -> IfConfigDeclSyntax {
        let newClauses = ifConfig.clauses.map { clause -> IfConfigClauseSyntax in
            guard case .statements(let stmts)? = clause.elements else { return clause }
            var result = clause
            result.elements = .statements(rewriteStatements(stmts, context: context))
            return result
        }
        var result = ifConfig
        result.clauses = IfConfigClauseListSyntax(newClauses)
        return result
    }

    private static func rewriteMembersInDecl(
        _ decl: DeclSyntax,
        context: Context
    ) -> DeclSyntax? {
        if var structDecl = decl.as(StructDeclSyntax.self) {
            structDecl.memberBlock.members =
                rewriteMembers(structDecl.memberBlock.members, context: context)
            return DeclSyntax(structDecl)
        } else if var classDecl = decl.as(ClassDeclSyntax.self) {
            classDecl.memberBlock.members =
                rewriteMembers(classDecl.memberBlock.members, context: context)
            return DeclSyntax(classDecl)
        } else if var enumDecl = decl.as(EnumDeclSyntax.self) {
            enumDecl.memberBlock.members =
                rewriteMembers(enumDecl.memberBlock.members, context: context)
            return DeclSyntax(enumDecl)
        } else if var actorDecl = decl.as(ActorDeclSyntax.self) {
            actorDecl.memberBlock.members =
                rewriteMembers(actorDecl.memberBlock.members, context: context)
            return DeclSyntax(actorDecl)
        } else if var extDecl = decl.as(ExtensionDeclSyntax.self) {
            extDecl.memberBlock.members =
                rewriteMembers(extDecl.memberBlock.members, context: context)
            return DeclSyntax(extDecl)
        }
        return nil
    }

    private static func rewriteMembers(
        _ members: MemberBlockItemListSyntax,
        context: Context
    ) -> MemberBlockItemListSyntax {
        let newMembers = members.map { member -> MemberBlockItemSyntax in
            let decl = member.decl
            guard let rewritten = rewriteFileprivate(on: decl, context: context) else {
                return member
            }
            var result = member
            result.decl = rewritten
            return result
        }
        return MemberBlockItemListSyntax(newMembers)
    }

    private static func rewriteFileprivate(
        on decl: DeclSyntax,
        context: Context
    ) -> DeclSyntax? {
        if let funcDecl = decl.as(FunctionDeclSyntax.self) {
            return DeclSyntax(replaceFileprivate(on: funcDecl, context: context))
        } else if let varDecl = decl.as(VariableDeclSyntax.self) {
            return DeclSyntax(replaceFileprivate(on: varDecl, context: context))
        } else if let initDecl = decl.as(InitializerDeclSyntax.self) {
            return DeclSyntax(replaceFileprivate(on: initDecl, context: context))
        } else if let subscriptDecl = decl.as(SubscriptDeclSyntax.self) {
            return DeclSyntax(replaceFileprivate(on: subscriptDecl, context: context))
        } else if let typealiasDecl = decl.as(TypeAliasDeclSyntax.self) {
            return DeclSyntax(replaceFileprivate(on: typealiasDecl, context: context))
        }
        return nil
    }

    private static func replaceFileprivate<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        on decl: Decl,
        context: Context
    ) -> Decl {
        guard decl.modifiers.contains(anyOf: [.fileprivate]) else { return decl }

        let newModifiers = decl.modifiers.map { modifier -> DeclModifierSyntax in
            var modifier = modifier
            if case .keyword(.fileprivate) = modifier.name.tokenKind {
                Self.diagnose(.replaceFileprivateWithPrivate, on: modifier.name, context: context)
                modifier.name.tokenKind = .keyword(.private)
            }
            return modifier
        }

        var result = decl
        result.modifiers = DeclModifierListSyntax(newModifiers)
        return result
    }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let removeRedundantInternal: Finding.Message =
        "remove redundant 'internal' access modifier"

    static let removeRedundantPublic: Finding.Message =
        "remove redundant 'public'; the enclosing type is not public"

    static func removeRedundantExtensionACL(keyword: String) -> Finding.Message {
        "remove redundant '\(keyword)'; it matches the extension's access level"
    }

    static let replaceFileprivateWithPrivate: Finding.Message =
        "replace 'fileprivate' with 'private'; no other type in this file needs broader access"
}
