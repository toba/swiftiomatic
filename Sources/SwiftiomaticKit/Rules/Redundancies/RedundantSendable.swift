import SwiftSyntax

/// Remove explicit `Sendable` conformance from non-public structs and enums.
///
/// In Swift 6, the compiler automatically infers `Sendable` for structs and enums whose stored
/// properties/associated values are all `Sendable` , as long as the type is not `public` .
/// Explicitly declaring `: Sendable` on these types is redundant.
///
/// This rule only flags non-public structs and enums. Classes, actors, and public types are not
/// checked because their `Sendable` conformance is either not inferred or must be explicit for ABI
/// stability.
///
/// Lint: If a redundant `Sendable` conformance is found, a lint warning is raised.
///
/// Rewrite: The redundant `Sendable` conformance is removed from the inheritance clause.
final class RedundantSendable: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ visited: StructDeclSyntax,
        original _: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isPublicOrPackage(visited.modifiers),
              let inheritanceClause = visited.inheritanceClause,
              let inherited = inheritanceClause.inherited(named: "Sendable") else {
            return DeclSyntax(visited)
        }
        Self.diagnose(.removeRedundantSendable, on: inherited, context: context)
        var result = visited
        let newClause = inheritanceClause.removing(named: "Sendable")
        result.inheritanceClause = newClause
        if newClause == nil { result.memberBlock.leftBrace.leadingTrivia = .space }
        return DeclSyntax(result)
    }

    static func transform(
        _ visited: EnumDeclSyntax,
        original _: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isPublicOrPackage(visited.modifiers),
              let inheritanceClause = visited.inheritanceClause,
              let inherited = inheritanceClause.inherited(named: "Sendable") else {
            return DeclSyntax(visited)
        }
        Self.diagnose(.removeRedundantSendable, on: inherited, context: context)
        var result = visited
        let newClause = inheritanceClause.removing(named: "Sendable")
        result.inheritanceClause = newClause
        if newClause == nil { result.memberBlock.leftBrace.leadingTrivia = .space }
        return DeclSyntax(result)
    }

    private static func isPublicOrPackage(_ modifiers: DeclModifierListSyntax) -> Bool {
        guard let accessModifier = modifiers.accessLevelModifier,
              case let .keyword(keyword) = accessModifier.name.tokenKind else { return false }
        return keyword == .public || keyword == .package
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantSendable: Finding.Message =
        "remove explicit 'Sendable'; it is inferred for non-public structs and enums"
}
