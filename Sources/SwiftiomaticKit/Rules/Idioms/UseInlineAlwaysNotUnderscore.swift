import SwiftSyntax

/// Replace `@inline(__always)` with `@inline(always)` .
///
/// `@inline(__always)` is the old, underscore-prefixed spelling. It only suggests inlining.
/// `@inline(always)` guarantees inlining since Swift 6.3.
///
/// `@inline(always)` changes how an overridable declaration can dispatch, so the rewrite applies
/// only to a declaration that nothing can override. That is a free or local function, a member of a
/// struct, enum, actor or extension, a `static` / `final` / `private` / `fileprivate` member of a
/// class, or any member of a `final` class.
///
/// Lint: Using `@inline(__always)` raises a warning.
///
/// Rewrite: The attribute becomes `@inline(always)` . An overridable class member keeps its text.
final class UseInlineAlwaysNotUnderscore: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 623

    override class var group: ConfigurationGroup? { .idioms }

    static func transform(
        _ node: AttributeSyntax,
        original: AttributeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> AttributeSyntax {
        guard let name = node.attributeName.as(IdentifierTypeSyntax.self),
            name.name.text == "inline",
            let arguments = node.arguments,
            let underscored = arguments.tokens(viewMode: .sourceAccurate).first(where: {
                $0.text == "__always"
            }),
            arguments.trimmedDescription == "__always" else { return node }

        Self.diagnose(.useInlineAlways, on: node.atSign, context: context)

        guard !isOverridable(original) else { return node }

        let renamed = AlwaysRenamer(target: underscored.id).rewrite(arguments)
        guard let newArguments = renamed.as(AttributeSyntax.Arguments.self) else { return node }
        return node.with(\.arguments, newArguments)
    }

    /// Whether the declaration that carries `attribute` can be overridden.
    ///
    /// An accessor takes the answer from the property or subscript that owns it.
    private static func isOverridable(_ attribute: AttributeSyntax) -> Bool {
        guard var decl = attribute.parent?.parent else { return true }

        if decl.is(AccessorDeclSyntax.self) {
            guard let owner = decl.ancestors.first(where: {
                $0.is(VariableDeclSyntax.self) || $0.is(SubscriptDeclSyntax.self)
            }) else { return true }
            decl = owner
        }

        // A declaration that is not a type member is a free or local function.
        guard decl.parent?.is(MemberBlockItemSyntax.self) == true else { return false }

        guard let container = decl.parent?.parent?.parent?.parent else { return true }

        if container.is(StructDeclSyntax.self) || container.is(EnumDeclSyntax.self)
            || container.is(ActorDeclSyntax.self) || container.is(ExtensionDeclSyntax.self) {
            return false
        }
        guard let classDecl = container.as(ClassDeclSyntax.self) else { return true }

        if classDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) }) {
            return false
        }

        let sealing: Set<Keyword> = [.static, .final, .private, .fileprivate]
        let modifiers = decl.asProtocol((any WithModifiersSyntax).self)?.modifiers ?? []
        return !modifiers.contains { modifier in
            guard case let .keyword(keyword) = modifier.name.tokenKind else { return false }
            return sealing.contains(keyword)
        }
    }
}

/// Renames the one `__always` token in an attribute's arguments to `always` , keeping its trivia.
private final class AlwaysRenamer: SyntaxRewriter {
    let target: SyntaxIdentifier

    init(target: SyntaxIdentifier) {
        self.target = target
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard token.id == target else { return token }
        return token.with(\.tokenKind, .identifier("always"))
    }
}

private extension Syntax {
    /// The chain of parents, nearest first.
    var ancestors: some Sequence<Syntax> { sequence(first: self, next: { $0.parent }).dropFirst() }
}

fileprivate extension Finding.Message {
    static var useInlineAlways: Finding.Message {
        "replace '@inline(__always)' with '@inline(always)', which guarantees inlining since Swift 6.3"
    }
}
