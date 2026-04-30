import SwiftSyntax

/// Per-node cache of the inputs needed to evaluate `shouldRewrite` for any rule at a single node.
/// Building one of these once per `visit(_:)` override and passing it to every per-rule check
/// eliminates the repeated `isInsideSelection` + `startLocation` work that `Context.shouldFormat`
/// otherwise performs for every rule on every node.
extension Context {
    struct Gate {
        let node: Syntax
        let location: SourceLocation
    }

    /// Builds a gate for `node` , or returns `nil` when the node falls outside the active selection
    /// (in which case no rule should run).
    @inline(__always)
    func gate(for node: some SyntaxProtocol) -> Gate? {
        let s = Syntax(node)
        guard s.isInsideSelection(selection) else { return nil }
        return Gate(node: s, location: s.startLocation(converter: sourceLocationConverter))
    }

    /// Gate-aware variant of `shouldRewrite(_:at:)` . Skips the per-call `isInsideSelection`
    /// traversal and `startLocation` work by reusing the values cached on the gate.
    @inline(__always)
    func shouldRewrite<R: SyntaxRule>(_ rule: R.Type, gate: Gate) -> Bool {
        guard enabledRules.contains(ObjectIdentifier(rule)) else { return false }
        let name = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)] ?? rule.key
        return ruleMask.ruleState(name, at: gate.location) == .default
    }
}
