import SwiftSyntax

/// A syntax visitor that delegates to individual rules for linting.
///
/// This file will be extended with `visit` methods in Pipelines+Generated.swift.
extension LintPipeline {
    /// Calls the `visit` method of a rule for the given node if that rule is enabled for the node.
    ///
    /// - Parameter gate: The per-node gate built once by the caller. Every rule registered against
    ///   the node shares it, so the selection test and the source-location lookup happen once per
    ///   node rather than once per rule.
    func visitIfEnabled<V: SyntaxRuleValue, Rule: LintSyntaxRule<V>, Node: SyntaxProtocol>(
        _ visitor: (Rule) -> (Node) -> SyntaxVisitorContinueKind,
        for node: Node,
        gate: Context.Gate
    ) {
        guard context.shouldFormat(Rule.self, gate: gate) else { return }
        let ruleID = ObjectIdentifier(Rule.self)
        if !shouldSkipChildren.isEmpty, shouldSkipChildren[ruleID] != nil { return }
        let rule = self.rule(Rule.self)
        let continueKind = visitor(rule)(node)
        if case .skipChildren = continueKind { shouldSkipChildren[ruleID] = node }
    }

    /// Calls the `visit` method of a rewrite rule for the given node if that rule is enabled.
    ///
    /// - Parameter gate: The per-node gate built once by the caller, as in the `LintSyntaxRule`
    ///   overload.
    func visitIfEnabled<V: SyntaxRuleValue, Rule: StructuralFormatRule<V>, Node: SyntaxProtocol>(
        _ visitor: (Rule) -> (Node) -> Any,
        for node: Node,
        gate: Context.Gate
    ) {
        guard context.shouldFormat(Rule.self, gate: gate) else { return }

        if !shouldSkipChildren.isEmpty,
           shouldSkipChildren[ObjectIdentifier(Rule.self)] != nil { return }

        let rule = self.rule(Rule.self)
        _ = visitor(rule)(node)
    }

    /// Node-taking counterpart used for `SourceFileSyntax` alone.
    ///
    /// The generated dispatchers call this shape for the file node. It resolves the same location
    /// a `Context.Gate` would, so the two paths agree.
    func visitIfEnabled<V: SyntaxRuleValue, Rule: LintSyntaxRule<V>>(
        _ visitor: (Rule) -> (SourceFileSyntax) -> SyntaxVisitorContinueKind,
        for node: SourceFileSyntax
    ) {
        guard context.shouldFormat(Rule.self, node: Syntax(node)) else { return }
        let ruleID = ObjectIdentifier(Rule.self)
        if !shouldSkipChildren.isEmpty, shouldSkipChildren[ruleID] != nil { return }
        let rule = self.rule(Rule.self)
        let continueKind = visitor(rule)(node)
        if case .skipChildren = continueKind { shouldSkipChildren[ruleID] = node }
    }

    /// Node-taking counterpart for a `StructuralFormatRule` on `SourceFileSyntax` .
    func visitIfEnabled<V: SyntaxRuleValue, Rule: StructuralFormatRule<V>>(
        _ visitor: (Rule) -> (SourceFileSyntax) -> Any,
        for node: SourceFileSyntax
    ) {
        guard context.shouldFormat(Rule.self, node: Syntax(node)) else { return }

        if !shouldSkipChildren.isEmpty,
           shouldSkipChildren[ObjectIdentifier(Rule.self)] != nil { return }

        let rule = self.rule(Rule.self)
        _ = visitor(rule)(node)
    }

    /// Cleans up any state associated with `rule` when we leave syntax node `node`
    func onVisitPost<R: SyntaxRule, Node: SyntaxProtocol>(
        rule: R.Type,
        for node: Node
    ) {
        guard !shouldSkipChildren.isEmpty else { return }
        let rule = ObjectIdentifier(rule)

        if case let .some(skipNode) = shouldSkipChildren[rule] {
            if node.id == skipNode.id { shouldSkipChildren.removeValue(forKey: rule) }
        }
    }

    /// Dispatches `visitPost` to a cached lint rule instance and cleans up `shouldSkipChildren`
    /// bookkeeping. Lint rules with stateful visitors rely on this to balance their `visit` /
    /// `visitPost` enter/leave pairs.
    func onVisitPost<V: SyntaxRuleValue, Rule: LintSyntaxRule<V>, Node: SyntaxProtocol>(
        _ visitor: (Rule) -> (Node) -> Void,
        for node: Node
    ) {
        let ruleID = ObjectIdentifier(Rule.self)

        if !shouldSkipChildren.isEmpty,
           case let .some(skipNode) = shouldSkipChildren[ruleID],
           node.id == skipNode.id { shouldSkipChildren.removeValue(forKey: ruleID) }

        if let cached = ruleCache[ruleID] as? Rule { visitor(cached)(node) }
    }

    /// Retrieves an instance of a lint or format rule based on its type
    ///
    /// The cache is keyed by `ObjectIdentifier(R.self)` , so a stored value is an `R` by
    /// construction. The conditional cast reads that invariant without a trap. A mismatched entry
    /// is replaced with a fresh instance of the requested type.
    func rule<R: InstanceSyntaxRule>(_ type: R.Type) -> R {
        let identifier = ObjectIdentifier(type)
        if let cachedRule = ruleCache[identifier] as? R { return cachedRule }
        let rule = R(context: context)
        ruleCache[identifier] = rule
        return rule
    }
}
