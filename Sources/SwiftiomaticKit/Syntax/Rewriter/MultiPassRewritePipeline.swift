// The multi-pass rewrite pipeline that will replace `RewritePipeline` once every rule
// is classified into a pass (issue `qm5-qyp`, child `ain-794`).
//
// Today: a single catch-all pass that runs each rule one-tree-walk-at-a-time —
// functionally identical to `RewritePipeline.rewrite(_:)`. The `Generator` emits the
// `rewrite(_:)` extension into `Pipelines+Generated.swift` from the rules detected by
// `RuleCollector`, choosing the pass for each rule based on its conformance to the
// markers in `Sources/SwiftiomaticKit/PassClassification/PassClassification.swift`.
//
// Tomorrow (after `7x2-5eg` and follow-ups): each non-empty pass is a single combined
// `SyntaxRewriter` walk that interleaves all rules assigned to it. The catch-all pass
// remains as the migration shelf for rules that don't fit any other bucket.
//
// The driver is gated behind `DebugOptions.useMultiPassPipeline`. While the flag is
// off (default), `RewriteCoordinator` calls `RewritePipeline` exactly as before.
struct MultiPassRewritePipeline {
    /// The formatter context.
    let context: Context

    /// Creates a new multi-pass rewrite pipeline.
    init(context: Context) {
        self.context = context
    }
}
