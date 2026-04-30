import SwiftSyntax

/// Compact-pipeline merge of all `ImportDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// `willEnter`/`didExit` hooks (none currently registered for `ImportDecl`)
/// would be emitted by the generator before/after `super.visit`, not from
/// inside this function.
func rewriteImportDecl(
    _ node: ImportDeclSyntax,
    parent: Syntax?,
    context: Context
) -> ImportDeclSyntax {
    var result = node
    let nodeSyntax = Syntax(node)

    // ModifiersOnSameLine
    if context.shouldRewrite(ModifiersOnSameLine.self, at: nodeSyntax) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ImportDeclSyntax.self) {
            result = next
        }
    }

    // PreferSwiftTesting (replaces `import XCTest` with `import Testing`)
    if context.shouldRewrite(PreferSwiftTesting.self, at: nodeSyntax) {
        if let next = PreferSwiftTesting.transform(
            result, parent: parent, context: context
        ).as(ImportDeclSyntax.self) {
            result = next
        }
    }

    // RedundantSwiftTestingSuite — record `import Testing` for later use by
    // the rule's struct/class/enum/actor visits.
    if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: nodeSyntax) {
        RedundantSwiftTestingSuite.visitImport(result, context: context)
    }

    // NoForceTry — record `import Testing` for later test-context detection.
    if context.shouldRewrite(NoForceTry.self, at: nodeSyntax) {
        NoForceTry.visitImport(result, context: context)
    }

    // NoForceUnwrap — record `import Testing` for later test-context detection.
    // Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldRewrite(NoForceUnwrap.self, at: nodeSyntax) {
        NoForceUnwrap.visitImport(result, context: context)
    }

    return result
}
