import SwiftSyntax

/// Apply a rule's `static func transform(_:parent:context:)` to a mutable
/// node, gating on `context.shouldFormat` and re-narrowing the result to the
/// input node type. Compact-pipeline merged rewrite functions (Phase 4 of
/// `ddi-wtv`) used to inline this 6-line ladder per rule:
///
/// ```swift
/// if context.shouldFormat(SomeRule.self, node: Syntax(result)) {
///     if let next = SomeRule.transform(
///         result, parent: parent, context: context
///     ).as(SomeNodeSyntax.self) {
///         result = next
///     }
/// }
/// ```
///
/// becomes:
///
/// ```swift
/// applyRule(SomeRule.self, to: &result, parent: parent, context: context,
///           transform: SomeRule.transform)
/// ```
///
/// If the rule produces a different concrete node kind (e.g. an `ExprSyntax`
/// widening), the result is silently dropped — same behaviour as the inlined
/// `.as(N.self)` ladder it replaces.
func applyRule<R: SyntaxRule, N: SyntaxProtocol, Out: SyntaxProtocol>(
    _ rule: R.Type,
    to node: inout N,
    parent: Syntax?,
    context: Context,
    transform: (N, Syntax?, Context) -> Out
) {
    guard context.shouldFormat(rule, node: Syntax(node)) else { return }
    if let next = transform(node, parent, context).as(N.self) {
        node = next
    }
}
