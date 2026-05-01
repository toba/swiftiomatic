import SwiftSyntax

/// Remove `@objc` when it is already implied by another attribute.
///
/// The `@objc` attribute is automatically implied by `@IBAction` , `@IBOutlet` , `@IBDesignable` ,
/// `@IBInspectable` , `@NSManaged` , and `@GKInspectable` . Writing `@objc` alongside any of these
/// is redundant.
///
/// This rule does NOT flag `@objc` when it specifies an explicit Objective-C name (e.g.
/// `@objc(mySelector:)` ), since that provides information beyond just marking the declaration as
/// ObjC-visible.
///
/// Lint: If a redundant `@objc` is found, a lint warning is raised.
///
/// Rewrite: The redundant `@objc` attribute is removed.
final class RedundantObjc: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Attributes that imply `@objc` .
    private static let implyingAttributes: Set<String> = [
        "IBAction",
        "IBOutlet",
        "IBDesignable",
        "IBInspectable",
        "NSManaged",
        "GKInspectable",
    ]

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    static func transform(
        _ node: VariableDeclSyntax,
        original _: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    static func transform(
        _ node: ClassDeclSyntax,
        original _: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    static func transform(
        _ node: StructDeclSyntax,
        original _: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    static func transform(
        _ node: EnumDeclSyntax,
        original _: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    static func transform(
        _ node: SubscriptDeclSyntax,
        original _: SubscriptDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    static func transform(
        _ node: InitializerDeclSyntax,
        original _: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax { DeclSyntax(removeRedundantObjc(from: node, context: context)) }

    private static func removeRedundantObjc<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
        from decl: Decl,
        context: Context
    ) -> Decl {
        guard let objcAttr = decl.attributes.attribute(named: "objc") else { return decl }
        // `@objc(selector:)` provides an explicit name — not redundant.
        guard objcAttr.arguments == nil else { return decl }
        // Must have at least one attribute that implies `@objc` .
        guard decl.attributes.contains(where: { element in
            guard case let .attribute(attr) = element,
                  let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
                return false
            }
            return Self.implyingAttributes.contains(name)
        }) else { return decl }

        Self.diagnose(.removeRedundantObjc, on: objcAttr, context: context)

        var result = decl
        result.attributes = decl.attributes.removing(named: "objc")
        return result
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantObjc: Finding.Message =
        "remove redundant '@objc'; it is implied by another attribute"
}
