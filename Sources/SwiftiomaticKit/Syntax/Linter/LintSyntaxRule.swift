import Foundation
import SwiftSyntax

/// A rule that lints a given file.
class LintSyntaxRule<V: SyntaxRuleValue>: SyntaxVisitor, SyntaxRule {
    typealias Value = V

    /// The context in which the rule is executed.
    let context: Context

    // class var so subclass overrides dispatch correctly through the vtable
    // when accessed via protocol existentials (any SyntaxRule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last!)
        return name.prefix(1).lowercased() + name.dropFirst()
    }
    class var group: ConfigurationGroup? { nil }
    class var defaultValue: V {
        var v = V()
        v.rewrite = false
        return v
    }

    /// Creates a new rule in a given context.
    required init(context: Context) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }
}
