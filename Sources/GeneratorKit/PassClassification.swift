import Foundation

/// Names of the pass-classification marker protocols defined in
/// `Sources/SwiftiomaticKit/PassClassification/PassClassification.swift`.
///
/// `RuleCollector` looks for these names in each rule's inheritance clause to determine
/// the rule's classification. Keep in sync with the protocol declarations — if a marker
/// is renamed there, rename it here too.
package enum PassMarker {
    package static let readLocalities: Set<String> = [
        "TokenLocalFormatRule",
        "NodeLocalFormatRule",
        "DeclLocalFormatRule",
        "BlockLocalFormatRule",
        "FileGlobalFormatRule",
    ]

    package static let writeSurfaces: Set<String> = [
        "TriviaOnlyFormatRule",
        "TokenTextFormatRule",
        "ExpressionRewriteFormatRule",
        "DeclRewriteFormatRule",
        "ListReshapingFormatRule",
    ]

    package static let optionalMarkers: Set<String> = [
        "IdempotentFormatRule",
        "MonotonicWriteFormatRule",
        "MustRunAfterFormatRule",
        "MustNotShareWithFormatRule",
    ]
}

/// The pass classification a rule has declared via marker protocols.
package struct PassClassification: Hashable, Sendable {
    package let readLocality: String?
    package let writeSurface: String?
    package let markers: [String]

    package init(readLocality: String?, writeSurface: String?, markers: [String]) {
        self.readLocality = readLocality
        self.writeSurface = writeSurface
        self.markers = markers
    }

    /// `true` when the rule declared no classification — it stays in the catch-all pass.
    package var isUnclassified: Bool {
        readLocality == nil && writeSurface == nil && markers.isEmpty
    }
}

/// One pass in the multi-pass rewrite pipeline.
package struct GeneratedPass: Sendable {
    /// Identifier used in generated code (e.g. `catchAll`, `tokenLocal`).
    package let name: String
    /// Human-readable label used in `PassManifest.md`.
    package let label: String
    /// Execution shape.
    package let kind: Kind
    /// Rule type names assigned to this pass, sorted.
    package let ruleTypeNames: [String]

    package enum Kind: Sendable {
        /// Each rule runs as its own full-tree `SyntaxRewriter` walk. Used for the
        /// catch-all and any rule a future static check can't safely co-walk.
        case soloPerRule
        /// A single combined `SyntaxRewriter` walk interleaves the listed rules. Not
        /// emitted by `ain-794` — `7x2-5eg` and follow-ups land the combined-rewriter
        /// codegen alongside their first real migrations.
        case combined
    }

    package init(name: String, label: String, kind: Kind, ruleTypeNames: [String]) {
        self.name = name
        self.label = label
        self.kind = kind
        self.ruleTypeNames = ruleTypeNames
    }
}

/// Computes the multi-pass partition from classified rules.
///
/// Today's behavior: every rule lands in a single catch-all `soloPerRule` pass — same
/// shape as the legacy `RewritePipeline`. As rules acquire `PassClassification`s in
/// follow-up issues, the partitioner will split them into combined passes guided by the
/// taxonomy in `qm5-qyp` → `## Static-Validation Taxonomy`.
package enum PassPartitioner {
    /// Returns the passes in execution order. Catch-all is always last.
    package static func partition(
        rules: [(typeName: String, classification: PassClassification?)]
    ) -> [GeneratedPass] {
        let catchAll = GeneratedPass(
            name: "catchAll",
            label: "Catch-all (one rule per walk; legacy behavior)",
            kind: .soloPerRule,
            ruleTypeNames: rules.map(\.typeName).sorted()
        )
        return [catchAll]
    }
}
