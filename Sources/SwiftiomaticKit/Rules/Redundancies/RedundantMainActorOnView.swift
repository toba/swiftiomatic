import SwiftSyntax

/// Remove `@MainActor` from SwiftUI `View`, `App`, and `Scene` conformers.
///
/// SwiftUI implies `@MainActor` isolation on these protocols, so writing the
/// attribute explicitly is redundant.
///
/// Detection is conservative: an unqualified inheritance name `View`, `App`,
/// or `Scene` matches. A custom protocol of the same name will be falsely
/// flagged — match the philosophy of the rule library: prefer false positives
/// over missed issues. Disable per-rule if needed.
///
/// Lint: A redundant `@MainActor` raises a warning.
///
/// Rewrite: The `@MainActor` attribute is removed.
final class RedundantMainActorOnView: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    private static let impliedMainActorProtocols: Set<String> = ["View", "App", "Scene"]

    static func transform(
        _ node: StructDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let mainActorAttr = redundantMainActorAttribute(node) else { return DeclSyntax(node) }
        Self.diagnose(.removeRedundantMainActor, on: mainActorAttr, context: context)
        var result = node
        let savedTrivia = mainActorAttr.leadingTrivia
        result.attributes = node.attributes.removing(named: "MainActor")
        if result.attributes.isEmpty {
            if result.modifiers.first != nil {
                result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
            } else {
                result.structKeyword.leadingTrivia = savedTrivia
            }
        }
        return DeclSyntax(result)
    }

    static func transform(
        _ node: ClassDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let mainActorAttr = redundantMainActorAttribute(node) else { return DeclSyntax(node) }
        Self.diagnose(.removeRedundantMainActor, on: mainActorAttr, context: context)
        var result = node
        let savedTrivia = mainActorAttr.leadingTrivia
        result.attributes = node.attributes.removing(named: "MainActor")
        if result.attributes.isEmpty {
            if result.modifiers.first != nil {
                result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
            } else {
                result.classKeyword.leadingTrivia = savedTrivia
            }
        }
        return DeclSyntax(result)
    }

    static func transform(
        _ node: EnumDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let mainActorAttr = redundantMainActorAttribute(node) else { return DeclSyntax(node) }
        Self.diagnose(.removeRedundantMainActor, on: mainActorAttr, context: context)
        var result = node
        let savedTrivia = mainActorAttr.leadingTrivia
        result.attributes = node.attributes.removing(named: "MainActor")
        if result.attributes.isEmpty {
            if result.modifiers.first != nil {
                result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
            } else {
                result.enumKeyword.leadingTrivia = savedTrivia
            }
        }
        return DeclSyntax(result)
    }

    private static func redundantMainActorAttribute(_ decl: some DeclSyntaxProtocol & WithAttributesSyntax) -> AttributeSyntax? {
        guard let attr = decl.attributes.attribute(named: "MainActor") else { return nil }
        guard inherits(decl, fromAnyOf: impliedMainActorProtocols) else { return nil }
        return attr
    }

    private static func inherits(_ decl: some DeclSyntaxProtocol, fromAnyOf names: Set<String>) -> Bool {
        let inheritance: InheritanceClauseSyntax?
        if let s = decl.as(StructDeclSyntax.self) {
            inheritance = s.inheritanceClause
        } else if let c = decl.as(ClassDeclSyntax.self) {
            inheritance = c.inheritanceClause
        } else if let e = decl.as(EnumDeclSyntax.self) {
            inheritance = e.inheritanceClause
        } else {
            return false
        }
        guard let inheritance else { return false }
        return inheritance.inheritedTypes.contains { entry in
            entry.type.as(IdentifierTypeSyntax.self).map { names.contains($0.name.text) } ?? false
        }
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantMainActor: Finding.Message =
        "remove redundant '@MainActor'; SwiftUI 'View', 'App', and 'Scene' are already main-actor-isolated"
}
