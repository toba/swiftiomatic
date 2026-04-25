import SwiftSyntax

/// Remove setter access modifiers (`(set)`) that match the property's effective access level.
///
/// `private(set) private var x` is redundant — the property is already entirely `private`,
/// so restricting the setter to `private` adds nothing. Likewise `internal(set) var x` inside
/// an `internal` (or default-internal) type, or `fileprivate(set) fileprivate var x`.
///
/// The rule fires when:
/// 1. Another modifier on the same declaration already supplies the matching access level, OR
/// 2. The `(set)` keyword is `internal` or `fileprivate` and it matches the effective access of
///    the enclosing type (or the file scope, in the `internal` case).
///
/// Lint: A finding is raised at the redundant `(set)` modifier.
///
/// Format: The redundant `(set)` modifier is removed, transferring its leading trivia to the
///         next modifier or the binding specifier.
final class RedundantSetterACL: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .warn) }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard let setMod = setterAccessModifier(in: node.modifiers),
            let setKeyword = setMod.keyword
        else {
            return super.visit(node)
        }

        let getter = getterAccessModifier(in: node.modifiers)

        if let getter, let getKeyword = getter.keyword, setKeyword == getKeyword {
            return removeModifier(setMod, from: node, reason: .matchesGetter)
        }

        // No explicit getter modifier — check the enclosing context for `internal`/`fileprivate`.
        guard getter == nil else { return super.visit(node) }

        switch setKeyword {
        case .internal:
            if enclosingTypeIsEffectively(.internal, around: Syntax(node)) {
                return removeModifier(setMod, from: node, reason: .matchesContext)
            }
        case .fileprivate:
            if enclosingTypeIsEffectively(.fileprivate, around: Syntax(node)) {
                return removeModifier(setMod, from: node, reason: .matchesContext)
            }
        default:
            break
        }

        return super.visit(node)
    }

    // MARK: - Modifier inspection

    private func setterAccessModifier(in modifiers: DeclModifierListSyntax) -> DeclModifierSyntax? {
        modifiers.first { $0.detail?.detail.tokenKind == .identifier("set") }
    }

    private func getterAccessModifier(in modifiers: DeclModifierListSyntax) -> DeclModifierSyntax? {
        modifiers.first { mod in
            guard mod.detail == nil, case .keyword(let kw) = mod.name.tokenKind else {
                return false
            }
            return Self.accessKeywords.contains(kw)
        }
    }

    private static let accessKeywords: Set<Keyword> = [
        .public, .package, .internal, .fileprivate, .private, .open,
    ]

    // MARK: - Rewrite

    private func removeModifier(
        _ target: DeclModifierSyntax,
        from node: VariableDeclSyntax,
        reason: RemovalReason
    ) -> DeclSyntax {
        diagnose(
            .removeRedundantSetterACL(keyword: target.name.text, reason: reason),
            on: target
        )

        var result = node
        let savedLeading = target.leadingTrivia
        let targetID = target.id

        var newModifiers = result.modifiers.filter { $0.id != targetID }
        // If the removed modifier was first, transfer its leading trivia.
        if let firstID = result.modifiers.first?.id, firstID == targetID {
            if newModifiers.first != nil {
                newModifiers[newModifiers.startIndex].leadingTrivia = savedLeading
            } else {
                result.bindingSpecifier.leadingTrivia = savedLeading
            }
        }
        result.modifiers = DeclModifierListSyntax(newModifiers)
        return DeclSyntax(result)
    }

    // MARK: - Context analysis

    /// Returns true when the closest enclosing type's effective access level matches `level`.
    /// - For `.internal`, the type may have no explicit modifier (default-internal),
    ///   or a non-public/non-package modifier where `internal` is the default.
    /// - For `.fileprivate`, the type must explicitly declare `fileprivate`.
    private func enclosingTypeIsEffectively(_ level: Keyword, around node: Syntax) -> Bool {
        var current = node.parent
        while let parent = current {
            if let typeModifiers = typeDeclModifiers(parent) {
                let access = typeModifiers.first { mod in
                    mod.detail == nil
                        && {
                            if case .keyword = mod.name.tokenKind { return true }
                            return false
                        }()
                }
                let keyword: Keyword? = access.flatMap {
                    if case .keyword(let kw) = $0.name.tokenKind { return kw }
                    return nil
                }

                switch level {
                case .internal:
                    // No explicit access modifier means internal by default.
                    return keyword == nil || keyword == .internal
                case .fileprivate:
                    return keyword == .fileprivate
                default:
                    return keyword == level
                }
            }
            current = parent.parent
        }
        // Top-level: file scope is effectively `internal` for unqualified declarations.
        return level == .internal
    }

    private func typeDeclModifiers(_ syntax: Syntax) -> DeclModifierListSyntax? {
        if let cls = syntax.as(ClassDeclSyntax.self) { return cls.modifiers }
        if let str = syntax.as(StructDeclSyntax.self) { return str.modifiers }
        if let enm = syntax.as(EnumDeclSyntax.self) { return enm.modifiers }
        if let act = syntax.as(ActorDeclSyntax.self) { return act.modifiers }
        if let ext = syntax.as(ExtensionDeclSyntax.self) { return ext.modifiers }
        return nil
    }

    // Wrapper to convey reason in the finding without storing extra state.
    fileprivate enum RemovalReason {
        case matchesGetter
        case matchesContext
    }
}

extension DeclModifierSyntax {
    fileprivate var keyword: Keyword? {
        if case .keyword(let kw) = name.tokenKind { return kw }
        return nil
    }
}

extension Finding.Message {
    fileprivate static func removeRedundantSetterACL(
        keyword: String,
        reason: RedundantSetterACL.RemovalReason
    ) -> Finding.Message {
        switch reason {
        case .matchesGetter:
            return "remove redundant '\(keyword)(set)'; it matches the property's access level"
        case .matchesContext:
            return
                "remove redundant '\(keyword)(set)'; it matches the enclosing type's access level"
        }
    }
}
