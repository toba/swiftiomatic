// sm:ignore useFinalClasses, useStaticNotClassFunc

// Subclassed by every lint rule; `class var` is required so subclass overrides dispatch through
// the vtable when accessed via `any SyntaxRule.Type` existentials.
import Foundation
import SwiftSyntax
import ConfigurationKit

/// A rule that lints a given file.
class LintSyntaxRule<V: SyntaxRuleValue>: SyntaxVisitor, InstanceSyntaxRule, @unchecked Sendable {
    typealias Value = V

    /// The context in which the rule is executed.
    let context: Context

    // class var so subclass overrides dispatch correctly through the vtable when accessed via
    // protocol existentials (any SyntaxRule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last ?? "")
        return configurationKey(forTypeName: name)
    }
    class var group: ConfigurationGroup? { nil }
    class var guidance: GuidanceLevel { group?.defaultGuidance ?? .should }
    class var defaultValue: V {
        var config = V()
        config.rewrite = false
        return config
    }

    /// The rule's dense index, read once so that a finding does not look it up.
    let ruleIndex: Int?

    /// Creates a new rule in a given context.
    required init(context: Context) {
        self.context = context
        ruleIndex = ConfigurationRegistry.ruleIndex(of: Self.self)
        super.init(viewMode: .sourceAccurate)
    }
}
