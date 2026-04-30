import SwiftSyntax

/// Remove `@Suite` attributes that have no arguments, since they are inferred by the Swift Testing
/// framework.
///
/// `@Suite` with no arguments (or empty parentheses) is redundant — Swift Testing automatically
/// discovers test suites without explicit annotation. Only `@Suite` with arguments like
/// `@Suite(.serialized)` or `@Suite("Display Name")` should be kept.
///
/// Lint: A warning is raised when `@Suite` or `@Suite()` is used without arguments.
///
/// Rewrite: The redundant `@Suite` attribute is removed.
final class RedundantSwiftTestingSuite: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context`.
    final class State {
        var importsTesting = false
    }

    /// Track an `import Testing` so later type-decl visits know the macro is in
    /// scope. Called from `rewriteImportDecl`.
    static func visitImport(_ node: ImportDeclSyntax, context: Context) {
        if node.path.first?.name.text == "Testing" {
            context.redundantSwiftTestingSuiteState.importsTesting = true
        }
    }

    /// Remove a no-argument `@Suite` attribute from the given type declaration.
    /// `keyword` points at the type's primary keyword (e.g. `\.classKeyword`)
    /// so its leading trivia can absorb the attribute's trivia when no other
    /// attributes remain.
    static func removeSuite<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
        from node: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        let state = context.redundantSwiftTestingSuiteState
        guard state.importsTesting,
              let attr = node.attributes.attribute(named: "Suite"),
              isRedundantSuiteAttribute(attr)
        else {
            return node
        }

        Self.diagnose(.removeRedundantSuite, on: attr, context: context)

        var result = node
        let savedTrivia = attr.leadingTrivia
        result.attributes.remove(named: "Suite")
        if result.attributes.isEmpty {
            result[keyPath: keyword].leadingTrivia = savedTrivia
        }
        return result
    }

    private static func isRedundantSuiteAttribute(_ attr: AttributeSyntax) -> Bool {
        if attr.arguments == nil { return true }
        if case let .argumentList(args) = attr.arguments, args.isEmpty { return true }
        return false
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantSuite: Finding.Message =
        "remove redundant '@Suite' attribute; it is inferred by Swift Testing"
}
