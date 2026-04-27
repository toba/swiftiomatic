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

/// Controls placement of access level modifiers on extensions vs. their members.
///
/// The behavior of this rule is controlled by `Configuration.extensionAccessControl.placement` :
///
/// - `onMembers` (default): Access levels on extensions are moved to individual members.
/// - `onExtension` : When all members share the same access level, it is hoisted to the extension.
///
/// Lint: A lint error is raised when access control placement doesn't match the configuration.
///
/// Rewrite: Access control modifiers are moved to match the configured placement.
final class ExtensionAccessLevel: RewriteSyntaxRule<ExtensionAccessControlConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .access }
    private enum State {
        /// The rule is currently visiting top-level declarations.
        case topLevel

        /// The rule is currently inside an extension that has the given access level keyword. Used
        /// in `onMembers` mode to add the keyword to members.
        case insideExtension(accessKeyword: Keyword)

        /// The rule is currently inside an extension where members' access level is being hoisted.
        /// Used in `onExtension` mode to remove the keyword from members.
        case hoistingFromExtension(accessKeyword: Keyword)
    }

    /// Tracks the state of the rule to determine which action should be taken on visited
    /// declarations.
    private var state: State = .topLevel

    /// Findings propagated up to the extension visitor from any members that were rewritten.
    private var notesFromRewrittenMembers: [Finding.Note] = []

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard case .topLevel = state else { return DeclSyntax(node) }

        switch ruleConfig.placement {
            case .onMembers: return visitOnDeclarations(node)
            case .onExtension: return visitOnExtension(node)
        }
    }

    // MARK: - onMembers mode (push access from extension to members)

    private func visitOnDeclarations(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let accessKeyword = node.modifiers.accessLevelModifier,
              case let .keyword(keyword) = accessKeyword.name.tokenKind
        else { return DeclSyntax(node) }

        notesFromRewrittenMembers = []

        let keywordToAdd: Keyword?
        let message: Finding.Message

        switch keyword {
            case .public, .private, .fileprivate, .package:
                // These access level modifiers need to be moved to members. Additionally, `private` is
                // a special case, because the *effective* access level for a top-level private
                // extension is `fileprivate` , so we need to preserve that when we apply it to the
                // members.
                if keyword == .private {
                    keywordToAdd = .fileprivate
                    message = .moveAccessKeywordAndMakeFileprivate(keyword: accessKeyword.name.text)
                } else {
                    keywordToAdd = keyword
                    message = .moveAccessKeyword(keyword: accessKeyword.name.text)
                }

            case .internal:
                // If the access level keyword was `internal` , then it's redundant and we can just
                // remove it. We don't need to modify the members at all in this case.
                message = .removeRedundantAccessKeyword
                keywordToAdd = nil

            default: return DeclSyntax(node)
        }

        // We don't have to worry about maintaining a stack here; even though extensions can nest
        // from a valid parse point of view, we ignore nested extensions because they're obviously
        // wrong semantically (and would be an error later during compilation).
        var result: ExtensionDeclSyntax
        if let keywordToAdd {
            // Visit the children in the new state to add the keyword to the extension members.
            state = .insideExtension(accessKeyword: keywordToAdd)
            defer { state = .topLevel }

            result = super.visit(node).as(ExtensionDeclSyntax.self)!
        } else {
            // We don't need to visit the children in this case, and we don't need to update the
            // state.
            result = node
        }

        // Finally, emit the finding (which includes notes from any rewritten members) and remove
        // the access level keyword from the extension itself.
        diagnose(message, on: accessKeyword, notes: notesFromRewrittenMembers)
        result.modifiers.remove(anyOf: [keyword])
        result.extensionKeyword.leadingTrivia = accessKeyword.leadingTrivia
        return DeclSyntax(result)
    }

    // MARK: - onExtension mode (hoist access from members to extension)

    private func visitOnExtension(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        // Only process extensions that don't already have an access level modifier.
        guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }

        // Swift forbids access modifiers on extensions that declare protocol conformance.
        guard node.inheritanceClause == nil else { return DeclSyntax(node) }

        // Check if all members share the same hoistable access level.
        guard let commonAccess = commonMemberAccessLevel(node.memberBlock)
        else { return DeclSyntax(node) }

        notesFromRewrittenMembers = []

        // Visit children to remove the access keyword from each member.
        state = .hoistingFromExtension(accessKeyword: commonAccess)
        defer { state = .topLevel }

        var result = super.visit(node).as(ExtensionDeclSyntax.self)!

        // Add the common access modifier to the extension.
        var modifier = DeclModifierSyntax(name: .keyword(commonAccess))
        modifier.trailingTrivia = [.spaces(1)]
        modifier.leadingTrivia = result.extensionKeyword.leadingTrivia
        result.extensionKeyword.leadingTrivia = []

        if var firstModifier = result.modifiers.first {
            // Insert before existing modifiers (e.g. @objc).
            firstModifier.leadingTrivia = modifier.leadingTrivia
            modifier.leadingTrivia = []
            result.modifiers[result.modifiers.startIndex] = firstModifier
            result.modifiers.insert(modifier, at: result.modifiers.startIndex)
        } else {
            result.modifiers = .init([modifier])
        }

        diagnose(
            .hoistAccessKeyword(keyword: TokenSyntax.keyword(commonAccess).text),
            on: node.extensionKeyword,
            notes: notesFromRewrittenMembers
        )
        return DeclSyntax(result)
    }

    /// Returns the common access level keyword shared by all direct members, or `nil` if members
    /// have mixed or non-hoistable access levels.
    ///
    /// Only `public` , `package` , and `fileprivate` are hoistable. `private` is not hoisted
    /// because it would change semantics (extension-level `private` means `fileprivate` ).
    /// `internal` is not hoisted because it's redundant on an extension.
    private func commonMemberAccessLevel(_ memberBlock: MemberBlockSyntax) -> Keyword? {
        guard !memberBlock.members.isEmpty else { return nil }

        var commonAccess: Keyword?

        for member in memberBlock.members {
            let decl = member.decl

            // Don't hoist when there are #if blocks — too complex to analyze.
            if decl.is(IfConfigDeclSyntax.self) { return nil }

            // Get the access level of this member.
            guard let modifiers = decl.asProtocol(WithModifiersSyntax.self)?.modifiers,
                  let accessModifier = modifiers.accessLevelModifier,
                  case let .keyword(keyword) = accessModifier.name.tokenKind else { return nil }

            // Only hoist public, package, or fileprivate.
            guard keyword == .public || keyword == .package || keyword == .fileprivate
            else { return nil }

            if let existing = commonAccess {
                guard existing == keyword else { return nil }
            } else {
                commonAccess = keyword
            }
        }

        return commonAccess
    }

    // MARK: - Member visitors

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.actorKeyword)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.classKeyword)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.enumKeyword)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.funcKeyword)
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.initKeyword)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.structKeyword)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.subscriptKeyword)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.typealiasKeyword)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.bindingSpecifier)
    }

    // MARK: - Member processing

    /// Dispatches to the appropriate add/remove logic based on the current state.
    private func processExtensionMember<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        _ decl: Decl,
        declKeywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
    ) -> DeclSyntax {
        switch state {
            case .topLevel: DeclSyntax(decl)
            case let .insideExtension(accessKeyword):
                applyingAccessModifierIfNone(
                    accessKeyword,
                    to: decl,
                    declKeywordKeyPath: declKeywordKeyPath
                )
            case let .hoistingFromExtension(accessKeyword):
                removingAccessModifier(
                    accessKeyword,
                    from: decl,
                    declKeywordKeyPath: declKeywordKeyPath
                )
        }
    }

    /// Adds `modifier` to `decl` if it doesn't already have an explicit access level modifier.
    private func applyingAccessModifierIfNone<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        _ modifier: Keyword,
        to decl: Decl,
        declKeywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
    ) -> DeclSyntax {
        // If there's already an access modifier among the modifier list, bail out.
        guard decl.modifiers.accessLevelModifier == nil else { return DeclSyntax(decl) }

        notesFromRewrittenMembers.append(
            Finding.Note(
                message: .addModifierToExtensionMember(keyword: TokenSyntax.keyword(modifier).text),
                location:
                    Finding.Location(decl.startLocation(converter: context.sourceLocationConverter))
            ))

        var result = decl
        var modifier = DeclModifierSyntax(name: .keyword(modifier))
        modifier.trailingTrivia = [.spaces(1)]

        guard var firstModifier = decl.modifiers.first else {
            // If there are no modifiers at all, add the one being requested, moving the leading
            // trivia from the decl keyword to that modifier (to preserve leading comments,
            // newlines, etc.).
            modifier.leadingTrivia = decl[keyPath: declKeywordKeyPath].leadingTrivia
            result[keyPath: declKeywordKeyPath].leadingTrivia = []
            result.modifiers = .init([modifier])
            return DeclSyntax(result)
        }

        // Otherwise, insert the modifier at the front of the modifier list, moving the (original)
        // first modifier's leading trivia to the new one (to preserve leading comments, newlines,
        // etc.).
        modifier.leadingTrivia = firstModifier.leadingTrivia
        firstModifier.leadingTrivia = []
        result.modifiers[result.modifiers.startIndex] = firstModifier
        result.modifiers.insert(modifier, at: result.modifiers.startIndex)
        return DeclSyntax(result)
    }

    /// Removes the access modifier from `decl` if it matches the keyword being hoisted.
    private func removingAccessModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        _ keyword: Keyword,
        from decl: Decl,
        declKeywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
    ) -> DeclSyntax {
        guard let accessModifier = decl.modifiers.accessLevelModifier,
              case .keyword(keyword) = accessModifier.name.tokenKind
        else { return DeclSyntax(decl) }

        notesFromRewrittenMembers.append(
            Finding.Note(
                message: .removeModifierFromExtensionMember(keyword: accessModifier.name.text),
                location:
                    Finding.Location(decl.startLocation(converter: context.sourceLocationConverter))
            ))

        var result = decl
        let savedLeadingTrivia = accessModifier.leadingTrivia
        result.modifiers.remove(anyOf: [keyword])

        if var firstModifier = result.modifiers.first {
            // Transfer trivia to the remaining first modifier.
            firstModifier.leadingTrivia = savedLeadingTrivia
            result.modifiers[result.modifiers.startIndex] = firstModifier
        } else {
            // No modifiers left — transfer trivia to the declaration keyword.
            result[keyPath: declKeywordKeyPath].leadingTrivia = savedLeadingTrivia
        }

        return DeclSyntax(result)
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantAccessKeyword: Finding.Message =
        "remove this redundant 'internal' access modifier from this extension"

    static func moveAccessKeyword(keyword: String) -> Finding.Message {
        "move this '\(keyword)' access modifier to precede each member inside this extension"
    }

    static func moveAccessKeywordAndMakeFileprivate(keyword: String) -> Finding.Message {
        "remove this '\(keyword)' access modifier and declare each member inside this extension as 'fileprivate'"
    }

    static func addModifierToExtensionMember(keyword: String) -> Finding.Message {
        "add '\(keyword)' access modifier to this declaration"
    }

    static func hoistAccessKeyword(keyword: String) -> Finding.Message {
        "hoist '\(keyword)' access modifier from members to this extension"
    }

    static func removeModifierFromExtensionMember(keyword: String) -> Finding.Message {
        "remove '\(keyword)' access modifier from this declaration"
    }
}

// MARK: - Configuration

package struct ExtensionAccessControlConfiguration: SyntaxRuleValue {
    package enum Placement: String, Codable, Sendable {
        case onMembers
        case onExtension
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// Where to attach the access-level modifier: on each member of an extension, or hoisted onto
    /// the extension itself when uniform.
    package var placement: Placement = .onMembers

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        placement = try container.decodeIfPresent(Placement.self, forKey: .placement)
            ?? .onMembers
    }
}
