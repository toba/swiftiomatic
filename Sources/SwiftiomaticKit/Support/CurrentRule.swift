import SwiftiomaticSyntax

/// Task-local storage for the currently executing rule
///
/// Allows SourceKit request handling to determine certain properties without
/// modifying function signatures throughout the codebase.
package enum CurrentRule {
  /// The identifier of the currently executing rule
  ///
  /// Used to check whether the active rule is allowed to make SourceKit requests.
  @TaskLocal package static var identifier: String?

  /// Bypasses the rule-context requirement for SourceKit requests
  ///
  /// Should only be set for essential operations like querying the Swift version.
  @TaskLocal package static var allowSourceKitRequestWithoutRule = false

  /// Executes a closure with the rule's identifier set as the current rule context.
  package static func withContext<T>(
    of rule: any Rule,
    _ body: () throws -> T,
  ) rethrows -> T {
    try $identifier.withValue(type(of: rule).identifier, operation: body)
  }

  /// Executes an async closure with the rule's identifier set as the current rule context.
  package static func withContext<T>(
    of rule: any Rule,
    _ body: () async throws -> T,
  ) async rethrows -> T {
    try await $identifier.withValue(type(of: rule).identifier, operation: body)
  }
}
