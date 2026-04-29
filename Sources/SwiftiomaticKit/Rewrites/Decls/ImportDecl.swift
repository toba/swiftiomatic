import SwiftSyntax

/// Compact-pipeline merge of all `ImportDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
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
    // the rule's struct/class/enum/actor visits.
    if context.shouldFormat(RedundantSwiftTestingSuite.self, node: nodeSyntax) {
        RedundantSwiftTestingSuite.visitImport(result, context: context)
    }

    // NoForceTry — record `import Testing` for later test-context detection.
    if context.shouldFormat(NoForceTry.self, node: nodeSyntax) {
        NoForceTry.visitImport(result, context: context)
    }

    // NoForceUnwrap — record `import Testing` for later test-context detection.
    // Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: nodeSyntax) {
        NoForceUnwrap.visitImport(result, context: context)
    }

    return result
}
