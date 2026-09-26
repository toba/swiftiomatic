/// What one location in a finding's evidence matched.
///
/// A role tells the reader why the location is part of the finding, so the reader does not have to
/// read the source again to find out.
public enum EvidenceRole: String, Codable, Sendable, CaseIterable {
    /// The location where the rule reports the finding.
    case finding

    /// A related location with no more specific role. Notes get this role by default.
    case related

    /// The declaration that owns the matched code.
    case owner

    /// A member of the owner.
    case member

    /// A value that flows into the matched code.
    case input

    /// A closure that holds the matched code.
    case closure

    /// A branch of a conditional statement.
    case branch

    /// The work that the rule objects to.
    case work
}
