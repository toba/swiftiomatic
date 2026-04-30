import SwiftSyntax

/// Compact-pipeline merge of all `ClassDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
/// Returns `DeclSyntax` so `StaticStructShouldBeEnum` can widen a final class
/// to an `EnumDeclSyntax`. All preceding rules preserve the `ClassDeclSyntax`
/// kind; the kind-widening rule runs last and short-circuits any further work.
func rewriteClassDecl(
    _ node: ClassDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeclSyntax {
    var result = node

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        ModifierOrder.self, to: &result,
        parent: parent, transform: ModifierOrder.transform
    )

    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )

    context.applyRewrite(
        PreferFinalClasses.self, to: &result,
        parent: parent, transform: PreferFinalClasses.transform
    )

    context.applyRewrite(
        PreferStaticOverClassFunc.self, to: &result,
        parent: parent, transform: PreferStaticOverClassFunc.transform
    )

    context.applyRewrite(
        PreferSwiftTesting.self, to: &result,
        parent: parent, transform: PreferSwiftTesting.transform
    )

    context.applyRewrite(
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )

    context.applyRewrite(
        RedundantObjc.self, to: &result,
        parent: parent, transform: RedundantObjc.transform
    )

    context.applyRewrite(
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, transform: SimplifyGenericConstraints.transform
    )

    context.applyRewrite(
        TestSuiteAccessControl.self, to: &result,
        parent: parent, transform: TestSuiteAccessControl.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    context.applyRewrite(
        ValidateTestCases.self, to: &result,
        parent: parent, transform: ValidateTestCases.transform
    )

    // RedundantFinal — strips redundant `final` from members of a `final`
    // class. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantFinal.swift`.
    if context.shouldRewrite(RedundantFinal.self, at: Syntax(result)) {
        result = applyRedundantFinal(result, context: context)
    }

    // RedundantSwiftTestingSuite — strip a no-argument `@Suite` attribute
    // when `import Testing` is present.
    if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(result)) {
        result = RedundantSwiftTestingSuite.removeSuite(
            from: result, keyword: \.classKeyword, context: context
        )
    }

    // NoForceTry — XCTestCase scope tracking happens in the generator-emitted
    // `willEnter(_ ClassDecl, context:)` / `didExit(_ ClassDecl, context:)`
    // hooks; no transform work needed here.

    // NoForceUnwrap — XCTestCase scope tracking via generator-emitted
    // `willEnter(_ ClassDecl)` / `didExit(_ ClassDecl)` hooks; no transform
    // work needed here.

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    // StaticStructShouldBeEnum — runs last because it can widen a final class
    // to an `EnumDeclSyntax`. Subsequent rules in this function would all
    // expect a `ClassDeclSyntax`, so this must come after them.
    if context.shouldRewrite(StaticStructShouldBeEnum.self, at: Syntax(result)) {
        return StaticStructShouldBeEnum.transform(result, parent: parent, context: context)
    }

    return DeclSyntax(result)
}

// MARK: - Support

private func applyRedundantFinal(
    _ node: ClassDeclSyntax,
    context: Context
) -> ClassDeclSyntax {
    guard node.modifiers.contains(anyOf: [.final]) else { return node }

    var result = node
    result.memberBlock.members = MemberBlockItemListSyntax(
        result.memberBlock.members.map { member in
            guard let cleaned = removeFinalFromMember(member.decl, context: context) else {
                return member
            }
            var item = member
            item.decl = cleaned
            return item
        }
    )
    return result
}

private func removeFinalFromMember(_ decl: DeclSyntax, context: Context) -> DeclSyntax? {
    guard let mods = decl.modifiersOrNil,
          let finalModifier = mods.first(where: { $0.name.tokenKind == .keyword(.final) })
    else { return nil }
    RedundantFinal.diagnose(.removeFinal, on: finalModifier, context: context)
    return decl.removingModifiers([.final])
}

extension Finding.Message {
    fileprivate static let removeFinal: Finding.Message =
        "remove 'final'; members of a final class are implicitly final"
}
