// sm:ignore preferFinalClasses, preferStaticOverClassFunc
// Subclassed by every structural format rule; `class var` is required so subclass overrides
// dispatch through the vtable when accessed via `any SyntaxRule.Type` existentials.
import SwiftSyntax
import ConfigurationKit

/// A rule that runs as a discrete structural pass over a settled tree.
///
/// Sister to `StaticFormatRule<V>` (compact-pipeline node-local rewrites dispatched in one walk)
/// and `LintSyntaxRule<V>` (lint rules interleaved in the lint pipeline). Structural passes act per
/// file or per scope and need a settled tree to make decisions; they're invoked from
/// `RewriteCoordinator.runCompactPipeline` after stage one.
///
/// Per-pass gating (selection, `// sm:ignore` , configuration `isActive` ) lives at the
/// dispatcher's call site — see `RewriteCoordinator` — not in a `visitAny` shim, so each rule walks
/// only when it's going to run.
class StructuralFormatRule<V: SyntaxRuleValue>: SyntaxRewriter, InstanceSyntaxRule,
    @unchecked Sendable
{
    typealias Value = V

    /// The context in which the rule is executed.
    let context: Context

    // class var so subclass overrides dispatch correctly through the vtable when accessed via
    // protocol existentials (any Rule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last ?? "")
        return configurationKey(forTypeName: name)
    }
    class var group: ConfigurationGroup? { nil }
    class var defaultValue: V { V() }

    /// Creates a new StructuralFormatRule in the given context.
    required init(context: Context) { self.context = context }
}
