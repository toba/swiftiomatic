import SwiftSyntax

/// Controls whether switch case bodies are wrapped (multiline) or inlined.
///
/// **Wrap mode** (default): Each case body appears on its own indented line
/// below the case label.
///
/// ```swift
/// switch piece {
/// case .backslashes, .pounds:
///     piece.write(to: &result)
/// default:
///     break
/// }
/// ```
///
/// **Adaptive mode**: Each case is independently inlined if it has a single
/// statement that fits within the configured line length; cases that don't fit
/// or have multiple statements remain wrapped.
///
/// ```swift
/// switch piece {
/// case .backslashes, .pounds: piece.write(to: &result)
/// default: break
/// }
/// ```
///
/// Lint: A case body whose formatting doesn't match the mode raises a warning.
///
/// Rewrite: The case body is wrapped or inlined to match the mode.
final class WrapSwitchCaseBodies: StaticFormatRule<SwitchCaseBodiesConfiguration>, @unchecked Sendable {
    override class var key: String { "switchCaseBodies" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: SwitchCaseBodiesConfiguration {
        var config = SwitchCaseBodiesConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    static func transform(
        _ node: SwitchCaseSyntax,
        parent: Syntax?,
        context: Context
    ) -> SwitchCaseSyntax {
        let mode = context.configuration[Self.self].mode
        switch mode {
        case .wrap: return wrapCase(node, context: context)
        case .adaptive: return adaptiveCase(node, context: context)
        }
    }
}

// MARK: - Wrap Mode

extension WrapSwitchCaseBodies {

    fileprivate static func wrapCase(_ node: SwitchCaseSyntax, context: Context) -> SwitchCaseSyntax {
        // Only act on cases that are currently inline (body on same line as label).
        guard isInline(node) else { return node }
        guard node.statements.count > 0 else { return node }

        Self.diagnose(.wrapCaseBody, on: node, context: context)

        let baseIndent = caseIndent(node)
        let bodyIndent = baseIndent + "    "

        var result = node

        // Put statements on a new line with body indentation.
        var items = Array(result.statements)
        items[0] = items[0].with(
            \.leadingTrivia,
            .newline + Trivia(stringLiteral: bodyIndent)
        )

        // Ensure the colon has a clean trailing trivia (no leftover spaces).
        result = result.withUpdatedColon(trailingTrivia: [])
        result.statements = CodeBlockItemListSyntax(items)

        return result
    }
}

// MARK: - Adaptive Mode

extension WrapSwitchCaseBodies {

    fileprivate static func adaptiveCase(_ node: SwitchCaseSyntax, context: Context) -> SwitchCaseSyntax {
        // Only inline single-statement cases.
        guard node.statements.count == 1 else { return node }
        // Skip if already inline.
        guard !isInline(node) else { return node }

        let bodyText = node.statements.first!.trimmedDescription
        let labelText = labelText(node)

        // "case .foo: body" or "default: body"
        let totalLength = caseIndent(node).count + labelText.count + " ".count + bodyText.count
        let maxLength = context.configuration[LineLength.self]

        guard totalLength <= maxLength else { return node }

        Self.diagnose(.inlineCaseBody, on: node, context: context)

        var result = node

        // Put the statement on the same line, one space after the colon.
        var items = Array(result.statements)
        items[0] = items[0].with(\.leadingTrivia, .space)
        // Remove any trailing newline/indent from the statement.
        items[0] = items[0].with(\.trailingTrivia, [])
        result.statements = CodeBlockItemListSyntax(items)

        return result
    }
}

// MARK: - Helpers

extension WrapSwitchCaseBodies {

    /// Whether the case body is on the same line as the label (no newline before first statement).
    fileprivate static func isInline(_ node: SwitchCaseSyntax) -> Bool {
        guard let firstStmt = node.statements.first else { return true }
        return !firstStmt.leadingTrivia.containsNewlines
    }

    /// The indentation of the case label.
    fileprivate static func caseIndent(_ node: SwitchCaseSyntax) -> String {
        node.leadingTrivia.indentation
    }

    /// The text of the case label including the colon (e.g. "case .foo:" or "default:").
    fileprivate static func labelText(_ node: SwitchCaseSyntax) -> String {
        switch node.label {
        case .case(let caseLabel):
            return caseLabel.trimmedDescription
        case .default(let defaultLabel):
            return defaultLabel.trimmedDescription
        }
    }
}

extension SwitchCaseSyntax {
    /// Returns a copy with the colon's trailing trivia updated.
    fileprivate func withUpdatedColon(trailingTrivia: Trivia) -> SwitchCaseSyntax {
        var result = self
        switch result.label {
        case .case(var caseLabel):
            caseLabel.colon = caseLabel.colon.with(\.trailingTrivia, trailingTrivia)
            result.label = .case(caseLabel)
        case .default(var defaultLabel):
            defaultLabel.colon = defaultLabel.colon.with(\.trailingTrivia, trailingTrivia)
            result.label = .default(defaultLabel)
        }
        return result
    }
}

// MARK: - Finding Messages

extension Finding.Message {
    fileprivate static let wrapCaseBody: Finding.Message =
        "wrap switch case body onto a new line"

    fileprivate static let inlineCaseBody: Finding.Message =
        "place switch case body on same line as label"
}

// MARK: - Configuration

package struct SwitchCaseBodiesConfiguration: SyntaxRuleValue {
    package enum Mode: String, Codable, Sendable {
        /// Each case body appears on its own indented line below the label.
        case wrap
        /// Inline each case independently if it has a single statement fitting
        /// within the configured line length; leave others wrapped.
        case adaptive
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// `wrap` puts each case body on its own indented line; `adaptive` keeps
    /// short single-statement cases inline when they fit, wraps the rest.
    package var mode: Mode = .wrap

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) { self.rewrite = rewrite }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.mode =
            try container.decodeIfPresent(Mode.self, forKey: .mode)
            ?? .wrap
    }
}
