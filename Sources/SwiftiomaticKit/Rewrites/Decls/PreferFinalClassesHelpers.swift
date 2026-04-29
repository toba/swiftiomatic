import SwiftSyntax

/// File-level state for the inlined `PreferFinalClasses` rule. Populated by
/// `static willEnter(_ SourceFileSyntax, context:)` (see `PreferFinalClasses`)
/// before any descendants are visited, so the per-class transform can ask
/// whether a class is subclassed within the same file.
final class PreferFinalClassesState {
    var subclassedNames: Set<String> = []
}

/// Pre-scan the file for class names that appear in inheritance clauses, so a
/// later `ClassDecl` visit can leave those classes non-final.
func preferFinalClassesCollect(
    _ node: SourceFileSyntax,
    context: Context
) {
    let state = context.ruleState(for: PreferFinalClasses.self) {
        PreferFinalClassesState()
    }
    collectSubclassedNamesRecursive(in: Syntax(node), into: &state.subclassedNames)
}

private func collectSubclassedNamesRecursive(in node: Syntax, into names: inout Set<String>) {
    if let classDecl = node.as(ClassDeclSyntax.self),
       let inheritanceClause = classDecl.inheritanceClause
    {
        for inherited in inheritanceClause.inheritedTypes {
            if let identType = inherited.type.as(IdentifierTypeSyntax.self) {
                names.insert(identType.name.text)
            }
        }
    }
    for child in node.children(viewMode: .sourceAccurate) {
        collectSubclassedNamesRecursive(in: child, into: &names)
    }
}

/// Transform the class declaration: add `final` and convert any `open`
/// members to `public` unless the class is exempt (already final, `open`,
/// "Base"-named, comment mentions subclassing, or subclassed in this file).
func applyPreferFinalClasses(
    _ node: ClassDeclSyntax,
    context: Context
) -> ClassDeclSyntax {
    if node.modifiers.contains(.final) { return node }
    if node.modifiers.contains(.open) { return node }
    if node.name.text.contains("Base") { return node }
    if commentMentionsSubclassing(node) { return node }

    let state = context.ruleState(for: PreferFinalClasses.self) {
        PreferFinalClassesState()
    }
    if state.subclassedNames.contains(node.name.text) { return node }

    PreferFinalClasses.diagnose(.preferFinalClass, on: node.classKeyword, context: context)

    var result = node

    var finalModifier = DeclModifierSyntax(name: .keyword(.final, trailingTrivia: .space))

    if result.modifiers.isEmpty {
        finalModifier.leadingTrivia = result.classKeyword.leadingTrivia
        result.classKeyword.leadingTrivia = []
    }

    result.modifiers.append(finalModifier)

    result.memberBlock.members = convertOpenToPublic(in: result.memberBlock.members)

    return result
}

private func commentMentionsSubclassing(_ node: ClassDeclSyntax) -> Bool {
    let text = node.leadingTrivia.pieces
        .compactMap { piece -> String? in
            switch piece {
                case let .docLineComment(text), let .docBlockComment(text),
                    let .lineComment(text),
                    let .blockComment(text):
                    text
                default: nil
            }
        }
        .joined()
        .lowercased()

    return text.contains("base") || text.contains("subclass")
}

private func convertOpenToPublic(
    in members: MemberBlockItemListSyntax
) -> MemberBlockItemListSyntax {
    MemberBlockItemListSyntax(
        members.map { member in
            guard let modified = replaceOpenModifier(in: member.decl) else { return member }
            var result = member
            result.decl = modified
            return result
        })
}

private func replaceOpenModifier(in decl: DeclSyntax) -> DeclSyntax? {
    if var funcDecl = decl.as(FunctionDeclSyntax.self),
       let modifiers = openToPublic(funcDecl.modifiers)
    {
        funcDecl.modifiers = modifiers
        return DeclSyntax(funcDecl)
    }
    if var varDecl = decl.as(VariableDeclSyntax.self),
       let modifiers = openToPublic(varDecl.modifiers)
    {
        varDecl.modifiers = modifiers
        return DeclSyntax(varDecl)
    }
    if var subscriptDecl = decl.as(SubscriptDeclSyntax.self),
       let modifiers = openToPublic(subscriptDecl.modifiers)
    {
        subscriptDecl.modifiers = modifiers
        return DeclSyntax(subscriptDecl)
    }
    if var initDecl = decl.as(InitializerDeclSyntax.self),
       let modifiers = openToPublic(initDecl.modifiers)
    {
        initDecl.modifiers = modifiers
        return DeclSyntax(initDecl)
    }
    if var typeAliasDecl = decl.as(TypeAliasDeclSyntax.self),
       let modifiers = openToPublic(typeAliasDecl.modifiers)
    {
        typeAliasDecl.modifiers = modifiers
        return DeclSyntax(typeAliasDecl)
    }
    return nil
}

private func openToPublic(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax? {
    guard modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) })
    else { return nil }
    return DeclModifierListSyntax(
        modifiers.map { mod in
            guard mod.name.tokenKind == .keyword(.open) else { return mod }
            return mod.with(
                \.name,
                .keyword(
                    .public,
                    leadingTrivia: mod.name.leadingTrivia,
                    trailingTrivia: mod.name.trailingTrivia
                ))
        })
}

extension Finding.Message {
    fileprivate static let preferFinalClass: Finding.Message =
        "prefer 'final class' unless designed for subclassing"
}
