import SwiftSyntax

/// Shared concurrency detection helpers used by both
/// `ConcurrencyModernizationCheck` (suggest) and `ConcurrencyModernizationRule` (lint).
enum ConcurrencyDetectionHelpers {
    /// Whether a function parameter looks like a completion handler.
    static func isCompletionHandlerParam(_ param: FunctionParameterSyntax) -> Bool {
        let paramName = param.firstName.text
        let isCompletion =
            paramName == "completion" || paramName == "completionHandler"
                || paramName == "handler" || paramName == "callback"
        return isCompletion && param.type.trimmedDescription.contains("@escaping")
    }

    /// Whether a function call expression is a `DispatchQueue.*.async` call.
    static func isDispatchQueueAsync(_ callee: String) -> Bool {
        callee.contains("DispatchQueue") && callee.hasSuffix(".async")
    }

    /// Whether an inheritance clause contains `@unchecked Sendable`.
    static func hasUncheckedSendable(_ clause: InheritanceClauseSyntax?) -> Bool {
        guard let clause else { return false }
        return clause.trimmedDescription.contains("@unchecked Sendable")
    }
}
