import SwiftSyntax

/// A declaration's access level must not exceed its enclosing nominal parent's effective access
/// level. For example, a `public` method inside a `private` struct can never be called from outside
/// that struct, so the wider modifier is misleading.
///
/// The rule traverses upward to the nearest enclosing struct/class/actor/enum (or its enclosing
/// extension) and compares effective access levels.
///
/// Lint: A finding is raised on the over-permissive ACL modifier.
///
/// Rewrite: `open` is downgraded to `public` when the parent is not also `open` ; otherwise the
/// redundant modifier is removed entirely.
final class ACLConsistency: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .access }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
        super.visit(
            Self.transform(node, parent: Syntax(node).parent, context: context)
        )
    }

    static func transform(
        _ node: DeclModifierSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclModifierSyntax {
        guard node.isHigherACLThanParent else { return node }

        Self.diagnose(.lowerACLThanParent, on: node, context: context)

        if node.name.tokenKind == .keyword(.open) {
            var replacement = node
            replacement.name = .keyword(
                .public,
                leadingTrivia: node.leadingTrivia,
                trailingTrivia: node.trailingTrivia
            )
            return replacement
        }

        // Replace the modifier with an empty identifier so the surrounding list can be flattened by
        // the parent decl visitor; preserve leading trivia.
        var replacement = node
        replacement.name = .identifier("", leadingTrivia: node.leadingTrivia, trailingTrivia: [])
        replacement.detail = nil
        return replacement
    }
}

fileprivate extension Finding.Message {
    static let lowerACLThanParent: Finding.Message =
        "declaration should not have a higher access level than its enclosing parent"
}

// MARK: - Helpers

fileprivate extension DeclModifierSyntax {
    var isHigherACLThanParent: Bool {
        guard let nearestNominalParent = parent?.nearestNominalParent() else {
            return false
        }

        let parentModifiers = nearestNominalParent.declModifiers
        switch name.tokenKind {
            case .keyword(.internal) where parentModifiers?.containsPrivateOrFileprivate == true:
                return true
            case .keyword(.internal) where parentModifiers?.effectiveAccessKeyword == nil:
                guard let nominalExtension =
                    nearestNominalParent.nearestNominalExtensionDeclParent()
                else {
                    return false
                }
                return nominalExtension.declModifiers?.containsPrivateOrFileprivate == true
            case .keyword(.public)
                where parentModifiers?.containsPrivateOrFileprivate == true
                || parentModifiers?.contains(.internal) == true:
                return true
            case .keyword(.public) where parentModifiers?.effectiveAccessKeyword == nil:
                guard let nominalExtension =
                    nearestNominalParent.nearestNominalExtensionDeclParent()
                else {
                    return true
                }
                return nominalExtension.declModifiers?.contains(.public) == false
                    && nominalExtension.declModifiers?.contains(.open) == false
            case .keyword(.open) where parentModifiers?.contains(.open) == false: return true
            default: return false
        }
    }
}

fileprivate extension SyntaxProtocol {
    func nearestNominalParent() -> Syntax? {
        guard let parent else { return nil }
        return parent.isNominalTypeDecl ? parent : parent.nearestNominalParent()
    }

    func nearestNominalExtensionDeclParent() -> Syntax? {
        guard let parent, !parent.isNominalTypeDecl else { return nil }
        return parent.isExtensionDecl
            ? parent
            : parent.nearestNominalExtensionDeclParent()
    }
}

fileprivate extension Syntax {
    var isNominalTypeDecl: Bool {
        `is`(StructDeclSyntax.self)
            || `is`(ClassDeclSyntax.self)
            || `is`(ActorDeclSyntax.self)
            || `is`(EnumDeclSyntax.self)
    }

    var isExtensionDecl: Bool { `is`(ExtensionDeclSyntax.self) }

    var declModifiers: DeclModifierListSyntax? {
        asProtocol((any WithModifiersSyntax).self)?.modifiers
    }
}

fileprivate extension DeclModifierListSyntax {
    var containsPrivateOrFileprivate: Bool { contains(anyOf: [.private, .fileprivate]) }

    /// Like `accessLevelModifier` but also recognizes `open` as an access level.
    var effectiveAccessKeyword: Keyword? {
        for mod in self {
            guard mod.detail == nil, case let .keyword(kw) = mod.name.tokenKind else { continue }
            switch kw {
                case .public, .internal, .fileprivate, .private, .package, .open: return kw
                default: continue
            }
        }
        return nil
    }
}
