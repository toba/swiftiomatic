import ConfigurationKit
import SwiftSyntax

/// A rule that both formats and lints a given file.
class RewriteSyntaxRule<V: SyntaxRuleValue>: SyntaxRewriter, InstanceSyntaxRule, @unchecked Sendable {
    typealias Value = V

    /// The context in which the rule is executed.
    let context: Context

    // class var so subclass overrides dispatch correctly through the vtable
    // when accessed via protocol existentials (any Rule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last ?? "")
        return configurationKey(forTypeName: name)
    }
    class var group: ConfigurationGroup? { nil }
    class var defaultValue: V { V() }

    /// Creates a new RewriteSyntaxRule in the given context.
    required init(context: Context) { self.context = context }

    override func visitAny(_ node: Syntax) -> Syntax? {
        // If the rule is not enabled, return the node unmodified to short-circuit the
        // typed visit and child recursion. Otherwise return nil to fall through to the
        // standard dispatch.
        //
        // We must use the non-generic `shouldFormat(ruleType:node:)` overload here:
        // this method runs on `RewriteSyntaxRule<V>`, so a generic `<R>` overload
        // would bind R to the static base type and look up the wrong configuration
        // key (e.g. `"rewriteSyntaxRule<BasicRuleValue>"`). The non-generic overload
        // takes `any SyntaxRule.Type`, which preserves the dynamic subclass identity.
        guard context.shouldFormat(ruleType: type(of: self), node: node) else { return node }
        return nil
    }
}
