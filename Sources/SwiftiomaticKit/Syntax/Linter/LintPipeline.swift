import SwiftSyntax

/// A syntax visitor that delegates to individual rules for linting.
///
/// This file will be extended with `visit` methods in Pipelines+Generated.swift.
extension LintPipeline {
    /// Calls the `visit` method of a rule for the given node if that rule is enabled for the node.
    func visitIfEnabled<V: SyntaxRuleValue, Rule: LintSyntaxRule<V>, Node: SyntaxProtocol>(
        _ visitor: (Rule) -> (Node) -> SyntaxVisitorContinueKind,
        for node: Node
    ) {
        guard context.shouldFormat(Rule.self, node: Syntax(node)) else { return }
        let ruleId = ObjectIdentifier(Rule.self)
        guard self.shouldSkipChildren[ruleId] == nil else { return }
        let rule = self.rule(Rule.self)
        let continueKind = visitor(rule)(node)
        if case .skipChildren = continueKind {
            self.shouldSkipChildren[ruleId] = node
        }
    }

    /// Calls the `visit` method of a rewrite rule for the given node if that rule is enabled.
    func visitIfEnabled<V: SyntaxRuleValue, Rule: RewriteSyntaxRule<V>, Node: SyntaxProtocol>(
        _ visitor: (Rule) -> (Node) -> Any,
        for node: Node
    ) {
        guard context.shouldFormat(Rule.self, node: Syntax(node)) else { return }
        guard self.shouldSkipChildren[ObjectIdentifier(Rule.self)] == nil else { return }
        let rule = self.rule(Rule.self)
        _ = visitor(rule)(node)
    }

    /// Cleans up any state associated with `rule` when we leave syntax node `node`
    func onVisitPost<R: SyntaxRule, Node: SyntaxProtocol>(
        rule: R.Type,
        for node: Node
    ) {
        let rule = ObjectIdentifier(rule)
        if case .some(let skipNode) = self.shouldSkipChildren[rule] {
            if node.id == skipNode.id {
                self.shouldSkipChildren.removeValue(forKey: rule)
            }
        }
    }

    /// Dispatches `visitPost` to a cached lint rule instance and cleans up
    /// `shouldSkipChildren` bookkeeping. Lint rules with stateful visitors rely
    /// on this to balance their `visit`/`visitPost` enter/leave pairs.
    func onVisitPost<V: SyntaxRuleValue, Rule: LintSyntaxRule<V>, Node: SyntaxProtocol>(
        _ visitor: (Rule) -> (Node) -> Void,
        for node: Node
    ) {
        let ruleId = ObjectIdentifier(Rule.self)
        if case .some(let skipNode) = self.shouldSkipChildren[ruleId],
            node.id == skipNode.id
        {
            self.shouldSkipChildren.removeValue(forKey: ruleId)
        }
        if let cached = ruleCache[ruleId] as? Rule {
            visitor(cached)(node)
        }
    }

    /// Retrieves an instance of a lint or format rule based on its type.
    private func rule<R: SyntaxRule>(_ type: R.Type) -> R {
        let identifier = ObjectIdentifier(type)
        if let cachedRule = ruleCache[identifier] {
            return cachedRule as! R
        }
        let rule = R(context: context)
        ruleCache[identifier] = rule
        return rule
    }
}
