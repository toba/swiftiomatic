import SwiftSyntax

/// Remove `@ViewBuilder` when the body is a single expression.
///
/// `@ViewBuilder` is unnecessary on computed properties and functions that return a single view
/// expression, since Swift can infer the return type without the result builder.
///
/// This rule flags `@ViewBuilder` on:
/// - Computed properties with a single-expression getter
/// - Functions with a single-expression body
///
/// It does NOT flag `@ViewBuilder` on:
/// - Closures (parameters)
/// - Bodies with multiple statements, `if/else` , `switch` , or `ForEach`
/// - Protocol requirements
///
/// Lint: If a redundant `@ViewBuilder` is found, a lint warning is raised.
///
/// Rewrite: The redundant `@ViewBuilder` attribute is removed.
final class RedundantViewBuilder: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Identifies this rule as being opt-in. This rule requires SwiftUI context and may produce
    /// false positives in codebases that use custom result builders named `ViewBuilder` .
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ node: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let viewBuilderAttr = node.attributes.attribute(named: "ViewBuilder") else {
            return DeclSyntax(node)
        }

        // Must be a computed property with an accessor block.
        guard node.bindings.count == 1,
              let binding = node.bindings.first,
              let accessorBlock = binding.accessorBlock else { return DeclSyntax(node) }

        // Check for single-expression getter.
        guard case let .getter(body) = accessorBlock.accessors,
              isSingleExpression(body) else { return DeclSyntax(node) }

        Self.diagnose(.removeRedundantViewBuilder, on: viewBuilderAttr, context: context)
        var result = node
        let savedTrivia = viewBuilderAttr.leadingTrivia
        result.attributes = node.attributes.removing(named: "ViewBuilder")
        // Transfer the removed attribute's leading trivia to the next token.
        if result.attributes.isEmpty { result.bindingSpecifier.leadingTrivia = savedTrivia }
        return DeclSyntax(result)
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let viewBuilderAttr = node.attributes.attribute(named: "ViewBuilder") else {
            return DeclSyntax(node)
        }

        // Must have a body (not a protocol requirement).
        guard let body = node.body else { return DeclSyntax(node) }

        guard isSingleExpression(body.statements) else { return DeclSyntax(node) }

        Self.diagnose(.removeRedundantViewBuilder, on: viewBuilderAttr, context: context)
        var result = node
        let savedTrivia = viewBuilderAttr.leadingTrivia
        result.attributes = node.attributes.removing(named: "ViewBuilder")
        // Transfer the removed attribute's leading trivia to the next token.
        if result.attributes.isEmpty {
            if result.modifiers.first != nil {
                result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
            } else {
                result.funcKeyword.leadingTrivia = savedTrivia
            }
        }
        return DeclSyntax(result)
    }

    /// Returns `true` if the code block contains exactly one expression statement.
    private static func isSingleExpression(_ statements: CodeBlockItemListSyntax) -> Bool {
        guard statements.count == 1 else { return false }
        guard let item = statements.first else { return false }
        // Must be a single expression, not a declaration or control flow statement.
        return item.item.is(ExprSyntax.self)
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantViewBuilder: Finding.Message =
        "remove '@ViewBuilder'; single-expression body does not need a result builder"
}
