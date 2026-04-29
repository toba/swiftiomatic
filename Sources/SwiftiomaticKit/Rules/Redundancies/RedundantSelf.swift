import SwiftSyntax

/// Remove explicit `self.` where the compiler allows implicit self.
///
/// In most contexts inside type bodies, `self.` is redundant when accessing members
/// because Swift resolves bare identifiers to instance members. This rule removes
/// the `self.` prefix when:
/// - The access is inside a type member (method, computed property, init, subscript)
/// - The member name is not shadowed by a local variable, parameter, or nested function
/// - The scope allows implicit self (not a closure in a reference type without capture)
///
/// For closures, implicit self is allowed per SE-0269 (Swift 5.3+) when:
/// - The enclosing type is a value type (struct/enum)
/// - The closure explicitly captures self: `[self]`, `[unowned self]`
///
/// The `[weak self]` + `guard let self` pattern (SE-0365, Swift 5.8+) is handled
/// conservatively: `self.` is kept in weak-self closures.
///
/// Lint: A lint warning is raised for redundant `self.` usage.
///
/// Rewrite: The `self.` prefix is removed.
final class RedundantSelf: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Per-file mutable state held in `Context.ruleState`. Mirrors the three instance stacks so
    /// the static `transform`/`willEnter`/`didExit` path tracks scope identically to the legacy
    /// override path.
    final class State {
        /// Whether the immediately enclosing type is a reference type (class/actor).
        var referenceTypeStack: [Bool] = []
        /// Stack of implicit-self-allowed flags per scope (function/accessor/closure).
        var implicitSelfStack: [Bool] = []
        /// Stack of local name sets per scope.
        var localNameStack: [Set<String>] = []
        /// Per-scope-decl flag: did we actually push a frame on willEnter? Used so didExit only
        /// pops when willEnter pushed (some scope-decl visits early-return without pushing).
        var scopeFrameStack: [Bool] = []

        var insideTypeBody: Bool { !referenceTypeStack.isEmpty }
        var isReferenceType: Bool { referenceTypeStack.last ?? false }
        var implicitSelfAllowed: Bool { implicitSelfStack.last ?? false }
        var allLocalNames: Set<String> {
            localNameStack.reduce(into: Set()) { $0.formUnion($1) }
        }
    }

    // MARK: - Static scope hooks

    static func willEnter(_: StructDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.referenceTypeStack.append(false)
    }

    static func didExit(_: StructDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if !state.referenceTypeStack.isEmpty { state.referenceTypeStack.removeLast() }
    }

    static func willEnter(_: EnumDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.referenceTypeStack.append(false)
    }

    static func didExit(_: EnumDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if !state.referenceTypeStack.isEmpty { state.referenceTypeStack.removeLast() }
    }

    static func willEnter(_: ClassDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.referenceTypeStack.append(true)
    }

    static func didExit(_: ClassDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if !state.referenceTypeStack.isEmpty { state.referenceTypeStack.removeLast() }
    }

    static func willEnter(_: ActorDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.referenceTypeStack.append(true)
    }

    static func didExit(_: ActorDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if !state.referenceTypeStack.isEmpty { state.referenceTypeStack.removeLast() }
    }

    static func willEnter(_: ExtensionDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        state.referenceTypeStack.append(true)
    }

    static func didExit(_: ExtensionDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if !state.referenceTypeStack.isEmpty { state.referenceTypeStack.removeLast() }
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.insideTypeBody else {
            state.scopeFrameStack.append(false)
            return
        }
        var names = Self.collectParamNames(from: node.signature.parameterClause)
        if let body = node.body { names.formUnion(Self.collectLocalNames(in: Syntax(body))) }
        state.localNameStack.append(names)
        state.implicitSelfStack.append(true)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: FunctionDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    static func willEnter(_ node: InitializerDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.insideTypeBody else {
            state.scopeFrameStack.append(false)
            return
        }
        var names = Self.collectParamNames(from: node.signature.parameterClause)
        if let body = node.body { names.formUnion(Self.collectLocalNames(in: Syntax(body))) }
        state.localNameStack.append(names)
        state.implicitSelfStack.append(true)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: InitializerDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    static func willEnter(_ node: SubscriptDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.insideTypeBody else {
            state.scopeFrameStack.append(false)
            return
        }
        let names = Self.collectParamNames(from: node.parameterClause)
        state.localNameStack.append(names)
        state.implicitSelfStack.append(true)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: SubscriptDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    static func willEnter(_ node: AccessorDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.insideTypeBody || !state.implicitSelfStack.isEmpty else {
            state.scopeFrameStack.append(false)
            return
        }
        var names = Set<String>()
        let spec = node.accessorSpecifier.tokenKind
        if let params = node.parameters {
            names.insert(params.name.text)
        } else {
            switch spec {
                case .keyword(.set), .keyword(.willSet): names.insert("newValue")
                case .keyword(.didSet): names.insert("oldValue")
                default: break
            }
        }
        if spec == .keyword(.get) || spec == .keyword(.set) {
            if let propName = Self.enclosingPropertyName(of: node) { names.insert(propName) }
        }
        if let body = node.body { names.formUnion(Self.collectLocalNames(in: Syntax(body))) }
        state.localNameStack.append(names)
        state.implicitSelfStack.append(true)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: AccessorDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    static func willEnter(_ node: VariableDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.insideTypeBody, node.modifiers.contains(anyOf: [.lazy]) else {
            state.scopeFrameStack.append(false)
            return
        }
        let allowed = !state.isReferenceType
        state.localNameStack.append([])
        state.implicitSelfStack.append(allowed)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: VariableDeclSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    static func willEnter(_ node: AccessorBlockSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard case let .getter(body) = node.accessors else {
            state.scopeFrameStack.append(false)
            return
        }
        guard state.insideTypeBody || !state.implicitSelfStack.isEmpty else {
            state.scopeFrameStack.append(false)
            return
        }
        var names = Self.collectLocalNames(in: Syntax(body))
        if let propName = Self.enclosingPropertyName(of: node) { names.insert(propName) }
        state.localNameStack.append(names)
        state.implicitSelfStack.append(true)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: AccessorBlockSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    static func willEnter(_ node: ClosureExprSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        guard state.insideTypeBody else {
            state.scopeFrameStack.append(false)
            return
        }
        var names = Set<String>()
        let allowsImplicitSelf: Bool = !state.isReferenceType ? true : Self.closureHasSelfCapture(node)

        if let signature = node.signature {
            names.formUnion(Self.collectClosureParamNames(from: signature))
            if let captureClause = signature.capture {
                for capture in captureClause.items {
                    let name = capture.name.text
                    if name != "self" { names.insert(name) }
                }
            }
        }
        names.formUnion(Self.collectLocalNames(in: Syntax(node.statements)))
        state.localNameStack.append(names)
        state.implicitSelfStack.append(allowsImplicitSelf)
        state.scopeFrameStack.append(true)
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        let state = context.ruleState(for: Self.self) { State() }
        if let didPush = state.scopeFrameStack.popLast(), didPush {
            if !state.localNameStack.isEmpty { state.localNameStack.removeLast() }
            if !state.implicitSelfStack.isEmpty { state.implicitSelfStack.removeLast() }
        }
    }

    // MARK: - Static transform

    static func transform(
        _ node: MemberAccessExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let state = context.ruleState(for: Self.self) { State() }

        guard let base = node.base?.as(DeclReferenceExprSyntax.self),
              base.baseName.tokenKind == .keyword(.self)
        else { return ExprSyntax(node) }

        let memberName = node.declName.baseName.text
        guard memberName != "init",
              !RedundantBackticks.swiftKeywords.contains(memberName)
        else { return ExprSyntax(node) }

        guard !state.implicitSelfStack.isEmpty else { return ExprSyntax(node) }
        guard state.implicitSelfAllowed else { return ExprSyntax(node) }
        guard !state.allLocalNames.contains(memberName) else { return ExprSyntax(node) }

        Self.diagnose(.removeRedundantSelf, on: base, context: context)

        var replacement = ExprSyntax(node.declName)
        replacement.leadingTrivia = node.leadingTrivia
        replacement.trailingTrivia = node.trailingTrivia
        return replacement
    }

    // MARK: - Helpers

    /// Determines if a closure captures `self` explicitly (strong or unowned).
    /// `[weak self]` returns false (conservative — requires guard let self detection).
    private static func closureHasSelfCapture(_ closure: ClosureExprSyntax) -> Bool {
        guard let signature = closure.signature,
              let captureClause = signature.capture
        else { return false }

        for capture in captureClause.items where capture.name.tokenKind == .keyword(.self) {
            if let specifier = capture.specifier {
                let specKind = specifier.specifier.tokenKind
                // [unowned self] and [unowned(safe) self] allow implicit self
                if specKind == .keyword(.unowned) { return true }
                // [weak self] does NOT allow implicit self without guard let self
                if specKind == .keyword(.weak) { return false }
            }
            // [self] — strong capture, allows implicit self
            return true
        }
        return false
    }

    /// Collects parameter internal names from a function parameter clause.
    private static func collectParamNames(
        from clause: FunctionParameterClauseSyntax
    ) -> Set<String> {
        var names = Set<String>()
        for param in clause.parameters {
            let internalName = param.secondName ?? param.firstName
            guard internalName.tokenKind != .wildcard else { continue }
            names.insert(internalName.text)
        }
        return names
    }

    /// Collects parameter names from a closure signature.
    private static func collectClosureParamNames(
        from signature: ClosureSignatureSyntax
    ) -> Set<String> {
        guard let paramClause = signature.parameterClause else { return [] }
        var names = Set<String>()

        switch paramClause {
            case let .simpleInput(params): for param in params { names.insert(param.name.text) }
            case let .parameterClause(clause):
                for param in clause.parameters {
                    let internalName = param.secondName ?? param.firstName
                    guard internalName.tokenKind != .wildcard else { continue }
                    names.insert(internalName.text)
                }
        }
        return names
    }

    /// Walks up from a node to find the enclosing property name.
    /// Used to prevent removing `self.` inside a computed property's own getter/setter.
    private static func enclosingPropertyName(of node: some SyntaxProtocol) -> String? {
        var current = node.parent
        while let parent = current {
            if let binding = parent.as(PatternBindingSyntax.self),
               let ident = binding.pattern.as(IdentifierPatternSyntax.self)
            {
                return ident.identifier.text
            }
            current = parent.parent
        }
        return nil
    }

    /// Collects all declared names in a syntax subtree without descending into
    /// nested closures, functions, or type declarations (those have their own scope).
    private static func collectLocalNames(in syntax: Syntax) -> Set<String> {
        let collector = LocalNameCollector(viewMode: .sourceAccurate)
        collector.walk(syntax)
        return collector.names
    }
}

// MARK: - Local Name Collector

/// Visitor that collects all identifiers introduced by bindings, patterns,
/// and nested function declarations within a single scope level.
private final class LocalNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.identifier.text)
        return .visitChildren
    }

    // Nested function names shadow members
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .skipChildren
    }

    // Catch clauses have an implicit `error` variable when no explicit binding exists
    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        if node.catchItems.isEmpty { names.insert("error") }
        return .visitChildren
    }

    // Don't descend into nested closures — they have their own scope
    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    // Don't descend into nested type declarations
    override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ClassDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ActorDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let removeRedundantSelf: Finding.Message = "remove redundant 'self.' prefix"
}
