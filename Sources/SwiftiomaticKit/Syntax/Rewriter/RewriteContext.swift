import SwiftSyntax

/// Per-node cache of the inputs needed to evaluate `shouldRewrite` or `shouldFormat` for any rule
/// at a single node. Building one of these once per `visit(_:)` override and passing it to every
/// per-rule check eliminates the repeated `isInsideSelection` + `startLocation` work that the
/// node-taking gate entry points otherwise perform for every rule on every node.
extension Context {
    struct Gate {
        let node: Syntax
        let location: SourceLocation
    }

    /// Builds a gate for `node` , or returns `nil` when the node falls outside the active selection
    /// (in which case no rule should run).
    ///
    /// The cached location comes from `gateLocation(for:)` , so a file-wide rule on
    /// `SourceFileSyntax` gates at the end of the file exactly as the node-taking entry points do.
    @inline(__always)
    func gate(for node: some SyntaxProtocol) -> Gate? {
        let s = Syntax(node)
        guard s.isInsideSelection(selection) else { return nil }
        return Gate(node: s, location: gateLocation(for: s))
    }

    /// Gate-aware variant of `shouldRewrite(_:at:)` . Skips the per-call `isInsideSelection`
    /// traversal and `startLocation` work by reusing the values cached on the gate.
    @inline(__always)
    func shouldRewrite<R: SyntaxRule>(_ rule: R.Type, gate: Gate) -> Bool {
        isUnmasked(rule, in: rewriteEnabledRules, at: gate.location)
    }

    /// Gate-aware variant of `shouldFormat(_:node:)` used by `LintPipeline` . Reuses the location
    /// cached on the gate, and stays generic on `R` so a disabled rule costs one set probe instead
    /// of the existential metatype conversion `shouldFormat(ruleType:node:)` pays per call.
    @inline(__always)
    func shouldFormat<R: SyntaxRule>(_ rule: R.Type, gate: Gate) -> Bool {
        isUnmasked(rule, in: enabledRules, at: gate.location)
    }
}
