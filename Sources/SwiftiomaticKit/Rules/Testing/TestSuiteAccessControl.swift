import SwiftSyntax

/// Test methods should be `internal`; helper properties and functions should be `private`.
///
/// In test suites, test methods don't need explicit access control (internal is the default and
/// correct level). Non-test helpers should be `private` since they're only used within the suite.
///
/// Lint: A warning is raised for incorrect access control on test suite members.
///
/// Rewrite: Access control is corrected.
final class TestSuiteAccessControl: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .testing }

    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

    /// Per-file mutable state held in `Context.ruleState`.
    final class State {
        var framework: TestFramework?
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.framework = detectTestFramework(in: node)
    }

    // MARK: - Static transforms

    static func transform(
        _ node: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.ruleState(for: Self.self) { State() }
        guard let framework = state.framework else { return DeclSyntax(node) }
        guard SwiftiomaticKit.isTestSuite(
            name: node.name.text,
            inheritanceClause: node.inheritanceClause,
            modifiers: node.modifiers,
            leadingTrivia: node.leadingTrivia,
            framework: framework
        ) else { return DeclSyntax(node) }
        guard !hasParameterizedInit(node.memberBlock) else { return DeclSyntax(node) }

        var result = node
        result = removePublicModifier(from: result, keyword: \.classKeyword, context: context)
        result = result.with(
            \.memberBlock,
            rewriteMembers(result.memberBlock, framework: framework, context: context)
        )
        return DeclSyntax(result)
    }

    static func transform(
        _ node: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.ruleState(for: Self.self) { State() }
        guard let framework = state.framework else { return DeclSyntax(node) }
        guard SwiftiomaticKit.isTestSuite(
            name: node.name.text,
            inheritanceClause: node.inheritanceClause,
            modifiers: node.modifiers,
            leadingTrivia: node.leadingTrivia,
            framework: framework
        ) else { return DeclSyntax(node) }
        guard !hasParameterizedInit(node.memberBlock) else { return DeclSyntax(node) }

        var result = node
        result = removePublicModifier(from: result, keyword: \.structKeyword, context: context)
        result = result.with(
            \.memberBlock,
            rewriteMembers(result.memberBlock, framework: framework, context: context)
        )
        return DeclSyntax(result)
    }

    // MARK: - Member Rewriting

    private static func rewriteMembers(
        _ memberBlock: MemberBlockSyntax,
        framework: TestFramework,
        context: Context
    ) -> MemberBlockSyntax {
        var newMembers = [MemberBlockItemSyntax]()
        var changed = false

        for member in memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let rewritten = rewriteFunction(funcDecl, framework: framework, context: context)
                if rewritten.description != funcDecl.description {
                    newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
                    changed = true
                    continue
                }
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                let rewritten = rewriteProperty(varDecl, context: context)
                if rewritten.description != varDecl.description {
                    newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
                    changed = true
                    continue
                }
            } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                let rewritten = removeExplicitACL(
                    from: initDecl,
                    keyword: \.initKeyword,
                    context: context
                )
                if rewritten.description != initDecl.description {
                    newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
                    changed = true
                    continue
                }
            }
            newMembers.append(member)
        }

        guard changed else { return memberBlock }
        return memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers))
    }

    private static func rewriteFunction(
        _ funcDecl: FunctionDeclSyntax,
        framework: TestFramework,
        context: Context
    ) -> FunctionDeclSyntax {
        let modifiers = funcDecl.modifiers

        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) { return funcDecl }
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { return funcDecl }
        if funcDecl.attributes.attribute(named: "objc") != nil { return funcDecl }
        if hasDisabledPrefix(funcDecl.name.text) { return funcDecl }

        let isTest = isTestFunction(funcDecl, framework: framework)

        if isTest {
            if framework == .xcTest,
                modifiers.contains(where: {
                    $0.name.tokenKind == .keyword(.private)
                        || $0.name.tokenKind == .keyword(.fileprivate)
                })
            {
                return funcDecl
            }
            return removeExplicitACL(from: funcDecl, keyword: \.funcKeyword, context: context)
        } else {
            if modifiers.contains(where: {
                $0.name.tokenKind == .keyword(.private)
                    || $0.name.tokenKind == .keyword(.fileprivate)
            }) {
                return funcDecl
            }
            return ensurePrivate(on: funcDecl, keyword: \.funcKeyword, context: context)
        }
    }

    private static func rewriteProperty(
        _ varDecl: VariableDeclSyntax,
        context: Context
    ) -> VariableDeclSyntax {
        let modifiers = varDecl.modifiers
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { return varDecl }
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) { return varDecl }
        if varDecl.attributes.attribute(named: "objc") != nil { return varDecl }
        if modifiers.contains(where: {
            $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
        }) { return varDecl }

        return ensurePrivate(on: varDecl, keyword: \.bindingSpecifier, context: context)
    }

    // MARK: - Test Function Detection

    private static func isTestFunction(
        _ funcDecl: FunctionDeclSyntax,
        framework: TestFramework
    ) -> Bool {
        if funcDecl.hasAttribute("Test", inModule: "Testing") { return true }
        if framework == .xcTest {
            return funcDecl.name.text.hasPrefix("test")
                && funcDecl.signature.parameterClause.parameters.isEmpty
                && funcDecl.signature.returnClause == nil
        }
        return false
    }

    // MARK: - Access Control Helpers

    private static let aclKeywords: Set<Keyword> =
        [.public, .private, .fileprivate, .internal, .package]

    private static func removePublicModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let publicMod = decl.modifiers.first(where: { $0.name.tokenKind == .keyword(.public) })
        else { return decl }

        Self.diagnose(.removePublicFromTestType, on: publicMod.name, context: context)
        return decl.removingModifiers([.public], keyword: keyword)
    }

    private static func removeExplicitACL<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let aclMod = decl.modifiers.first(where: {
            if case .keyword(let kw) = $0.name.tokenKind {
                return Self.aclKeywords.contains(kw) && kw != .internal
            }
            return false
        }) else { return decl }

        Self.diagnose(.removeACLFromTestMethod, on: aclMod.name, context: context)

        guard case .keyword(let kwToRemove) = aclMod.name.tokenKind else { return decl }
        return decl.removingModifiers([kwToRemove], keyword: keyword)
    }

    private static func ensurePrivate<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        on decl: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        if let aclMod = decl.modifiers.first(where: {
            if case .keyword(let kw) = $0.name.tokenKind { return Self.aclKeywords.contains(kw) }
            return false
        }) {
            Self.diagnose(.makePrivate, on: aclMod.name, context: context)
            var result = decl
            var newModifiers = Array(result.modifiers)
            if let idx = newModifiers.firstIndex(where: { $0.id == aclMod.id }) {
                newModifiers[idx] = newModifiers[idx].with(
                    \.name,
                    .keyword(
                        .private,
                        leadingTrivia: aclMod.name.leadingTrivia,
                        trailingTrivia: aclMod.name.trailingTrivia
                    )
                )
            }
            result.modifiers = DeclModifierListSyntax(newModifiers)
            return result
        }

        Self.diagnose(.makePrivate, on: decl[keyPath: keyword], context: context)
        var result = decl
        var pm = DeclModifierSyntax(name: .keyword(.private, trailingTrivia: .space))
        pm.leadingTrivia = result[keyPath: keyword].leadingTrivia
        result[keyPath: keyword] = result[keyPath: keyword].with(\.leadingTrivia, [])
        var newModifiers = Array(result.modifiers)
        newModifiers.insert(pm, at: 0)
        result.modifiers = DeclModifierListSyntax(newModifiers)
        return result
    }
}

extension Finding.Message {
    fileprivate static let removePublicFromTestType: Finding.Message =
        "remove 'public' from test suite type"
    fileprivate static let removeACLFromTestMethod: Finding.Message =
        "remove explicit access control from test method"
    fileprivate static let makePrivate: Finding.Message =
        "make test helper 'private'"
}
