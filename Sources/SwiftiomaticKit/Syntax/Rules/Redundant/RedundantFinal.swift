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
        if let d = decl.as(FunctionDeclSyntax.self), d.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: d.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(d.removingModifiers([.final], keyword: \.funcKeyword))
        }
        if let d = decl.as(VariableDeclSyntax.self), d.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: d.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(d.removingModifiers([.final], keyword: \.bindingSpecifier))
        }
        if let d = decl.as(SubscriptDeclSyntax.self), d.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: d.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(d.removingModifiers([.final], keyword: \.subscriptKeyword))
        }
        if let d = decl.as(ClassDeclSyntax.self), d.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: d.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(d.removingModifiers([.final], keyword: \.classKeyword))
        }
        if let d = decl.as(InitializerDeclSyntax.self), d.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: d.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(d.removingModifiers([.final], keyword: \.initKeyword))
        }
        if let d = decl.as(TypeAliasDeclSyntax.self), d.modifiers.contains(anyOf: [.final]) {
            diagnose(.removeFinal, on: d.modifiers.first { $0.name.tokenKind == .keyword(.final) })
            return DeclSyntax(d.removingModifiers([.final], keyword: \.typealiasKeyword))
        }
        return nil
    }
}

extension Finding.Message {
    fileprivate static let removeFinal: Finding.Message =
        "remove 'final'; members of a final class are implicitly final"
}
