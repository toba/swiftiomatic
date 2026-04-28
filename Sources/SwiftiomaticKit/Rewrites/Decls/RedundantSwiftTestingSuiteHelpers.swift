import SwiftSyntax

/// Shared helpers for the inlined `RedundantSwiftTestingSuite` rule. The rule
/// needs file-level state (`importsTesting`) to know whether `@Suite` is in
/// scope. State lives on `Context` via `ruleState(for:)`. See
/// `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSwiftTestingSuite.swift`
/// for the legacy implementation.

private final class RedundantSwiftTestingSuiteState {
    var importsTesting = false
}

/// Track an `import Testing` so later type-decl visits know the macro is in
/// scope. Called from `rewriteImportDecl`.
func redundantSwiftTestingSuiteVisitImport(
    _ node: ImportDeclSyntax,
    context: Context
) {
    if node.path.first?.name.text == "Testing" {
        let state = context.ruleState(for: RedundantSwiftTestingSuite.self) {
            RedundantSwiftTestingSuiteState()
        }
        state.importsTesting = true
    }
}

/// Remove a no-argument `@Suite` attribute from the given type declaration.
/// `keyword` points at the type's primary keyword (e.g. `\.classKeyword`)
/// so its leading trivia can absorb the attribute's trivia when no other
/// attributes remain.
func redundantSwiftTestingSuiteRemoveSuite<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
    from node: Decl,
    keyword: WritableKeyPath<Decl, TokenSyntax>,
    context: Context
) -> Decl {
    let state = context.ruleState(for: RedundantSwiftTestingSuite.self) {
        RedundantSwiftTestingSuiteState()
    }
    guard state.importsTesting,
          let attr = node.attributes.attribute(named: "Suite"),
          isRedundantSuiteAttribute(attr)
    else {
        return node
    }

    RedundantSwiftTestingSuite.diagnose(.removeRedundantSuite, on: attr, context: context)

    var result = node
    let savedTrivia = attr.leadingTrivia
    result.attributes.remove(named: "Suite")
    if result.attributes.isEmpty {
        result[keyPath: keyword].leadingTrivia = savedTrivia
    }
    return result
}

private func isRedundantSuiteAttribute(_ attr: AttributeSyntax) -> Bool {
    if attr.arguments == nil { return true }
    if case let .argumentList(args) = attr.arguments, args.isEmpty { return true }
    return false
}

extension Finding.Message {
    fileprivate static let removeRedundantSuite: Finding.Message =
        "remove redundant '@Suite' attribute; it is inferred by Swift Testing"
}
