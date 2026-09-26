import ConfigurationKit

/// How strong the advice of a rule is.
///
/// The guidance level is a fixed property of the rule. It is separate from the severity, which the
/// configuration sets with the `lint` value.
public enum GuidanceLevel: String, Codable, Sendable, CaseIterable {
    /// The code can deadlock, hang, leak or crash as written.
    case must = "MUST"

    /// The change improves the code in almost every case.
    case should = "SHOULD"

    /// The change is a judgment call, such as a size threshold.
    case consider = "CONSIDER"
}

extension ConfigurationGroup {
    /// The guidance level of a rule in this group that does not declare its own level.
    var defaultGuidance: GuidanceLevel { self == .metrics ? .consider : .should }
}
