import SwiftSyntax

/// Remove setter access modifiers ( `(set)` ) that match the property's effective access level.
///
/// `private(set) private var x` is redundant — the property is already entirely `private` , so
/// restricting the setter to `private` adds nothing. Likewise `internal(set) var x` inside an
/// `internal` (or default-internal) type, or `fileprivate(set) fileprivate var x` .
///
/// The rule fires when:
/// 1. Another modifier on the same declaration already supplies the matching access level, OR
/// 2. The `(set)` keyword is `internal` or `fileprivate` and it matches the effective access of the
///    enclosing type (or the file scope, in the `internal` case).
///
/// Lint: A finding is raised at the redundant `(set)` modifier.
///
/// Rewrite: The redundant `(set)` modifier is removed, transferring its leading trivia to the next
/// modifier or the binding specifier.
final class RedundantSetterACL: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    static func transform(
        _ node: VariableDeclSyntax,
        original _: VariableDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let setMod = setterAccessModifier(in: node.modifiers),
              let setKeyword = setMod.keyword else { return DeclSyntax(node) }

        let getter = getterAccessModifier(in: node.modifiers)

        if let getter, let getKeyword = getter.keyword, setKeyword == getKeyword {
            return removeModifier(setMod, from: node, reason: .matchesGetter, context: context)
        }

        // No explicit getter modifier — check the enclosing context for `internal` / `fileprivate`
        // .
        guard getter == nil else { return DeclSyntax(node) }

        switch setKeyword {
            case .internal:
                if enclosingTypeIsEffectively(.internal, parent: parent) {
                    return removeModifier(
                        setMod, from: node, reason: .matchesContext, context: context)
                }
            case .fileprivate:
                if enclosingTypeIsEffectively(.fileprivate, parent: parent) {
                    return removeModifier(
                        setMod, from: node, reason: .matchesContext, context: context)
                }
            default: break
        }

        return DeclSyntax(node)
    }

    // MARK: - Modifier inspection

    private static func setterAccessModifier(
        in modifiers: DeclModifierListSyntax
    ) -> DeclModifierSyntax? {
        modifiers.first { $0.detail?.detail.tokenKind == .identifier("set") }
    }

    private static func getterAccessModifier(
        in modifiers: DeclModifierListSyntax
    ) -> DeclModifierSyntax? {
        modifiers.first { mod in
            guard mod.detail == nil, case let .keyword(kw) = mod.name.tokenKind else {
                return false
            }
            return Self.accessKeywords.contains(kw)
        }
    }

    private static let accessKeywords: Set<Keyword> = [
        .public, .package, .internal, .fileprivate, .private, .open,
    ]

    // MARK: - Rewrite

    private static func removeModifier(
        _ target: DeclModifierSyntax,
        from node: VariableDeclSyntax,
        reason: RemovalReason,
        context: Context
    ) -> DeclSyntax {
        Self.diagnose(
            .removeRedundantSetterACL(keyword: target.name.text, reason: reason),
            on: target,
            context: context
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

    /// Returns true when the closest enclosing type's effective access level matches `level` .
    /// - For `.internal` , the type may have no explicit modifier (default-internal), or a
    ///   non-public/non-package modifier where `internal` is the default.
    /// - For `.fileprivate` , the type must explicitly declare `fileprivate` .
    private static func enclosingTypeIsEffectively(_ level: Keyword, parent: Syntax?) -> Bool {
        var current = parent

        while let p = current {
            if let typeModifiers = typeDeclModifiers(p) {
                let access = typeModifiers.first { mod in
                    mod.detail == nil
                        && {
                            if case .keyword = mod.name.tokenKind { return true }
                            return false
                        }()
                }
                let keyword: Keyword? = access.flatMap {
                    if case let .keyword(kw) = $0.name.tokenKind { return kw }
                    return nil
                }

                switch level {
                    case .internal: return keyword == nil || keyword == .internal
                    case .fileprivate: return keyword == .fileprivate
                    default: return keyword == level
                }
            }
            current = p.parent
        }
        // Top-level: file scope is effectively `internal` for unqualified declarations.
        return level == .internal
    }

    private static func typeDeclModifiers(_ syntax: Syntax) -> DeclModifierListSyntax? {
        if let cls = syntax.as(ClassDeclSyntax.self) { return cls.modifiers }
        if let str = syntax.as(StructDeclSyntax.self) { return str.modifiers }
        if let enm = syntax.as(EnumDeclSyntax.self) { return enm.modifiers }
        if let act = syntax.as(ActorDeclSyntax.self) { return act.modifiers }
        if let ext = syntax.as(ExtensionDeclSyntax.self) { return ext.modifiers }
        return nil
    }

    // Wrapper to convey reason in the finding without storing extra state.
    fileprivate enum RemovalReason { case matchesGetter, matchesContext }
}

fileprivate extension DeclModifierSyntax {
    var keyword: Keyword? {
        if case let .keyword(kw) = name.tokenKind { return kw }
        return nil
    }
}

fileprivate extension Finding.Message {
    static func removeRedundantSetterACL(
        keyword: String,
        reason: RedundantSetterACL.RemovalReason
    ) -> Finding.Message {
        switch reason {
            case .matchesGetter:
                "remove redundant '\(keyword)(set)'; it matches the property's access level"
            case .matchesContext:

                "remove redundant '\(keyword)(set)'; it matches the enclosing type's access level"
        }
    }
}
