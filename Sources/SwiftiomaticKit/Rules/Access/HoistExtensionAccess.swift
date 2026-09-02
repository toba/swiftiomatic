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
/// For a nested protocol, the access level goes on the protocol declaration itself and not on its
/// requirements, which implicitly have the protocol's access level.
///
/// Lint: A lint error is raised when access control placement doesn't match the configuration.
///
/// Rewrite: Access control modifiers are moved to match the configured placement.
final class HoistExtensionAccess: StructuralFormatRule<ExtensionAccessControlConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .hoist }
    private enum State {
        /// The rule is currently visiting top-level declarations.
        case topLevel

        /// The rule is currently inside an extension that has the given access level keyword, along
        /// with any `@_spi` attributes that should be moved down to each member alongside that
        /// keyword. Used in `onMembers` mode to add the keyword to members.
        case insideExtension(accessKeyword: Keyword, spiAttributes: [AttributeListSyntax.Element])

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
                // These access level modifiers need to be moved to members. Additionally, `private`
                // is a special case, because the *effective* access level for a top-level private
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

        // An `@_spi` attribute on an extension only has an effect when the extension also has an
        // explicit access level, and it applies to the members the same way that access level does.
        // Move them down to the members alongside the access level. Other attributes like `@objc`
        // or `@available` belong on the extension itself and are left untouched.
        let spiAttributes: [AttributeListSyntax.Element] = keywordToAdd != nil
            ? node.attributes.filter(\.isSPIAttribute)
            : []

        // Swift refuses a public member in an extension whose where-clause names an SPI
        // declaration, so the grant stays where it is. The diagnostic reads "cannot use struct 'X'
        // in an extension with public or '@usableFromInline' members; it is SPI". Extending an SPI
        // type carries no such restriction, so only the where-clause is examined.
        if !spiAttributes.isEmpty, whereClauseMayNameSPIType(node.genericWhereClause) {
            return DeclSyntax(node)
        }

        var result: ExtensionDeclSyntax

        if let keywordToAdd {
            state = .insideExtension(accessKeyword: keywordToAdd, spiAttributes: spiAttributes)
            defer { state = .topLevel }

            result = super.visit(node).as(ExtensionDeclSyntax.self)!
        } else {
            result = node
        }

        diagnose(message, on: accessKeyword, notes: notesFromRewrittenMembers)

        let originalLeadingTrivia = result.leadingTrivia
        result.modifiers.remove(anyOf: [keyword])

        if !spiAttributes.isEmpty {
            result.attributes = result.attributes.filter { !$0.isSPIAttribute }
        }

        if let firstAttribute = result.attributes.first {
            result.attributes[result.attributes.startIndex] = firstAttribute.with(
                \.leadingTrivia, originalLeadingTrivia)
        } else {
            result.extensionKeyword.leadingTrivia = originalLeadingTrivia
        }
        return DeclSyntax(result)
    }

    // MARK: - SPI constraint guard

    /// Whether any type the where-clause names may carry an `@_spi` grant.
    ///
    /// A name this file declares without a grant is safe. Every other name is unresolved and counts
    /// as unsafe, because the declaration may sit in another file or another module. A generic
    /// parameter such as `T` resolves nowhere either, so an extension constrained on one keeps its
    /// grant.
    private func whereClauseMayNameSPIType(_ clause: GenericWhereClauseSyntax?) -> Bool {
        guard let clause else { return false }
        let index = context.fileDeclarationIndex

        // `Self` names the extended type, which Swift allows even when it is SPI
        for name in TypeNameCollector.names(in: clause) where name != "Self" {
            if index.spiNames.contains(name) { return true }
            if !index.declaredNames.contains(name) { return true }
        }
        return false
    }

    // MARK: - onExtension mode (hoist access from members to extension)

    private func visitOnExtension(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        // Only process extensions that don't already have an access level modifier.
        guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }

        // Swift forbids access modifiers on extensions that declare protocol conformance.
        guard node.inheritanceClause == nil else { return DeclSyntax(node) }

        // Check if all members share the same hoistable access level.
        guard let commonAccess = commonMemberAccessLevel(node.memberBlock) else {
            return DeclSyntax(node)
        }

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
            guard keyword == .public || keyword == .package || keyword == .fileprivate else {
                return nil
            }

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

    /// Visits a nested protocol declaration.
    ///
    /// Like every other member visitor, this one does not visit the protocol's children. A
    /// protocol's requirements implicitly have the protocol's own access level, and stating one
    /// explicitly is an error, so the access level has to land on the protocol itself.
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        processExtensionMember(node, declKeywordKeyPath: \.protocolKeyword)
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
            case let .insideExtension(accessKeyword, spiAttributes):
                prepending(
                    spiAttributes,
                    to: applyingAccessModifierIfNone(
                        accessKeyword,
                        to: decl,
                        declKeywordKeyPath: declKeywordKeyPath
                    )
                )
            case let .hoistingFromExtension(accessKeyword):
                removingAccessModifier(
                    accessKeyword,
                    from: decl,
                    declKeywordKeyPath: declKeywordKeyPath
                )
        }
    }

    /// Prepends the given `@_spi` attributes to the front of `decl`'s attribute list, moving the
    /// declaration's leading trivia onto the first attribute so that leading comments, newlines,
    /// and indentation are preserved on the line that now begins with `@_spi`.
    private func prepending(
        _ spiAttributes: [AttributeListSyntax.Element],
        to decl: DeclSyntax
    ) -> DeclSyntax {
        guard !spiAttributes.isEmpty else { return decl }

        let leadingTrivia = decl.leadingTrivia
        guard var attributed = decl.with(\.leadingTrivia, [])
            .asProtocol(WithAttributesSyntax.self)
        else { return decl }

        var attributesToInsert = spiAttributes.map {
            $0.with(\.leadingTrivia, []).with(\.trailingTrivia, [.spaces(1)])
        }
        attributesToInsert[0] = attributesToInsert[0].with(\.leadingTrivia, leadingTrivia)

        var newAttributes = attributed.attributes

        for element in attributesToInsert.reversed() {
            newAttributes.insert(element, at: newAttributes.startIndex)
        }
        attributed.attributes = newAttributes
        return attributed.as(DeclSyntax.self) ?? decl
    }

    /// Adds `modifier` to `decl` if it doesn't already have an explicit access level modifier.
    private func applyingAccessModifierIfNone<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        _ modifier: Keyword,
        to decl: Decl,
        declKeywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
    ) -> DeclSyntax {
        // If there's already an access modifier among the modifier list, bail out.
        guard decl.modifiers.accessLevelModifier == nil else { return DeclSyntax(decl) }

        notesFromRewrittenMembers.append(Finding.Note(
            message: .addModifierToExtensionMember(keyword: TokenSyntax.keyword(modifier).text),
            location: Finding.Location(decl.startLocation(
                converter: context.sourceLocationConverter))))

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

        notesFromRewrittenMembers.append(Finding.Note(
            message: .removeModifierFromExtensionMember(keyword: accessModifier.name.text),
            location: Finding.Location(decl.startLocation(
                converter: context.sourceLocationConverter))))

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

// MARK: - File lookups

/// Collects every type name a syntax node mentions.
private final class TypeNameCollector: SyntaxVisitor {
    private var names: Set<String> = []

    static func names(in node: some SyntaxProtocol) -> Set<String> {
        let collector = TypeNameCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        return collector.names
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .visitChildren
    }
}

fileprivate extension AttributeListSyntax.Element {
    /// Whether this element is an `@_spi` attribute (for example `@_spi(Foo)`).
    var isSPIAttribute: Bool {
        self.as(AttributeSyntax.self)?
            .attributeName.as(IdentifierTypeSyntax.self)?
            .name.text == "_spi"
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
    package enum Placement: String, Codable, Sendable { case onMembers, onExtension }

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
