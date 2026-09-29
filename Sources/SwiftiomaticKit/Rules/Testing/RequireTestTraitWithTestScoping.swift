import Foundation
import SwiftSyntax

/// Add `TestTrait` to a `SuiteTrait` that conforms to `TestScoping` .
///
/// The Swift Testing runner applies a suite trait to every test in the suite as well as to the
/// suite. When a `SuiteTrait` provides a scope through `TestScoping` but does not conform to
/// `TestTrait` , the runner crashes when it applies the trait to a test. See the Swift Testing
/// notes on custom traits.
///
/// The rule checks structs, classes, enums, actors and extensions. It matches a simple name or a
/// name qualified with a module, such as `Testing.SuiteTrait` .
///
/// Lint: A type or extension whose inheritance clause names `TestScoping` and `SuiteTrait` but not
/// `TestTrait` raises a warning.
///
/// Rewrite: `TestTrait` is inserted in the inheritance clause after `SuiteTrait` .
final class RequireTestTraitWithTestScoping: StaticFormatRule<BasicRuleValue>,
    @unchecked Sendable
{
    static let rewriteOrder = 1235

    override class var group: ConfigurationGroup? { .testing }

    static func transform(
        _ node: StructDeclSyntax,
        original: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(fixed(node, original: original, context: context))
    }

    static func transform(
        _ node: ClassDeclSyntax,
        original: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(fixed(node, original: original, context: context))
    }

    static func transform(
        _ node: EnumDeclSyntax,
        original: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(fixed(node, original: original, context: context))
    }

    static func transform(
        _ node: ActorDeclSyntax,
        original: ActorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(fixed(node, original: original, context: context))
    }

    static func transform(
        _ node: ExtensionDeclSyntax,
        original: ExtensionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(fixed(node, original: original, context: context))
    }

    // MARK: - Helpers

    /// Returns the declaration with `TestTrait` inserted, or the declaration unchanged when it does
    /// not qualify.
    private static func fixed<D: DeclGroupSyntax>(
        _ node: D,
        original: D,
        context: Context
    ) -> D {
        guard let clause = node.inheritanceClause,
              let items = insertingTestTrait(into: clause.inheritedTypes) else { return node }

        // Diagnose on the source position, which the original node keeps.
        let anchor = original.inheritanceClause?.inheritedTypes
            .first { simpleName(of: $0.type) == "SuiteTrait" }
        Self.diagnose(.addTestTrait, on: anchor, context: context)

        var result = node
        result.inheritanceClause = clause.with(\.inheritedTypes, items)
        return result
    }

    /// Returns the list with `TestTrait` inserted after `SuiteTrait` , or `nil` when the list does
    /// not name both `SuiteTrait` and `TestScoping` or already names `TestTrait` .
    private static func insertingTestTrait(
        into list: InheritedTypeListSyntax
    ) -> InheritedTypeListSyntax? {
        var items = Array(list)
        let names = items.map { simpleName(of: $0.type) }

        guard names.contains("TestScoping"),
              !names.contains("TestTrait"),
              let suiteIndex = names.firstIndex(of: "SuiteTrait") else { return nil }

        let suite = items[suiteIndex]
        let testTrait = TypeSyntax(IdentifierTypeSyntax(name: .identifier("TestTrait")))
        var inserted = InheritedTypeSyntax(type: testTrait)

        if let comma = suite.trailingComma {
            // A later item follows. Copy the comma and the layout of that item.
            inserted.trailingComma = comma
            inserted.leadingTrivia = items[suiteIndex + 1].leadingTrivia
        } else {
            // `SuiteTrait` closes the list. It takes a comma, and the new item takes the trivia
            // before the opening brace.
            let previousComma = suiteIndex > 0 ? items[suiteIndex - 1].trailingComma : nil
            inserted.leadingTrivia = suite.leadingTrivia
            inserted.trailingTrivia = suite.trailingTrivia
            items[suiteIndex] = suite
                .with(\.trailingTrivia, [])
                .with(\.trailingComma, previousComma ?? .commaToken(trailingTrivia: .space))
        }
        items.insert(inserted, at: suiteIndex + 1)
        return InheritedTypeListSyntax(items)
    }

    /// The last name component of a type, so `Testing.SuiteTrait` reads as `SuiteTrait` .
    private static func simpleName(of type: TypeSyntax) -> String? {
        if let identifier = type.as(IdentifierTypeSyntax.self) { return identifier.name.text }
        if let member = type.as(MemberTypeSyntax.self) { return member.name.text }
        return nil
    }
}

fileprivate extension Finding.Message {
    static let addTestTrait: Finding.Message =
        "add 'TestTrait' to this 'SuiteTrait' that conforms to 'TestScoping'; the test runner crashes without it"
}
