import SwiftSyntax

/// Spike (`eti-yt2`): a single `SyntaxRewriter` whose `visit(_:)` overrides apply multiple
/// node-local transformations in one tree walk.
///
/// The three rules below were chosen as a representative cross-section of node-local rewrites:
/// - `RedundantBreak` — list/statement-level (`SwitchCaseSyntax`).
/// - `NoBacktickedSelf` — pattern-level (`OptionalBindingConditionSyntax`).
/// - `RedundantNilInit` — declaration-level (`VariableDeclSyntax`).
///
/// They share no node types, so combining their logic in one walk is straightforward and
/// demonstrates the architectural premise: per-node work is small; the dominant cost in
/// today's pipeline is starting 137 separate full-tree walks. One walk × N visits per node ≈
/// the cost of one walk.
///
/// Findings are intentionally omitted — the spike measures rewrite throughput only. The
/// production combined rewriter (`ddi-wtv`) will route diagnostics through `Context`.
package final class CombinedRewriter: SyntaxRewriter {
    override package func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        let visited = super.visit(node)
        let statements = visited.statements

        guard statements.count > 1 else { return visited }
        guard let lastItem = statements.last,
              let breakStmt = lastItem.item.as(StmtSyntax.self)?.as(BreakStmtSyntax.self),
              breakStmt.label == nil
        else { return visited }

        let newStatements = CodeBlockItemListSyntax(statements.dropLast())
        return visited.with(\.statements, newStatements)
    }

    override package func visit(
        _ node: OptionalBindingConditionSyntax
    ) -> OptionalBindingConditionSyntax {
        let visited = super.visit(node)

        guard let identifierPattern = visited.pattern.as(IdentifierPatternSyntax.self),
              case let .identifier(text) = identifierPattern.identifier.tokenKind,
              text == "`self`",
              let initializer = visited.initializer,
              let declRef = initializer.value.as(DeclReferenceExprSyntax.self),
              declRef.baseName.tokenKind == .keyword(.self)
        else { return visited }

        var result = visited
        let newIdentifier = identifierPattern.identifier.with(\.tokenKind, .identifier("self"))
        result.pattern = PatternSyntax(identifierPattern.with(\.identifier, newIdentifier))
        return result
    }

    override package func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard let varDecl = visited.as(VariableDeclSyntax.self) else { return visited }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else { return visited }
        if varDecl.parent?.parent?.is(ProtocolDeclSyntax.self) == true { return visited }

        var bindings = varDecl.bindings
        var didChange = false

        for (index, binding) in bindings.enumerated() {
            guard let initializer = binding.initializer,
                  initializer.value.is(NilLiteralExprSyntax.self),
                  Self.isOptionalType(binding.typeAnnotation?.type)
            else { continue }

            var newBinding = binding
            newBinding.initializer = nil
            if var typeAnnotation = newBinding.typeAnnotation {
                typeAnnotation.trailingTrivia = initializer.value.trailingTrivia
                newBinding.typeAnnotation = typeAnnotation
            }
            bindings = bindings.with(
                \.[bindings.index(bindings.startIndex, offsetBy: index)], newBinding)
            didChange = true
        }

        guard didChange else { return visited }
        var result = varDecl
        result.bindings = bindings
        return DeclSyntax(result)
    }

    private static func isOptionalType(_ type: TypeSyntax?) -> Bool {
        guard let type else { return false }
        if type.is(OptionalTypeSyntax.self) { return true }
        if type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) { return true }
        if let identifierType = type.as(IdentifierTypeSyntax.self),
           identifierType.name.text == "Optional",
           identifierType.genericArgumentClause != nil
        {
            return true
        }
        return false
    }
}
