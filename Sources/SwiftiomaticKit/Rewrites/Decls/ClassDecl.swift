import SwiftSyntax

/// Compact-pipeline merge of all `ClassDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteClassDecl(
    _ node: ClassDeclSyntax,
    context: Context
) -> ClassDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // PreferStaticOverClassFunc
    if context.shouldFormat(PreferStaticOverClassFunc.self, node: Syntax(result)) {
        if let next = PreferStaticOverClassFunc.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // PreferSwiftTesting
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(result)) {
        if let next = PreferSwiftTesting.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // SimplifyGenericConstraints
    if context.shouldFormat(SimplifyGenericConstraints.self, node: Syntax(result)) {
        if let next = SimplifyGenericConstraints.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // StaticStructShouldBeEnum
    if context.shouldFormat(StaticStructShouldBeEnum.self, node: Syntax(result)) {
        if let next = StaticStructShouldBeEnum.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // TestSuiteAccessControl
    if context.shouldFormat(TestSuiteAccessControl.self, node: Syntax(result)) {
        if let next = TestSuiteAccessControl.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // ValidateTestCases
    if context.shouldFormat(ValidateTestCases.self, node: Syntax(result)) {
        if let next = ValidateTestCases.transform(
            result, parent: parent, context: context
        ).as(ClassDeclSyntax.self) {
            result = next
        }
    }

    // RedundantFinal — strips redundant `final` from members of a `final`
    // class. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantFinal.swift`.
    if context.shouldFormat(RedundantFinal.self, node: Syntax(result)) {
        result = applyRedundantFinal(result, context: context)
    }

    // Unported rules — tracked for sub-issue 4f. Audit-only:
    //   - RedundantSwiftTestingSuite (instance state)
    //   - NoForceTry / NoForceUnwrap (file-level pre-scan, instance state)
    //   - WrapMultilineStatementBraces (no static transform)
    _ = context.shouldFormat(RedundantSwiftTestingSuite.self, node: Syntax(result))
    _ = context.shouldFormat(NoForceTry.self, node: Syntax(result))
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
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
