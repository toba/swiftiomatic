import SwiftSyntax

/// Enforce switch case label indentation style.
///
/// Two styles are supported via `IndentSwitchCasesConfiguration.Style` :
/// - `flush` : `case` labels align with the `switch` keyword (default).
/// - `indented` : `case` labels are indented one level from `switch` .
///
/// Lint: Raised when a `case` or `default` label doesn't match the configured style.
///
/// Rewrite: Case labels, bodies, and the closing brace are reindented to match.
final class IndentSwitchCases: StaticFormatRule<IndentSwitchCasesConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .indentation }

    override class var defaultValue: IndentSwitchCasesConfiguration {
        var config = IndentSwitchCasesConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    /// Diagnose against the pre-traversal node so finding source locations are accurate.
    static func willEnter(_ node: SwitchExprSyntax, context: Context) {
        let style = context.configuration[Self.self].style
        let switchIndent = Self.lineIndentationOf(node.switchKeyword)
        let indent =
            switch context.configuration[IndentationSetting.self] {
                case let .spaces(count): String(repeating: " ", count: count)
                case let .tabs(count): String(repeating: "\t", count: count)
            }

        let expectedCaseIndent: String

        switch style {
            case .flush: expectedCaseIndent = switchIndent
            case .indented: expectedCaseIndent = switchIndent + indent
        }

        for caseListItem in node.cases {
            switch caseListItem {
                case let .switchCase(switchCase):
                    let currentCaseIndent = switchCase.leadingTrivia.indentation

                    if currentCaseIndent != expectedCaseIndent {
                        let message: Finding.Message = style == .flush
                            ? .alignCaseWithSwitch
                            : .indentCaseFromSwitch
                        Self.diagnose(message, on: switchCase.label, context: context)
                    }
                case .ifConfigDecl: break
            }
        }
    }

    /// Reindent `case` labels, bodies, and the closing brace to match the configured style. Called
    /// from `CompactSyntaxRewriter.visit(_: SwitchExprSyntax)` .
    static func apply(_ node: SwitchExprSyntax, context: Context) -> SwitchExprSyntax {
        var switchExpr = node
        let style = context.configuration[Self.self].style
        let switchIndent = lineIndentationOf(switchExpr.switchKeyword)
        let indent =
            switch context.configuration[IndentationSetting.self] {
                case let .spaces(count): String(repeating: " ", count: count)
                case let .tabs(count): String(repeating: "\t", count: count)
            }

        let expectedCaseIndent: String
        let expectedBodyIndent: String

        switch style {
            case .flush:
                expectedCaseIndent = switchIndent
                expectedBodyIndent = switchIndent + indent
            case .indented:
                expectedCaseIndent = switchIndent + indent
                expectedBodyIndent = switchIndent + indent + indent
        }

        let cases = Array(switchExpr.cases)
        guard !cases.isEmpty else { return node }

        var modifiedCases = cases
        var modified = false

        for i in 0..<cases.count {
            switch cases[i] {
                case var .switchCase(switchCase):
                    let currentCaseIndent = switchCase.leadingTrivia.indentation

                    if currentCaseIndent != expectedCaseIndent {
                        switchCase = reindentCase(
                            switchCase,
                            caseIndent: expectedCaseIndent,
                            bodyIndent: expectedBodyIndent
                        )
                        modifiedCases[i] = .switchCase(switchCase)
                        modified = true
                    }

                case .ifConfigDecl: break
            }
        }

        if modified { switchExpr.cases = SwitchCaseListSyntax(modifiedCases) }

        let braceIndent = switchExpr.rightBrace.leadingTrivia.indentation

        if braceIndent != switchIndent {
            switchExpr.rightBrace = switchExpr.rightBrace.with(
                \.leadingTrivia,
                replaceIndentation(in: switchExpr.rightBrace.leadingTrivia, with: switchIndent)
            )
            modified = true
        }

        return modified ? switchExpr : node
    }

    private static func reindentCase(
        _ switchCase: SwitchCaseSyntax,
        caseIndent: String,
        bodyIndent: String
    ) -> SwitchCaseSyntax {
        var result = switchCase

        result = result.with(
            \.leadingTrivia,
            replaceIndentation(in: switchCase.leadingTrivia, with: caseIndent)
        )

        let stmts = Array(result.statements)
        var modifiedStmts = stmts

        for j in 0..<stmts.count {
            let stmt = stmts[j]
            modifiedStmts[
                j] = stmt.with(
                    \.leadingTrivia,
                    replaceIndentation(in: stmt.leadingTrivia, with: bodyIndent)
                )
        }
        result.statements = CodeBlockItemListSyntax(modifiedStmts)
        return result
    }

    private static func replaceIndentation(in trivia: Trivia, with indent: String) -> Trivia {
        var pieces = Array(trivia.pieces)

        if let lastNewlineIndex = pieces.lastIndex(where: {
            if case .newlines = $0 { return true }
            if case .carriageReturns = $0 { return true }
            if case .carriageReturnLineFeeds = $0 { return true }
            return false
        }) {
            let afterNewline = lastNewlineIndex + 1

            while afterNewline < pieces.count {
                switch pieces[afterNewline] {
                    case .spaces, .tabs: pieces.remove(at: afterNewline)
                    default: break
                }
                if afterNewline < pieces.count {
                    switch pieces[afterNewline] {
                        case .spaces, .tabs: continue
                        default: break
                    }
                }
                break
            }
            if !indent.isEmpty { pieces.insert(.spaces(indent.count), at: afterNewline) }
        }

        return .init(pieces: pieces)
    }

    /// Static counterpart of the legacy instance `lineIndentation` , used by the compact-pipeline
    /// `willEnter` and `apply` .
    static func lineIndentationOf(_ token: TokenSyntax) -> String {
        var current = token

        while !current.leadingTrivia.containsNewlines {
            guard let prev = current.previousToken(viewMode: .sourceAccurate) else { return "" }
            current = prev
        }
        return current.leadingTrivia.indentation
    }
}

// MARK: - Configuration

package struct IndentSwitchCasesConfiguration: SyntaxRuleValue {
    package enum Style: String, Codable, Sendable {
        /// Case labels align with the `switch` keyword.
        case flush
        /// Case labels are indented one level beneath it.
        case indented
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// `flush` aligns case labels with the `switch` keyword; `indented` indents them one level
    /// beneath it.
    package var style: Style = .flush

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        style = try container.decodeIfPresent(Style.self, forKey: .style) ?? .flush
    }
}

fileprivate extension Finding.Message {
    static let alignCaseWithSwitch: Finding.Message = "align 'case' with 'switch' keyword"
    static let indentCaseFromSwitch: Finding.Message =
        "indent 'case' one level from 'switch' keyword"
}
