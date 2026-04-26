import SwiftSyntax

/// Remove `@escaping` from closure parameters that demonstrably do not escape.
///
/// `@escaping` is required only when a closure parameter outlives the function call. This
/// rule uses a flow-insensitive escape check: a closure escapes if it (or a value tainted
/// by it) is returned, assigned to a non-local variable, passed to another function, or
/// referenced inside a nested closure.
///
/// The analysis is deliberately conservative — when escape can't be ruled out, the rule
/// stays silent. Protocol requirements, autoclosure-only edge cases, and parameters
/// referenced inside nested closures are all assumed to escape.
///
/// Lint: A finding is raised at the `@escaping` attribute.
///
/// Rewrite: The `@escaping` attribute is removed.
final class RedundantEscaping: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .warn) }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard !isInsideProtocol(Syntax(node)),
            let body = node.body
        else {
            return super.visit(node)
        }
        let rewritten = rewriteParameterClause(
            node.signature.parameterClause,
            body: body.statements
        )
        guard let rewritten else { return super.visit(node) }
        var result = node
        result.signature.parameterClause = rewritten
        return super.visit(DeclSyntax(result))
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        guard !isInsideProtocol(Syntax(node)),
            let body = node.body
        else {
            return super.visit(node)
        }
        let rewritten = rewriteParameterClause(
            node.signature.parameterClause,
            body: body.statements
        )
        guard let rewritten else { return super.visit(node) }
        var result = node
        result.signature.parameterClause = rewritten
        return super.visit(DeclSyntax(result))
    }

    // MARK: - Parameter rewriting

    private func rewriteParameterClause(
        _ clause: FunctionParameterClauseSyntax,
        body: CodeBlockItemListSyntax
    ) -> FunctionParameterClauseSyntax? {
        var changed = false
        let newParams = clause.parameters.map { param -> FunctionParameterSyntax in
            guard let attributedType = param.type.as(AttributedTypeSyntax.self),
                let escapingAttr = escapingAttribute(in: attributedType.attributes)
            else {
                return param
            }
            let paramName = (param.secondName ?? param.firstName).text
            let isAutoclosure = hasAttribute(named: "autoclosure", in: attributedType.attributes)
            let checker = EscapeChecker(
                paramName: paramName,
                isAutoclosure: isAutoclosure,
                viewMode: .sourceAccurate
            )
            checker.walk(body)
            guard !checker.doesEscape else { return param }

            diagnose(.removeRedundantEscaping(name: paramName), on: escapingAttr)

            var newAttributedType = attributedType
            let newAttributes = AttributeListSyntax(
                attributedType.attributes.compactMap { element -> AttributeListSyntax.Element? in
                    if case .attribute(let attr) = element,
                        attributeName(of: attr) == "escaping"
                    {
                        return nil
                    }
                    return element
                }
            )
            newAttributedType.attributes = newAttributes

            var newParam = param
            // If the attribute list is now empty, drop the AttributedTypeSyntax wrapper to keep
            // the printed source clean.
            if newAttributes.isEmpty {
                newParam.type = newAttributedType.baseType
                    .with(\.leadingTrivia, attributedType.leadingTrivia)
                    .with(\.trailingTrivia, attributedType.trailingTrivia)
            } else {
                newParam.type = TypeSyntax(newAttributedType)
            }
            changed = true
            return newParam
        }
        guard changed else { return nil }
        return clause.with(\.parameters, FunctionParameterListSyntax(newParams))
    }

    private func escapingAttribute(in list: AttributeListSyntax) -> AttributeSyntax? {
        for element in list {
            guard case .attribute(let attr) = element else { continue }
            if attributeName(of: attr) == "escaping" { return attr }
        }
        return nil
    }

    private func hasAttribute(named name: String, in list: AttributeListSyntax) -> Bool {
        list.contains { element in
            guard case .attribute(let attr) = element else { return false }
            return attributeName(of: attr) == name
        }
    }

    private func attributeName(of attr: AttributeSyntax) -> String? {
        attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text
    }

    private func isInsideProtocol(_ syntax: Syntax) -> Bool {
        var current = syntax.parent
        while let parent = current {
            if parent.is(ProtocolDeclSyntax.self) { return true }
            current = parent.parent
        }
        return false
    }
}

// MARK: - Escape Analysis

/// Conservative escape checker: tracks the parameter name (and any local variables tainted
/// by it) and reports an escape when a tainted value is returned, assigned to a non-local
/// variable, passed to another function, or referenced inside a nested closure.
private final class EscapeChecker: SyntaxVisitor {
    private var taintedVariables: Set<String>
    private var localVariables: Set<String> = []
    private var insideNestedClosure = 0
    private(set) var doesEscape = false
    private let isAutoclosure: Bool

    init(paramName: String, isAutoclosure: Bool, viewMode: SyntaxTreeViewMode) {
        self.taintedVariables = [paramName]
        self.localVariables = [paramName]
        self.isAutoclosure = isAutoclosure
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        insideNestedClosure += 1
        return .visitChildren
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        insideNestedClosure -= 1
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            localVariables.insert(pattern.identifier.text)
            if let initializer = binding.initializer, isTainted(initializer.value) {
                taintedVariables.insert(pattern.identifier.text)
            }
        }
    }

    override func visitPost(_ node: ReturnStmtSyntax) {
        if let expr = node.expression, isTainted(expr) {
            doesEscape = true
        }
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        for argument in node.arguments {
            if isTainted(argument.expression) || calleeIsTainted(argument.expression) {
                doesEscape = true
                return
            }
        }
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        guard isTainted(ExprSyntax(node)) else { return }
        if insideNestedClosure > 0 {
            doesEscape = true
            return
        }
        // Stored in a collection literal.
        if let parentKind = node.parent?.kind,
            parentKind == .arrayElement || parentKind == .dictionaryElement
        {
            doesEscape = true
        }
    }

    override func visitPost(_ node: InfixOperatorExprSyntax) {
        guard node.operator.is(AssignmentExprSyntax.self), isTainted(node.rightOperand) else {
            return
        }
        // Only assignment to a known local variable is safe; assignment to anything else
        // (an outer-scope `var`, a member, a subscript) escapes the value.
        if let leftRef = node.leftOperand.as(DeclReferenceExprSyntax.self),
            localVariables.contains(leftRef.baseName.text)
        {
            taintedVariables.insert(leftRef.baseName.text)
        } else {
            doesEscape = true
        }
    }

    private func isTainted(_ expr: ExprSyntax) -> Bool {
        if let ref = expr.as(DeclReferenceExprSyntax.self) {
            return taintedVariables.contains(ref.baseName.text)
        }
        if let optChain = expr.as(OptionalChainingExprSyntax.self),
            let ref = optChain.expression.as(DeclReferenceExprSyntax.self)
        {
            return taintedVariables.contains(ref.baseName.text)
        }
        if let ternary = expr.as(TernaryExprSyntax.self) {
            return isTainted(ternary.thenExpression) || isTainted(ternary.elseExpression)
        }
        return false
    }

    /// For autoclosure parameters, calling the parameter (e.g. `body()`) does not escape it —
    /// but the result might still be propagated. This mirrors SwiftLint's autoclosure carve-out.
    private func calleeIsTainted(_ expr: ExprSyntax) -> Bool {
        guard isAutoclosure,
            let call = expr.as(FunctionCallExprSyntax.self),
            call.arguments.isEmpty,
            call.trailingClosure == nil,
            call.additionalTrailingClosures.isEmpty,
            let ref = call.calledExpression.as(DeclReferenceExprSyntax.self)
        else {
            return false
        }
        return taintedVariables.contains(ref.baseName.text)
    }
}

extension Finding.Message {
    fileprivate static func removeRedundantEscaping(name: String) -> Finding.Message {
        "remove '@escaping' from '\(name)'; the closure does not escape"
    }
}
