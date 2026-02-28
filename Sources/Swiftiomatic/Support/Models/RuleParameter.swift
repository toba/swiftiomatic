/// A configuration parameter for rules.
@preconcurrency
struct RuleParameter<T: Equatable & Sendable>: Equatable, Sendable {
    /// The severity that should be assigned to the violation of this parameter's value is met.
    let severity: ViolationSeverity
    /// The value to configure the rule.
    let value: T
}
