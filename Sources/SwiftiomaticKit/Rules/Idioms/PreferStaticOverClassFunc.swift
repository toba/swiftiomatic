import SwiftSyntax

/// Prefer `static` over `class` for type members of `final` classes.
///
/// In a `final` class, `class func` and `class var` are equivalent to `static func` and
/// `static var` since the class cannot be subclassed. Using `static` makes the intent clearer.
///
/// Members carrying `override` are skipped: the parent's signature uses `class` so the override
/// chain remains open; switching to `static` would close that chain even though this class is
/// final, and may break the override under generic specialization.
///
/// Lint: If a `class` modifier is found on a non-override member of a `final` class, a warning is raised.
///
/// Rewrite: The `class` modifier is replaced with `static`.
final class PreferStaticOverClassFunc: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ClassDeclSyntax.self)
        guard visited.modifiers.contains(anyOf: [.final]) else {
            return DeclSyntax(visited)
        }

        var result = visited
        result.memberBlock.members = MemberBlockItemListSyntax(
            result.memberBlock.members.map { member in
                guard let classModifier = classModifier(in: member.decl) else { return member }
                diagnose(.preferStatic, on: classModifier)
                var item = member
                item.decl = replaceClassWithStatic(in: member.decl)
                return item
            })
        return DeclSyntax(result)
    }

    private func classModifier(in decl: DeclSyntax) -> DeclModifierSyntax? {
        guard let withModifiers = decl.asProtocol(WithModifiersSyntax.self) else { return nil }
        if withModifiers.modifiers.contains(.override) {
            return nil
        }
        return withModifiers.modifiers.first { $0.name.tokenKind == .keyword(.class) }
    }

    private func replaceClassWithStatic(in decl: DeclSyntax) -> DeclSyntax {
        func replace<D: DeclSyntaxProtocol & WithModifiersSyntax>(_ node: D) -> DeclSyntax {
            var result = node
            result.modifiers = DeclModifierListSyntax(
                node.modifiers.map { mod in
                    guard mod.name.tokenKind == .keyword(.class) else { return mod }
                    return mod.with(
                        \.name,
                        .keyword(
                            .static,
                            leadingTrivia: mod.name.leadingTrivia,
                            trailingTrivia: mod.name.trailingTrivia
                        ))
                })
            return DeclSyntax(result)
        }
        if let funcDecl = decl.as(FunctionDeclSyntax.self) { return replace(funcDecl) }
        if let varDecl = decl.as(VariableDeclSyntax.self) { return replace(varDecl) }
        if let subscriptDecl = decl.as(SubscriptDeclSyntax.self) { return replace(subscriptDecl) }
        return decl
    }
}

extension Finding.Message {
    fileprivate static let preferStatic: Finding.Message =
        "use 'static' instead of 'class'; this class is final"
}
