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
    context: Context
) -> ImportDeclSyntax {
    var result = node
    let parent: Syntax? = nil  // ImportDecl rules don't need parent context.
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

    // Unported file-level pre-scan rules (NoForceTry, NoForceUnwrap,
    // RedundantSwiftTestingSuite) use instance state in the legacy path.
    // Their compact equivalents need `Context.ruleState` infrastructure;
    // tracked in 4f for the test-state migration. Audit-only `shouldFormat`
    // calls preserved so rule-mask gating stays consistent.
    _ = context.shouldFormat(NoForceTry.self, node: nodeSyntax)
    _ = context.shouldFormat(NoForceUnwrap.self, node: nodeSyntax)
    _ = context.shouldFormat(RedundantSwiftTestingSuite.self, node: nodeSyntax)

    return result
}
