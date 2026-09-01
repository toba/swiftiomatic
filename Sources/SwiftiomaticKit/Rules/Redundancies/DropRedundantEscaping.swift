import SwiftSyntax

/// Remove `@escaping` from closure parameters that demonstrably do not escape.
///
/// `@escaping` is required only when a closure parameter outlives the function call. This rule uses
/// a flow-insensitive escape check: a closure escapes if it (or a value tainted by it) is returned,
/// assigned to a non-local variable, passed to another function, or referenced inside a nested
/// scope or an `async let` initializer.
///
/// The analysis is deliberately conservative — when escape can't be ruled out, the rule stays
/// silent. Protocol requirements, autoclosure-only edge cases, and parameters referenced inside
/// nested closures are all assumed to escape.
///
/// Lint: A finding is raised at the `@escaping` attribute.
///
/// Rewrite: The `@escaping` attribute is removed.
final class DropRedundantEscaping: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 1170

    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isInsideProtocol(parent: parent), let body = node.body
        else { return DeclSyntax(node) }
        guard let rewritten = rewriteParameterClause(
            node.signature.parameterClause,
            body: body.statements,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.signature.parameterClause = rewritten
        return DeclSyntax(result)
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        original _: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard !isInsideProtocol(parent: parent), let body = node.body
        else { return DeclSyntax(node) }
        guard let rewritten = rewriteParameterClause(
            node.signature.parameterClause,
            body: body.statements,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.signature.parameterClause = rewritten
        return DeclSyntax(result)
    }

    /// Drop `@escaping` from every parameter the escape check clears.
    ///
    /// One `EscapeChecker` covers the whole parameter clause, so the body is walked once however
    /// many parameters carry the attribute.
    ///
    /// - Returns: The rewritten clause, or `nil` when no parameter changed
    private static func rewriteParameterClause(
        _ clause: FunctionParameterClauseSyntax,
        body: CodeBlockItemListSyntax,
        context: Context
    ) -> FunctionParameterClauseSyntax? {
        var candidates: Set<String> = []
        var autoclosures: Set<String> = []

        for param in clause.parameters {
            guard let attributedType = param.type.as(AttributedTypeSyntax.self),
                attribute(named: "escaping", in: attributedType.attributes) != nil else { continue }
            let name = (param.secondName ?? param.firstName).text
            candidates.insert(name)

            if attribute(named: "autoclosure", in: attributedType.attributes) != nil {
                autoclosures.insert(name)
            }
        }
        guard !candidates.isEmpty else { return nil }

        let checker = EscapeChecker(
            candidates: candidates,
            autoclosures: autoclosures,
            viewMode: .sourceAccurate
        )
        checker.walk(body)

        var changed = false
        let newParams = clause.parameters.map { param -> FunctionParameterSyntax in
            guard let attributedType = param.type.as(AttributedTypeSyntax.self),
                let escapingAttr = attribute(named: "escaping", in: attributedType.attributes)
            else { return param }
            let paramName = (param.secondName ?? param.firstName).text
            guard !checker.escapedParameters.contains(paramName) else { return param }

            Self.diagnose(
                .removeRedundantEscaping(name: paramName),
                on: escapingAttr,
                context: context
            )

            var newAttributedType = attributedType
            let newAttributes = attributedType.attributes.filter { element in
                guard case let .attribute(attr) = element else { return true }
                return attr.id != escapingAttr.id
            }
            newAttributedType.attributes = newAttributes

            var newParam = param
            newParam.type = newAttributes.isEmpty
                ? newAttributedType.baseType
                    .with(\.leadingTrivia, attributedType.leadingTrivia)
                    .with(\.trailingTrivia, attributedType.trailingTrivia)
                : TypeSyntax(newAttributedType)
            changed = true
            return newParam
        }
        guard changed else { return nil }
        return clause.with(\.parameters, FunctionParameterListSyntax(newParams))
    }

    private static func attribute(
        named name: String,
        in list: AttributeListSyntax
    ) -> AttributeSyntax? {
        for element in list {
            guard case let .attribute(attr) = element else { continue }
            if attributeName(of: attr) == name { return attr }
        }
        return nil
    }

    private static func attributeName(of attr: AttributeSyntax) -> String? {
        attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text
    }

    private static func isInsideProtocol(parent: Syntax?) -> Bool {
        var current = parent

        while let node = current {
            if node.is(ProtocolDeclSyntax.self) { return true }
            current = node.parent
        }
        return false
    }
}

// MARK: - Escape Analysis

/// Conservative escape checker: tracks a set of candidate parameters (and any local variables
/// tainted by one) and reports a parameter as escaping when a value it taints is returned, assigned
/// to a non-local variable, passed to another function, or referenced inside a nested scope or an
/// `async let` initializer.
private final class EscapeChecker: SyntaxVisitor {
    /// Names each candidate parameter taints, keyed by the parameter name.
    private var taintedVariables: [String: Set<String>]
    private var localVariables: Set<String>
    private let autoclosures: Set<String>
    private var insideNestedScope = 0
    private var insideAsyncLet = 0
    private(set) var escapedParameters: Set<String> = []

    init(candidates: Set<String>, autoclosures: Set<String>, viewMode: SyntaxTreeViewMode) {
        taintedVariables = candidates.reduce(into: [:]) { $0[$1] = [$1] }
        localVariables = candidates
        self.autoclosures = autoclosures
        super.init(viewMode: viewMode)
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        insideNestedScope += 1
        return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) { insideNestedScope -= 1 }

    // the walk starts at the body, so only a local function reaches these two
    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        insideNestedScope += 1
        return .visitChildren
    }

    override func visitPost(_: FunctionDeclSyntax) { insideNestedScope -= 1 }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if Self.isAsyncLet(node) { insideAsyncLet += 1 }
        return .visitChildren
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        if Self.isAsyncLet(node) { insideAsyncLet -= 1 }

        for binding in node.bindings {
            let sources = binding.initializer.map { taintSources(of: $0.value) } ?? []
            registerPattern(binding.pattern, sources: sources)
        }
    }

    private static func isAsyncLet(_ node: VariableDeclSyntax) -> Bool {
        node.modifiers.contains { $0.name.tokenKind == .keyword(.async) }
    }

    /// Walk a binding pattern and register every identifier as a local; taint each identifier for
    /// every parameter that tainted the initializer. Handles both `let x = …` (IdentifierPattern)
    /// and `let (x, y) = …` (TuplePattern).
    private func registerPattern(_ pattern: PatternSyntax, sources: Set<String>) {
        if let ident = pattern.as(IdentifierPatternSyntax.self) {
            let name = ident.identifier.text
            localVariables.insert(name)
            for source in sources { taintedVariables[source]?.insert(name) }
        } else if let tuple = pattern.as(TuplePatternSyntax.self) {
            for element in tuple.elements { registerPattern(element.pattern, sources: sources) }
        }
    }

    override func visitPost(_ node: ReturnStmtSyntax) {
        guard let expr = node.expression else { return }
        escapedParameters.formUnion(taintSources(of: expr))
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        for argument in node.arguments {
            escapedParameters.formUnion(taintSources(of: argument.expression))
            escapedParameters.formUnion(autoclosureCallSources(of: argument.expression))
        }
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        let sources = taintSources(of: ExprSyntax(node))
        guard !sources.isEmpty else { return }

        // a nested scope and an async let child task both outlive the call
        if insideNestedScope > 0 || insideAsyncLet > 0 {
            escapedParameters.formUnion(sources)
            return
        }
        if let parentKind = node.parent?.kind,
           parentKind == .arrayElement || parentKind == .dictionaryElement {
            escapedParameters.formUnion(sources)
        }
    }

    override func visitPost(_ node: InfixOperatorExprSyntax) {
        guard node.operator.is(AssignmentExprSyntax.self) else { return }
        let sources = taintSources(of: node.rightOperand)
        guard !sources.isEmpty else { return }

        if let leftRef = node.leftOperand.as(DeclReferenceExprSyntax.self),
            localVariables.contains(leftRef.baseName.text)
        {
            for source in sources { taintedVariables[source]?.insert(leftRef.baseName.text) }
        } else {
            escapedParameters.formUnion(sources)
        }
    }

    /// The candidate parameters whose taint reaches this expression.
    private func taintSources(of expr: ExprSyntax) -> Set<String> {
        if let ref = expr.as(DeclReferenceExprSyntax.self) {
            return sources(tainting: ref.baseName.text)
        }

        if let optChain = expr.as(OptionalChainingExprSyntax.self),
           let ref = optChain.expression.as(DeclReferenceExprSyntax.self) {
            return sources(tainting: ref.baseName.text)
        }

        if let ternary = expr.as(TernaryExprSyntax.self) {
            return taintSources(of: ternary.thenExpression)
                .union(taintSources(of: ternary.elseExpression))
        }

        if let tuple = expr.as(TupleExprSyntax.self) {
            return tuple.elements.reduce(into: Set<String>()) {
                $0.formUnion(taintSources(of: $1.expression))
            }
        }
        return []
    }

    private func sources(tainting name: String) -> Set<String> {
        var result: Set<String> = []

        for (parameter, tainted) in taintedVariables where tainted.contains(name) {
            result.insert(parameter)
        }
        return result
    }

    /// For an autoclosure parameter, calling it (e.g. `body()`) does not escape it, but the result
    /// might still be propagated. This mirrors SwiftLint's autoclosure carve-out.
    private func autoclosureCallSources(of expr: ExprSyntax) -> Set<String> {
        guard let call = expr.as(FunctionCallExprSyntax.self),
              call.arguments.isEmpty,
              call.trailingClosure == nil,
              call.additionalTrailingClosures.isEmpty,
              let ref = call.calledExpression.as(DeclReferenceExprSyntax.self) else { return [] }
        return sources(tainting: ref.baseName.text).intersection(autoclosures)
    }
}

fileprivate extension Finding.Message {
    static func removeRedundantEscaping(name: String) -> Finding.Message {
        "remove '@escaping' from '\(name)'; the closure does not escape"
    }
}
