import SwiftSyntax

/// Enforce switch case label indentation style.
///
/// Two styles are supported via `SwitchCaseIndentationConfiguration.Style`:
/// - `flush`: `case` labels align with the `switch` keyword (default).
/// - `indented`: `case` labels are indented one level from `switch`.
///
/// Lint: Raised when a `case` or `default` label doesn't match the configured style.
///
/// Rewrite: Case labels, bodies, and the closing brace are reindented to match.
final class SwitchCaseIndentation: RewriteSyntaxRule<SwitchCaseIndentationConfiguration>, @unchecked Sendable {
    override class var key: String { "switchCases" }
    override class var group: ConfigurationGroup? { .indentation }

    override class var defaultValue: SwitchCaseIndentationConfiguration {
        var config = SwitchCaseIndentationConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    // Diagnose against the pre-traversal node so finding source locations
    // are accurate. The compact-pipeline rewrite (in
    // `Rewrites/Stmts/SwitchExpr.swift::applySwitchCaseIndentation`) handles
    // the rewrite without diagnose.
    static func willEnter(_ node: SwitchExprSyntax, context: Context) {
        let style = context.configuration[Self.self].style
        let switchIndent = Self.lineIndentationOf(node.switchKeyword)
        let indent: String =
            switch context.configuration[IndentationSetting.self] {
                case .spaces(let count): String(repeating: " ", count: count)
                case .tabs(let count): String(repeating: "\t", count: count)
            }

        let expectedCaseIndent: String
        switch style {
            case .flush: expectedCaseIndent = switchIndent
            case .indented: expectedCaseIndent = switchIndent + indent
        }

        for caseListItem in node.cases {
            switch caseListItem {
                case .switchCase(let switchCase):
                    let currentCaseIndent = switchCase.leadingTrivia.indentation
                    if currentCaseIndent != expectedCaseIndent {
                        let message: Finding.Message = style == .flush
                            ? .alignCaseWithSwitch : .indentCaseFromSwitch
                        Self.diagnose(message, on: switchCase.label, context: context)
                    }
                case .ifConfigDecl: break
            }
        }
    }

    /// Static counterpart of the legacy instance `lineIndentation`, used by
    /// the compact-pipeline `willEnter`.
    static func lineIndentationOf(_ token: TokenSyntax) -> String {
        var current = token
        while !current.leadingTrivia.containsNewlines {
            guard let prev = current.previousToken(viewMode: .sourceAccurate) else {
                return ""
            }
            current = prev
        }
        return current.leadingTrivia.indentation
    }
}

// MARK: - Configuration

package struct SwitchCaseIndentationConfiguration: SyntaxRuleValue {
    package enum Style: String, Codable, Sendable {
        /// Case labels align with the `switch` keyword.
        case flush
        /// Case labels are indented one level from the `switch` keyword.
        case indented
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// `flush` aligns case labels with the `switch` keyword; `indented`
    /// indents them one level beneath it.
    package var style: Style = .flush

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) { self.rewrite = rewrite }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.style = try container.decodeIfPresent(Style.self, forKey: .style) ?? .flush
    }
}

extension Finding.Message {
    fileprivate static let alignCaseWithSwitch: Finding.Message =
        "align 'case' with 'switch' keyword"
    fileprivate static let indentCaseFromSwitch: Finding.Message =
        "indent 'case' one level from 'switch' keyword"
}
