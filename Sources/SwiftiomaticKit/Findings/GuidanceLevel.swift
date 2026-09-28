import ConfigurationKit

/// How strong the advice of a rule is.
///
/// The guidance level is a fixed property of the rule. It is separate from the severity, which the
/// configuration sets with the `lint` value.
///
/// The five levels follow the scale of the SwiftFairy guidance. A `NOT` level states the same
/// strength as its positive level, for a rule whose advice is to remove or avoid a code shape.
public enum GuidanceLevel: String, Codable, Sendable, CaseIterable {
    /// The change is required. Without it the code is incorrect: it can deadlock, hang, leak or
    /// crash, or it breaks a contract of the language or framework that the code depends on.
    case must = "MUST"

    /// The code shape is prohibited, with the strength of `MUST`. The rule reports a construct that
    /// is incorrect wherever it appears.
    case mustNot = "MUST NOT"

    /// The change improves the code in almost every case. Keep the code only for a documented
    /// exception.
    case should = "SHOULD"

    /// The code shape is to be avoided, with the strength of `SHOULD`. The rule reports a construct
    /// that is wrong in almost every case.
    case shouldNot = "SHOULD NOT"

    /// The change is a judgment call, such as a size threshold. Weigh it against the code.
    case consider = "CONSIDER"
}

extension ConfigurationGroup {
    /// The guidance level of a rule in this group that does not declare its own level.
    var defaultGuidance: GuidanceLevel { self == .metrics ? .consider : .should }
}
