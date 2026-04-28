import SwiftSyntax

/// Compact-pipeline merge of all `ImportDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv` (sub-issue `np6-piu`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
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
    if context.shouldFormat(ModifiersOnSameLine.self, node: nodeSyntax) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ImportDeclSyntax.self) {
            result = next
        }
    }

    // PreferSwiftTesting (replaces `import XCTest` with `import Testing`)
    if context.shouldFormat(PreferSwiftTesting.self, node: nodeSyntax) {
        if let next = PreferSwiftTesting.transform(
            result, parent: parent, context: context
        ).as(ImportDeclSyntax.self) {
            result = next
        }
    }

    // RedundantSwiftTestingSuite — record `import Testing` for later use by
    // the rule's struct/class/enum/actor visits. Helpers in
    // `RedundantSwiftTestingSuiteHelpers.swift`.
    if context.shouldFormat(RedundantSwiftTestingSuite.self, node: nodeSyntax) {
        redundantSwiftTestingSuiteVisitImport(result, context: context)
    }

    // NoForceTry — record `import Testing` for later test-context detection.
    // Helpers in `Rewrites/Exprs/NoForceTryHelpers.swift`.
    if context.shouldFormat(NoForceTry.self, node: nodeSyntax) {
        noForceTryVisitImport(result, context: context)
    }

    // NoForceUnwrap — record `import Testing` for later test-context detection.
    // Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: nodeSyntax) {
        noForceUnwrapVisitImport(result, context: context)
    }

    return result
}
