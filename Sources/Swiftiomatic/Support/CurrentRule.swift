/// Task-local storage for the currently executing rule
///
/// Allows SourceKit request handling to determine certain properties without
/// modifying function signatures throughout the codebase.
enum CurrentRule {
    /// The identifier of the currently executing rule
    ///
    /// Used to check whether the active rule is allowed to make SourceKit requests.
    @TaskLocal static var identifier: String?

    /// Bypasses the rule-context requirement for SourceKit requests
    ///
    /// Should only be set for essential operations like querying the Swift version.
    @TaskLocal static var allowSourceKitRequestWithoutRule = false
}
