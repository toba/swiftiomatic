import SwiftSyntax

/// A rule that both formats and lints a given file.
class RewriteSyntaxRule<V: SyntaxRuleValue>: SyntaxRewriter, SyntaxRule, @unchecked Sendable {
    typealias Value = V

    /// The context in which the rule is executed.
    let context: Context

    // class var so subclass overrides dispatch correctly through the vtable
    // when accessed via protocol existentials (any Rule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last!)
        return name.prefix(1).lowercased() + name.dropFirst()
    }
    class var group: ConfigurationGroup? { nil }
    class var defaultValue: V { V() }

    /// Creates a new RewriteSyntaxRule in the given context.
    required init(context: Context) { self.context = context }

    override func visitAny(_ node: Syntax) -> Syntax? {
        // If the rule is not enabled, then return the node unmodified; otherwise, returning nil tells
        // SwiftSyntax to continue with the standard dispatch.
        guard context.shouldFormat(type(of: self), node: node) else { return node }
        return nil
    }
}
