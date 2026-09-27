import SwiftSyntax

/// Per-node cache of the inputs needed to evaluate `shouldRewrite` or `shouldFormat` for any rule
/// at a single node. Building one of these once per `visit(_:)` override and passing it to every
/// per-rule check eliminates the repeated `isInsideSelection` and offset work that the node-taking
/// gate entry points otherwise perform for every rule on every node.
extension Context {
    struct Gate {
        /// The UTF-8 offset that `RuleMask` checks against its directives.
        let offset: Int
    }

    /// Builds a gate for `node` , or returns `nil` when the node falls outside the active selection
    /// (in which case no rule should run).
    ///
    /// The cached offset comes from `gateOffset(for:)` , so a file-wide rule on `SourceFileSyntax`
    /// gates at the end of the file exactly as the node-taking entry points do.
    @inline(__always)
    func gate(for node: some SyntaxProtocol) -> Gate? {
        let s = Syntax(node)
        guard s.isInsideSelection(selection) else { return nil }
        return Gate(offset: gateOffset(for: s))
    }

    /// Gate-aware check for the rewrite pipeline. The generated code passes the rule index as a
    /// literal, so the check hashes nothing.
    @inline(__always)
    func shouldRewrite(_ index: Int, gate: Gate) -> Bool {
        isUnmasked(index, in: rewriteEnabledRules, atOffset: gate.offset)
    }

    /// Gate-aware check for the lint pipeline, the counterpart of `shouldRewrite(_:gate:)` .
    @inline(__always)
    func shouldFormat(_ index: Int, gate: Gate) -> Bool {
        isUnmasked(index, in: enabledRules, atOffset: gate.offset)
    }

    /// Whether any rule of `indices` is in `enabled` .
    ///
    /// The generated pipelines call this once per node kind when they start, and skip the gate for
    /// a node kind with no enabled rule.
    func anyEnabled(_ indices: [Int], in enabled: RuleSet) -> Bool {
        enabled.containsAny(indices)
    }
}
