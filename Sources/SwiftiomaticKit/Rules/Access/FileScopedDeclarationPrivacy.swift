// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import SwiftSyntax

/// Declarations at file scope with effective private access should be consistently declared as
/// either `fileprivate` or `private` , determined by configuration.
///
/// Lint: If a file-scoped declaration has formal access opposite to the desired access level in the
/// formatter's configuration, a lint error is raised.
///
/// Rewrite: File-scoped declarations that have formal access opposite to the desired access level
/// in the formatter's configuration will have their access level changed.
final class FileScopedDeclarationPrivacy: StructuralFormatRule<
    FileScopedDeclarationPrivacyConfiguration
>, @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .access }
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        var result = node
        result.statements = rewrittenCodeBlockItems(node.statements)
        return result
    }

    /// Returns a list of code block items equivalent to the given list, but where any file-scoped
    /// declarations with effective private access have had their formal access level rewritten, if
    /// necessary, to be either `private` or `fileprivate` , as determined by the formatter
    /// configuration.
    ///
    /// - Parameter codeBlockItems: The list of code block items to rewrite.
    /// - Returns: A new `CodeBlockItemListSyntax` that has possibly been rewritten.
    private func rewrittenCodeBlockItems(
        _ codeBlockItems: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        let newCodeBlockItems = codeBlockItems.map { codeBlockItem -> CodeBlockItemSyntax in
            switch codeBlockItem.item {
                case let .decl(decl):
                    var result = codeBlockItem
                    result.item = .decl(rewrittenDecl(decl))
                    return result
                default: return codeBlockItem
            }
        }
        return CodeBlockItemListSyntax(newCodeBlockItems)
    }

    private func rewrittenDecl(_ decl: DeclSyntax) -> DeclSyntax {
        switch Syntax(decl).as(SyntaxEnum.self) {
            case let .ifConfigDecl(ifConfigDecl): DeclSyntax(rewrittenIfConfigDecl(ifConfigDecl))
            case let .functionDecl(functionDecl): DeclSyntax(rewrittenDecl(functionDecl))
            case let .variableDecl(variableDecl): DeclSyntax(rewrittenDecl(variableDecl))
            case let .classDecl(classDecl): DeclSyntax(rewrittenDecl(classDecl))
            case let .structDecl(structDecl): DeclSyntax(rewrittenDecl(structDecl))
            case let .enumDecl(enumDecl): DeclSyntax(rewrittenDecl(enumDecl))
            case let .protocolDecl(protocolDecl): DeclSyntax(rewrittenDecl(protocolDecl))
            case let .typeAliasDecl(typealiasDecl): DeclSyntax(rewrittenDecl(typealiasDecl))
            default: decl
        }
    }

    /// Returns a new `IfConfigDeclSyntax` equivalent to the given node, but where any file-scoped
    /// declarations with effective private access have had their formal access level rewritten, if
    /// necessary, to be either `private` or `fileprivate` , as determined by the formatter
    /// configuration.
    ///
    /// - Parameter ifConfigDecl: The `IfConfigDeclSyntax` to rewrite.
    /// - Returns: A new `IfConfigDeclSyntax` that has possibly been rewritten.
    private func rewrittenIfConfigDecl(_ ifConfigDecl: IfConfigDeclSyntax) -> IfConfigDeclSyntax {
        let newClauses = ifConfigDecl.clauses.map { clause -> IfConfigClauseSyntax in
            switch clause.elements {
                case .statements(let codeBlockItemList)?:
                    var result = clause
                    result.elements = .statements(rewrittenCodeBlockItems(codeBlockItemList))
                    return result
                default: return clause
            }
        }

        var result = ifConfigDecl
        result.clauses = IfConfigClauseListSyntax(newClauses)
        return result
    }

    /// Returns a rewritten version of the given declaration if its modifier list contains `private`
    /// that contains `fileprivate` instead.
    ///
    /// If the modifier list is not inconsistent with the configured access level, the original
    /// declaration is returned unchanged.
    ///
    /// - Parameters:
    ///   - decl: The declaration to possibly rewrite.
    ///   - modifiers: The modifier list of the declaration (i.e., `decl.modifiers` ).
    ///   - factory: A reference to the `decl` 's `withModifiers` instance method that is called to
    ///     rewrite the node if needed.
    ///   - Returns: A new node if the modifiers were rewritten, or the original node if not.
    private func rewrittenDecl<DeclType: DeclSyntaxProtocol & WithModifiersSyntax>(
        _ decl: DeclType
    ) -> DeclType {
        let invalidAccess: Keyword
        let validAccess: Keyword
        let diagnostic: Finding.Message

        switch ruleConfig.accessLevel {
            case .private:
                invalidAccess = .fileprivate
                validAccess = .private
                diagnostic = .replaceFileprivateWithPrivate
            case .fileprivate:
                invalidAccess = .private
                validAccess = .fileprivate
                diagnostic = .replacePrivateWithFileprivate
        }

        guard decl.modifiers.contains(anyOf: [invalidAccess]) else { return decl }

        let newModifiers = decl.modifiers.map { modifier -> DeclModifierSyntax in
            var modifier = modifier

            let name = modifier.name
            if case .keyword(invalidAccess) = name.tokenKind {
                diagnose(diagnostic, on: name)
                modifier.name.tokenKind = .keyword(validAccess)
            }
            return modifier
        }

        var result = decl
        result.modifiers = DeclModifierListSyntax(newModifiers)
        return result
    }
}

fileprivate extension Finding.Message {
    static let replacePrivateWithFileprivate: Finding.Message =
        "replace 'private' with 'fileprivate' on file-scoped declarations"

    static let replaceFileprivateWithPrivate: Finding.Message =
        "replace 'fileprivate' with 'private' on file-scoped declarations"
}

// MARK: - Configuration

package struct FileScopedDeclarationPrivacyConfiguration: SyntaxRuleValue {
    package enum AccessLevel: String, Codable, Sendable {
        case `private`
        case `fileprivate`
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// Preferred modifier for file-scoped declarations whose effective access is private to the
    /// file.
    package var accessLevel: AccessLevel = .private

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }

        accessLevel = try container.decodeIfPresent(AccessLevel.self, forKey: .accessLevel)
            ?? .private
    }
}
