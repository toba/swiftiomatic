import SwiftSyntax

/// Test methods should be `internal` ; helper properties and functions should be `private` .
///
/// In test suites, test methods don't need explicit access control (internal is the default and
/// correct level). Non-test helpers should be `private` since they're only used within the suite.
///
/// Lint: A warning is raised for incorrect access control on test suite members.
///
/// Rewrite: Access control is corrected.
final class RequireSuiteAccessControl: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .testing }

    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        var framework: TestFramework?
        /// Protocols declared in this file, keyed by protocol name.
        var protocols: [String: ProtocolInfo] = [:]
    }

    /// A protocol declared in the file under format. Holds the member names it requires and the
    /// names of the protocols it inherits.
    struct ProtocolInfo {
        let requirements: Set<String>
        let inherited: [String]
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.testSuiteAccessControlState
        state.framework = detectTestFramework(in: node)
        // Every transform returns on a nil framework, so the file holds no test suite and the
        // protocol walk has no reader.
        state.protocols = state.framework == nil ? [:] : collectProtocols(in: node)
    }

    private static func collectProtocols(in node: SourceFileSyntax) -> [String: ProtocolInfo] {
        let collector = ProtocolCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        return collector.protocols
    }

    /// Records every protocol declared in the file, at any nesting level.
    private final class ProtocolCollector: SyntaxVisitor {
        var protocols: [String: ProtocolInfo] = [:]

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            var requirements = Set<String>()

            for member in node.memberBlock.members {
                if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                    for binding in varDecl.bindings {
                        if let ident = binding.pattern.as(IdentifierPatternSyntax.self) {
                            requirements.insert(ident.identifier.text)
                        }
                    }
                } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                    requirements.insert(funcDecl.name.text)
                }
            }

            var inherited = [String]()
            if let clause = node.inheritanceClause {
                for inheritedType in clause.inheritedTypes {
                    inherited.append(RequireSuiteAccessControl.baseName(of: inheritedType.type))
                }
            }

            protocols[node.name.text] = ProtocolInfo(
                requirements: requirements,
                inherited: inherited
            )
            return .visitChildren
        }
    }

    // MARK: - Protocol Witnesses

    /// The member names a type may not narrow to `private` .
    ///
    /// A member that witnesses a protocol requirement is read from outside the type, so the
    /// compiler rejects `private` on it.
    enum WitnessGuard {
        /// Every conformance resolves to a protocol in this file, or requires no member.
        case names(Set<String>)
        /// A conformance is declared outside this file, so its requirements are unknown.
        case unknown

        /// Returns `true` when a member with the given name can witness a requirement.
        ///
        /// Pass `nil` for a binding pattern that carries no identifier, such as a tuple pattern.
        /// A named requirement never matches one, so only `.unknown` blocks it.
        func blocks(_ name: String?) -> Bool {
            switch self {
            case let .names(names): name.map(names.contains) ?? false
            case .unknown: true
            }
        }
    }

    /// Conformances that add no member requirement. `XCTestCase` is a class, and a member that
    /// overrides one of its methods carries `override` , which this rule already skips.
    private static let requirementFreeConformances: Set<String> = [
        "Sendable", "AnyObject", "Any", "XCTestCase",
    ]

    private static func baseName(of type: TypeSyntax) -> String {
        if let identifier = type.as(IdentifierTypeSyntax.self) { return identifier.name.text }
        if let member = type.as(MemberTypeSyntax.self) { return member.name.text }
        return type.trimmedDescription
    }

    /// Resolves the conformances of a type to the member names its witnesses may use.
    ///
    /// Returns `.unknown` as soon as one conformance names a type this file does not declare.
    private static func witnessGuard(
        for inheritanceClause: InheritanceClauseSyntax?,
        state: State
    ) -> WitnessGuard {
        guard let inheritanceClause else { return .names([]) }

        var names = Set<String>()
        var pending = inheritanceClause.inheritedTypes.map { baseName(of: $0.type) }
        var seen = Set<String>()

        while let name = pending.popLast() {
            guard seen.insert(name).inserted else { continue }
            if requirementFreeConformances.contains(name) { continue }
            guard let info = state.protocols[name] else { return .unknown }
            names.formUnion(info.requirements)
            pending.append(contentsOf: info.inherited)
        }
        return .names(names)
    }

    // MARK: - Static transforms

    static func transform(
        _ node: ClassDeclSyntax,
        original: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.testSuiteAccessControlState
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
        result = removePublicModifier(
            from: result,
            original: original,
            keyword: \.classKeyword,
            context: context
        )
        result = result.with(
            \.memberBlock,
            rewriteMembers(
                result.memberBlock,
                original: original.memberBlock,
                framework: framework,
                witnesses: witnessGuard(for: node.inheritanceClause, state: state),
                context: context
            )
        )
        return DeclSyntax(result)
    }

    static func transform(
        _ node: StructDeclSyntax,
        original: StructDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.testSuiteAccessControlState
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
        result = removePublicModifier(
            from: result,
            original: original,
            keyword: \.structKeyword,
            context: context
        )
        result = result.with(
            \.memberBlock,
            rewriteMembers(
                result.memberBlock,
                original: original.memberBlock,
                framework: framework,
                witnesses: witnessGuard(for: node.inheritanceClause, state: state),
                context: context
            )
        )
        return DeclSyntax(result)
    }

    // MARK: - Member Rewriting

    private static func rewriteMembers(
        _ memberBlock: MemberBlockSyntax,
        original: MemberBlockSyntax,
        framework: TestFramework,
        witnesses: WitnessGuard,
        context: Context
    ) -> MemberBlockSyntax {
        var newMembers = [MemberBlockItemSyntax]()
        var changed = false
        let originalMembers = Array(original.members)

        for (idx, member) in memberBlock.members.enumerated() {
            // The pipeline may pass a detached `node` (rebuilt by sub-rule rewrites of
            // children) whose absolute positions reset to 0 — emitting findings on those
            // tokens maps the offsets onto unrelated lines of the source. The matching
            // member from `original` is still attached to the source file and reports
            // correct positions. Fall back to the rewritten member only if member counts
            // diverge (defensive: no rule in this stage adds or removes members).
            let originalDecl = idx < originalMembers.count ? originalMembers[idx].decl : nil
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let originalFunc = originalDecl?.as(FunctionDeclSyntax.self) ?? funcDecl
                let rewritten = rewriteFunction(
                    funcDecl,
                    original: originalFunc,
                    framework: framework,
                    witnesses: witnesses,
                    context: context
                )

                if rewritten.description != funcDecl.description {
                    newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
                    changed = true
                    continue
                }
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                let originalVar = originalDecl?.as(VariableDeclSyntax.self) ?? varDecl
                let rewritten = rewriteProperty(
                    varDecl,
                    original: originalVar,
                    witnesses: witnesses,
                    context: context
                )

                if rewritten.description != varDecl.description {
                    newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
                    changed = true
                    continue
                }
            } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                let originalInit = originalDecl?.as(InitializerDeclSyntax.self) ?? initDecl
                let rewritten = removeExplicitACL(
                    from: initDecl,
                    original: originalInit,
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
        original: FunctionDeclSyntax,
        framework: TestFramework,
        witnesses: WitnessGuard,
        context: Context
    ) -> FunctionDeclSyntax {
        let modifiers = funcDecl.modifiers

        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) {
            return funcDecl
        }
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
            return removeExplicitACL(
                from: funcDecl,
                original: original,
                keyword: \.funcKeyword,
                context: context
            )
        } else {
            // A helper that witnesses a protocol requirement is read from outside the type.
            if witnesses.blocks(funcDecl.name.text) { return funcDecl }
            return modifiers.contains(where: {
                $0.name.tokenKind == .keyword(.private)
                    || $0.name.tokenKind == .keyword(.fileprivate)
            })
                ? funcDecl
                : ensurePrivate(
                    on: funcDecl,
                    original: original,
                    keyword: \.funcKeyword,
                    context: context
                )
        }
    }

    private static func rewriteProperty(
        _ varDecl: VariableDeclSyntax,
        original: VariableDeclSyntax,
        witnesses: WitnessGuard,
        context: Context
    ) -> VariableDeclSyntax {
        let modifiers = varDecl.modifiers
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { return varDecl }
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) {
            return varDecl
        }
        if varDecl.attributes.attribute(named: "objc") != nil { return varDecl }

        // A property that witnesses a protocol requirement is read from outside the type.
        let bindsWitness = varDecl.bindings.contains { binding in
            witnesses.blocks(binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text)
        }
        if bindsWitness { return varDecl }
        return modifiers.contains(where: {
            $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
        })
            ? varDecl
            : ensurePrivate(
                on: varDecl,
                original: original,
                keyword: \.bindingSpecifier,
                context: context
            )
    }

    // MARK: - Test Function Detection

    private static func isTestFunction(
        _ funcDecl: FunctionDeclSyntax,
        framework: TestFramework
    ) -> Bool {
        if funcDecl.hasAttribute("Test", inModule: "Testing") { return true }
        return framework == .xcTest
            ? funcDecl.name.text.hasPrefix("test")
                && funcDecl.signature.parameterClause.parameters.isEmpty
                && funcDecl.signature.returnClause == nil
            : false
    }

    // MARK: - Access Control Helpers

    private static let aclKeywords: Set<Keyword> = [
        .public, .private, .fileprivate, .internal, .package,
    ]

    private static func removePublicModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        original: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let publicMod = decl.modifiers.first(where: { $0.name.tokenKind == .keyword(.public) }
        ) else { return decl }

        let anchor = original.modifiers.first(where: { $0.name.tokenKind == .keyword(.public) })?
            .name ?? publicMod.name
        Self.diagnose(.removePublicFromTestType, on: anchor, context: context)
        return decl.removingModifiers([.public], keyword: keyword)
    }

    private static func removeExplicitACL<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        from decl: Decl,
        original: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        guard let aclMod = decl.modifiers.first(where: {
            if case let .keyword(kw) = $0.name.tokenKind {
                return Self.aclKeywords.contains(kw) && kw != .internal
            }
            return false
        }) else { return decl }

        let anchor = original.modifiers.first(where: {
            if case let .keyword(kw) = $0.name.tokenKind {
                return Self.aclKeywords.contains(kw) && kw != .internal
            }
            return false
        })?.name ?? aclMod.name
        Self.diagnose(.removeACLFromTestMethod, on: anchor, context: context)

        guard case let .keyword(kwToRemove) = aclMod.name.tokenKind else { return decl }
        return decl.removingModifiers([kwToRemove], keyword: keyword)
    }

    private static func ensurePrivate<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
        on decl: Decl,
        original: Decl,
        keyword: WritableKeyPath<Decl, TokenSyntax>,
        context: Context
    ) -> Decl {
        if let aclMod = decl.modifiers.first(where: {
            if case let .keyword(kw) = $0.name.tokenKind { return Self.aclKeywords.contains(kw) }
            return false
        }) {
            let anchor = original.modifiers.first(where: {
                if case let .keyword(kw) = $0.name.tokenKind {
                    return Self.aclKeywords.contains(kw)
                }
                return false
            })?.name ?? aclMod.name
            Self.diagnose(.makePrivate, on: anchor, context: context)
            var result = decl
            var newModifiers = Array(result.modifiers)

            if let idx = newModifiers.firstIndex(where: { $0.id == aclMod.id }) {
                newModifiers[
                    idx] = newModifiers[idx].with(
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

        Self.diagnose(.makePrivate, on: original[keyPath: keyword], context: context)
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

fileprivate extension Finding.Message {
    static let removePublicFromTestType: Finding.Message = "remove 'public' from test suite type"
    static let removeACLFromTestMethod: Finding.Message =
        "remove explicit access control from test method"
    static let makePrivate: Finding.Message = "make test helper 'private'"
}
