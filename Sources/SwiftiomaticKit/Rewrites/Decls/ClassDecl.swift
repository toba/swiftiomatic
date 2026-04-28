import SwiftSyntax

/// Compact-pipeline merge of all `ClassDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
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

    applyRule(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, context: context,
        transform: DocCommentsPrecedeModifiers.transform
    )

    applyRule(
        ModifierOrder.self, to: &result,
        parent: parent, context: context,
        transform: ModifierOrder.transform
    )

    applyRule(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, context: context,
        transform: ModifiersOnSameLine.transform
    )

    applyRule(
        PreferStaticOverClassFunc.self, to: &result,
        parent: parent, context: context,
        transform: PreferStaticOverClassFunc.transform
    )

    applyRule(
        PreferSwiftTesting.self, to: &result,
        parent: parent, context: context,
        transform: PreferSwiftTesting.transform
    )

    applyRule(
        RedundantAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: RedundantAccessControl.transform
    )

    applyRule(
        RedundantObjc.self, to: &result,
        parent: parent, context: context,
        transform: RedundantObjc.transform
    )

    applyRule(
        SimplifyGenericConstraints.self, to: &result,
        parent: parent, context: context,
        transform: SimplifyGenericConstraints.transform
    )

    applyRule(
        TestSuiteAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: TestSuiteAccessControl.transform
    )

    applyRule(
        TripleSlashDocComments.self, to: &result,
        parent: parent, context: context,
        transform: TripleSlashDocComments.transform
    )

    applyRule(
        ValidateTestCases.self, to: &result,
        parent: parent, context: context,
        transform: ValidateTestCases.transform
    )

    // RedundantFinal — strips redundant `final` from members of a `final`
    // class. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantFinal.swift`.
    if context.shouldFormat(RedundantFinal.self, node: Syntax(result)) {
        result = applyRedundantFinal(result, context: context)
    }

    // RedundantSwiftTestingSuite — strip a no-argument `@Suite` attribute
    // when `import Testing` is present. Helpers in
    // `RedundantSwiftTestingSuiteHelpers.swift`.
    if context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result)) {
        result = redundantSwiftTestingSuiteRemoveSuite(
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
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

    // StaticStructShouldBeEnum — runs last because it can widen a final class
    // to an `EnumDeclSyntax`. Subsequent rules in this function would all
    // expect a `ClassDeclSyntax`, so this must come after them.
    if context.shouldFormat(StaticStructShouldBeEnum.self, node: Syntax(result)) {
        return StaticStructShouldBeEnum.transform(result, parent: parent, context: context)
    }

    return DeclSyntax(result)
}

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
    if let funcDecl = decl.as(FunctionDeclSyntax.self),
       funcDecl.modifiers.contains(anyOf: [.final])
    {
        RedundantFinal.diagnose(
            .removeFinal,
            on: funcDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) },
            context: context
        )
        return DeclSyntax(funcDecl.removingModifiers([.final], keyword: \.funcKeyword))
    }
    if let varDecl = decl.as(VariableDeclSyntax.self),
       varDecl.modifiers.contains(anyOf: [.final])
    {
        RedundantFinal.diagnose(
            .removeFinal,
            on: varDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) },
            context: context
        )
        return DeclSyntax(varDecl.removingModifiers([.final], keyword: \.bindingSpecifier))
    }
    if let subscriptDecl = decl.as(SubscriptDeclSyntax.self),
       subscriptDecl.modifiers.contains(anyOf: [.final])
    {
        RedundantFinal.diagnose(
            .removeFinal,
            on: subscriptDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) },
            context: context
        )
        return DeclSyntax(subscriptDecl.removingModifiers([.final], keyword: \.subscriptKeyword))
    }
    if let classDecl = decl.as(ClassDeclSyntax.self),
       classDecl.modifiers.contains(anyOf: [.final])
    {
        RedundantFinal.diagnose(
            .removeFinal,
            on: classDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) },
            context: context
        )
        return DeclSyntax(classDecl.removingModifiers([.final], keyword: \.classKeyword))
    }
    if let initDecl = decl.as(InitializerDeclSyntax.self),
       initDecl.modifiers.contains(anyOf: [.final])
    {
        RedundantFinal.diagnose(
            .removeFinal,
            on: initDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) },
            context: context
        )
        return DeclSyntax(initDecl.removingModifiers([.final], keyword: \.initKeyword))
    }
    if let typeAliasDecl = decl.as(TypeAliasDeclSyntax.self),
       typeAliasDecl.modifiers.contains(anyOf: [.final])
    {
        RedundantFinal.diagnose(
            .removeFinal,
            on: typeAliasDecl.modifiers.first { $0.name.tokenKind == .keyword(.final) },
            context: context
        )
        return DeclSyntax(typeAliasDecl.removingModifiers([.final], keyword: \.typealiasKeyword))
    }
    return nil
}

extension Finding.Message {
    fileprivate static let removeFinal: Finding.Message =
        "remove 'final'; members of a final class are implicitly final"
}
