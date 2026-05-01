import SwiftSyntax

/// Remove redundant `final` from members of `final` classes.
///
/// When a class is declared `final` , all its members are implicitly final. Adding `final` to
/// individual members is redundant.
///
/// Lint: If a `final` modifier is found on a member of a `final` class, a warning is raised.
///
/// Rewrite: The redundant `final` modifier is removed.
final class RedundantFinal: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    /// Strip `final` from members of a `final` class. Called from
    /// `CompactSyntaxRewriter.visit(_: ClassDeclSyntax)` .
    static func apply(_ node: ClassDeclSyntax, context: Context) -> ClassDeclSyntax {
        guard node.modifiers.contains(anyOf: [.final]) else { return node }

        var result = node
        result.memberBlock.members = MemberBlockItemListSyntax(
            result.memberBlock.members.map { member in
                guard let cleaned = removeFinalFromMember(member.decl, context: context) else {
                    return member
                }
                var item = member
                item.decl = cleaned
                return item
            }
        )
        return result
    }

    private static func removeFinalFromMember(
        _ decl: DeclSyntax,
        context: Context
    ) -> DeclSyntax? {
        // A nested class is a distinct type; the outer class's finality doesn't prevent subclassing
        // of nested classes, so `final` is meaningful here.
        if decl.is(ClassDeclSyntax.self) { return nil }
        guard let mods = decl.modifiersOrNil,
              let finalModifier = mods.first(where: { $0.name.tokenKind == .keyword(.final) })
        else { return nil }
        Self.diagnose(.removeFinal, on: finalModifier, context: context)
        return decl.removingModifiers([.final])
    }
}

fileprivate extension Finding.Message {
    static let removeFinal: Finding.Message =
        "remove 'final'; members of a final class are implicitly final"
}
