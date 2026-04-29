import SwiftSyntax

/// Controls the layout of nested function/initializer calls where the sole
/// argument to one call is another call.
///
/// **Inline mode**: Collapses deeply nested calls into the most compact form
/// that fits the line width, trying each layout in order:
///
/// 1. Fully inline:
///    ```swift
///    result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
///    ```
///
/// 2. Outer inline, inner wrapped:
///    ```swift
///    result = ExprSyntax(ForceUnwrapExprSyntax(
///        expression: result,
///        trailingTrivia: trivia
///    ))
///    ```
///
/// 3. Fully wrapped (outer on new line, inner inline):
///    ```swift
///    result = ExprSyntax(
///        ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)
///    )
///    ```
///
/// 4. Fully nested (no change).
///
/// **Wrap mode**: Expands any compact form into the fully nested form with each
/// call and its arguments on separate indented lines.
///
/// Lint: A nested call whose layout doesn't match the mode raises a warning.
///
/// Rewrite: The call tree is reformatted to match the mode.
final class NestedCallLayout: StaticFormatRule<NestedCallLayoutConfiguration>, @unchecked Sendable {
    override class var key: String { "nestedCallLayout" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: NestedCallLayoutConfiguration {
        var config = NestedCallLayoutConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    static func transform(
        _ node: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        _ = parent
        return applyNestedCallLayout(node, context: context)
    }
}

// MARK: - Configuration

package struct NestedCallLayoutConfiguration: SyntaxRuleValue {
    package enum Mode: String, Codable, Sendable {
        /// Collapse nested calls to the most compact form that fits.
        case inline
        /// Expand nested calls to fully nested form.
        case wrap
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// `inline` collapses nested calls to the most compact form that fits;
    /// `wrap` expands them to fully nested form.
    package var mode: Mode = .inline

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) { self.rewrite = rewrite }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.mode =
            try container.decodeIfPresent(Mode.self, forKey: .mode)
            ?? .inline
    }
}
