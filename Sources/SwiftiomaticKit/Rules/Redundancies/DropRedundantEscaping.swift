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
/// A member of a conforming type keeps `@escaping` whenever it may witness a requirement that
/// declares it. The body of a witness can look non-escaping on its own, and a witness that drops
/// the attribute no longer satisfies the requirement. See `Witness` and `FileDeclarationIndex` .
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
        let isOverride = node.modifiers.contains { $0.name.tokenKind == .keyword(.override) }
        let witness: Witness = isOverride
            ? .override
            : .function(
                name: node.name.text,
                parameterCount: node.signature.parameterClause.parameters.count
            )
        guard let rewritten = rewriteParameterClause(
            node.signature.parameterClause,
            body: body.statements,
            witness: witness,
            parent: parent,
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
            witness: .initializer(parameterCount: node.signature.parameterClause.parameters.count),
            parent: parent,
            context: context
        ) else { return DeclSyntax(node) }
        var result = node
        result.signature.parameterClause = rewritten
        return DeclSyntax(result)
    }

    /// Drop `@escaping` from every parameter the escape check clears.
    ///
    /// One `EscapeChecker` covers the whole parameter clause, so the body is walked once however
    /// many parameters carry the attribute. A parameter a requirement protects never reaches the
    /// checker.
    ///
    /// - Parameters:
    ///   - witness: What the function may witness, which decides the protected positions
    ///   - parent: The node's parent, used to find the type the function belongs to
    /// - Returns: The rewritten clause, or `nil` when no parameter changed
    private static func rewriteParameterClause(
        _ clause: FunctionParameterClauseSyntax,
        body: CodeBlockItemListSyntax,
        witness: Witness,
        parent: Syntax?,
        context: Context
    ) -> FunctionParameterClauseSyntax? {
        var attributed: [Int: (name: String, isAutoclosure: Bool)] = [:]

        for (position, param) in clause.parameters.enumerated() {
            guard let attributes = param.type.as(AttributedTypeSyntax.self)?.attributes,
                  attributes.attribute(named: "escaping") != nil else { continue }
            attributed[position] = (
                name: (param.secondName ?? param.firstName).text,
                isAutoclosure: attributes.attribute(named: "autoclosure") != nil
            )
        }
        guard !attributed.isEmpty else { return nil }

        let protected = protectedPositions(witness: witness, parent: parent, context: context)
        var candidates: Set<String> = []
        var autoclosures: Set<String> = []

        for (position, param) in attributed where !protected.covers(position) {
            candidates.insert(param.name)
            if param.isAutoclosure { autoclosures.insert(param.name) }
        }
        guard !candidates.isEmpty else { return nil }

        let checker = EscapeChecker(
            candidates: candidates,
            autoclosures: autoclosures,
            viewMode: .sourceAccurate
        )
        checker.walk(body)

        var changed = false
        let newParams = clause.parameters.enumerated().map {
            position, param -> FunctionParameterSyntax in
            guard let attributedType = param.type.as(AttributedTypeSyntax.self),
                let escapingAttr = attributedType.attributes.attribute(named: "escaping")
            else { return param }
            let paramName = (param.secondName ?? param.firstName).text
            guard !protected.covers(position),
                  !checker.escapedParameters.contains(paramName) else { return param }

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

    private static func isInsideProtocol(parent: Syntax?) -> Bool {
        var current = parent

        while let node = current {
            if node.is(ProtocolDeclSyntax.self) { return true }
            current = node.parent
        }
        return false
    }
}

// MARK: - Witness Analysis

extension DropRedundantEscaping {
    /// What a function or an initializer may witness.
    ///
    /// An `override` answers a superclass signature this file often does not hold, so it protects
    /// every parameter.
    private enum Witness {
        case function(name: String, parameterCount: Int)
        case initializer(parameterCount: Int)
        case override

        /// The requirement this witness answers, or `nil` when no requirement can name it
        var requirementKey: FileDeclarationIndex.RequirementKey? {
            switch self {
                case let .function(name, parameterCount):
                    FileDeclarationIndex.RequirementKey(name: name, parameterCount: parameterCount)
                case let .initializer(parameterCount):
                    FileDeclarationIndex.RequirementKey(
                        name: "init", parameterCount: parameterCount)
                case .override: nil
            }
        }
    }

    /// Parameter positions that keep `@escaping` whatever the escape check finds.
    private enum ProtectedPositions {
        case none
        case some(Set<Int>)
        case all

        func covers(_ position: Int) -> Bool {
            switch self {
                case .none: false
                case let .some(positions): positions.contains(position)
                case .all: true
            }
        }
    }

    /// Where a declaration sits, from the point of view of conformance.
    private enum Ownership {
        /// A top-level or local declaration, which witnesses nothing
        case free
        /// A member of a type whose conformance list this file holds
        case member(conformances: [String])
        /// A member of a type this file does not declare, so its conformances stay invisible
        case unresolved
    }

    /// Conformances whose requirements take no closure parameter. A member of a type that conforms
    /// only to these cannot witness an `@escaping` requirement through them.
    private static let closureFreeConformances: Set<String> = [
        "AnyObject", "BitwiseCopyable", "CaseIterable", "Codable", "Comparable", "Copyable",
        "CustomDebugStringConvertible", "CustomStringConvertible", "Decodable", "Encodable",
        "Equatable", "Error", "Escapable", "Hashable", "Identifiable", "RawRepresentable",
        "Sendable",
    ]

    /// The positions `witness` protects.
    ///
    /// The walk starts at the conformance list of the owning type and follows every inherited name
    /// this file declares. A name the file does not declare protects every position, because the
    /// requirement it carries is unreadable from here.
    private static func protectedPositions(
        witness: Witness,
        parent: Syntax?,
        context: Context
    ) -> ProtectedPositions {
        guard let key = witness.requirementKey else { return .all }
        let index = context.fileDeclarationIndex

        switch ownership(parent: parent, index: index) {
            case .free: return .none
            case .unresolved: return .all
            case let .member(conformances):
                var positions: Set<Int> = []
                var pending = conformances
                var seen: Set<String> = []

                while let name = pending.popLast() {
                    guard seen.insert(name).inserted else { continue }
                    if closureFreeConformances.contains(name) { continue }

                    if let entry = index.protocols[name] {
                        positions.formUnion(entry.requirements[key] ?? [])
                        pending.append(contentsOf: entry.inherited)
                        continue
                    }
                    guard let inherited = index.conformances[name] else { return .all }
                    pending.append(contentsOf: inherited)
                }
                return positions.isEmpty ? .none : .some(positions)
        }
    }

    /// The nearest enclosing type context of `parent` .
    ///
    /// A function, an initializer, an accessor or a closure between the declaration and the type
    /// makes the declaration local, and a local declaration witnesses nothing.
    private static func ownership(parent: Syntax?, index: FileDeclarationIndex) -> Ownership {
        var current = parent

        while let node = current {
            switch node.as(SyntaxEnum.self) {
                case .functionDecl,
                     .initializerDecl,
                     .deinitializerDecl,
                     .accessorDecl,
                     .closureExpr,
                     .subscriptDecl: return .free
                case .structDecl, .classDecl, .enumDecl, .actorDecl:
                    let name = node.asProtocol(NamedDeclSyntax.self)?.name.text ?? ""
                    return .member(conformances: index.conformances[name] ?? [])
                case let .extensionDecl(decl):
                    // an extension of a type declared elsewhere hides that type's conformances
                    guard let name = decl.extendedType.simpleName,
                          index.concreteTypes.contains(name) else { return .unresolved }
                    return .member(conformances: index.conformances[name] ?? [])
                default: current = node.parent
            }
        }
        return .free
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
