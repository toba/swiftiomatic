import SwiftSyntax

/// Flag framework types the OS 27 SDK replaced wholesale.
///
/// - `MXMetricManager` and its payload types → `MetricManager` . The MetricKit headers carry
///   `API_DEPRECATED("Use MetricManager instead.")` on the manager, the subscriber protocol and
///   each payload type.
/// - `NSBundleResourceRequest` → Background Assets. The Foundation interface marks it
///   `deprecated: 27` on iOS, tvOS, watchOS and visionOS. It was never available on macOS.
///
/// The rule matches the type name wherever it appears: a conformance, an annotation, a generic
/// argument or a static member reference such as `MXMetricManager.shared` .
///
/// Lint: A reference to one of these types raises a warning.
final class FlagSupersededFrameworkAPI: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        flag(node.name)
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        flag(node.baseName)
        return .visitChildren
    }

    private func flag(_ token: TokenSyntax) {
        switch token.text {
            case "MXMetricManager", "MXMetricManagerSubscriber":
                diagnose(.useMetricManager, on: token)
            case "MXMetricPayload", "MXDiagnosticPayload": diagnose(.useMetricReports, on: token)
            case "NSBundleResourceRequest": diagnose(.useBackgroundAssets, on: token)
            default: break
        }
    }
}

fileprivate extension Finding.Message {
    static let useMetricManager: Finding.Message =
        "'MXMetricManager' is deprecated — use 'MetricManager'"
    static let useMetricReports: Finding.Message =
        "the 'MX' payload types are deprecated — read 'MetricManager.metricReports' instead"
    static let useBackgroundAssets: Finding.Message =
        "'NSBundleResourceRequest' is deprecated on OS 27 — stage assets with Background Assets instead"
}
