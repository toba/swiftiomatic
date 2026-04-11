import SwiftSyntax

/// Shared concurrency pattern detection for GCD and completion-handler code
///
/// Used by both `ConcurrencyModernizationCheck` (suggest) and
/// `ConcurrencyModernizationRule` (lint).
enum ConcurrencyPatternDetector {
  /// Whether a function parameter looks like a completion handler
  ///
  /// Matches names like `completion`, `handler`, or `callback` that are
  /// annotated with `@escaping`.
  ///
  /// - Parameters:
  ///   - param: The function parameter to inspect.
  /// - Returns: `true` if the parameter appears to be a completion handler.
  static func isCompletionHandlerParam(_ param: FunctionParameterSyntax) -> Bool {
    let paramName = param.firstName.text
    let isCompletion =
      paramName == "completion" || paramName == "completionHandler"
      || paramName == "handler" || paramName == "callback"
    return isCompletion && param.type.trimmedDescription.contains("@escaping")
  }

  /// Whether a callee string represents a `DispatchQueue.*.async` call
  ///
  /// - Parameters:
  ///   - callee: The trimmed description of the called expression.
  /// - Returns: `true` if the callee matches the `DispatchQueue` async pattern.
  static func isDispatchQueueAsync(_ callee: String) -> Bool {
    callee.contains("DispatchQueue") && callee.hasSuffix(".async")
  }

  /// Whether an inheritance clause contains `@unchecked Sendable`
  ///
  /// - Parameters:
  ///   - clause: The inheritance clause to inspect, or `nil`.
  /// - Returns: `true` if the clause includes `@unchecked Sendable`.
  static func hasUncheckedSendable(_ clause: InheritanceClauseSyntax?) -> Bool {
    guard let clause else { return false }
    return clause.trimmedDescription.contains("@unchecked Sendable")
  }
}
