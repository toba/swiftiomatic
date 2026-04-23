import SwiftSyntax

/// Remove redundant `final` from members of `final` classes.
///
/// When a class is declared `final`, all its members are implicitly final.
/// Adding `final` to individual members is redundant.
///
/// Lint: If a `final` modifier is found on a member of a `final` class, a warning is raised.
///
/// Format: The redundant `final` modifier is removed.
final class RedundantFinal: RewriteSyntaxRule<BasicRuleValue> {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node).cast(ClassDeclSyntax.self)
        guard visited.modifiers.contains(anyOf: [.final]) else {
            return DeclSyntax(visited)
        }

        var result = visited
        result.memberBlock.members = MemberBlockItemListSyntax(
            result.memberBlock.members.map { member in
                guard let cleaned = removeFinal(from: member.decl) else { return member }
                var item = member
                item.decl = cleaned
                return item
            })
        return DeclSyntax(result)
    }

    private func removeFinal(from decl: DeclSyntax) -> DeclSyntax? {
        if let funcDecl = decl.as(FunctionDeclSyntax.self), funcDecl.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: funcDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(funcDecl.removingModifiers([.final], keyword: \.funcKeyword))
        }
        if let varDecl = decl.as(VariableDeclSyntax.self), varDecl.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: varDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(varDecl.removingModifiers([.final], keyword: \.bindingSpecifier))
        }
        if let subscriptDecl = decl.as(SubscriptDeclSyntax.self), subscriptDecl.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: subscriptDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(subscriptDecl.removingModifiers([.final], keyword: \.subscriptKeyword))
        }
        if let classDecl = decl.as(ClassDeclSyntax.self), classDecl.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: classDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(classDecl.removingModifiers([.final], keyword: \.classKeyword))
        }
        if let initDecl = decl.as(InitializerDeclSyntax.self), initDecl.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: initDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(initDecl.removingModifiers([.final], keyword: \.initKeyword))
        }
        if let typeAliasDecl = decl.as(TypeAliasDeclSyntax.self), typeAliasDecl.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: typeAliasDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(typeAliasDecl.removingModifiers([.final], keyword: \.typealiasKeyword))
        }
        return nil
    }
}

extension Finding.Message {
    fileprivate static let removeFinal: Finding.Message =
        "remove 'final'; members of a final class are implicitly final"
}
