import SwiftSyntax

/// Enforce switch case label indentation style.
///
/// Two styles are supported via `SwitchCaseIndentationConfiguration.Style`:
/// - `flush`: `case` labels align with the `switch` keyword (default).
/// - `indented`: `case` labels are indented one level from `switch`.
///
/// Lint: Raised when a `case` or `default` label doesn't match the configured style.
///
/// Format: Case labels, bodies, and the closing brace are reindented to match.
final class SwitchCaseIndentation: SyntaxFormatRule {
    static let group: ConfigGroup? = .indentation

    static let isOptIn = true

    private var style: SwitchCaseIndentationConfiguration.Style {
        context.configuration.switchCaseIndentation.style
    }

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard var switchExpr = visited.as(SwitchExprSyntax.self) else { return visited }

        let switchIndent = lineIndentation(of: switchExpr.switchKeyword)
        let indent = indentUnit(from: switchExpr)

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
        guard !cases.isEmpty else { return visited }

        var modifiedCases = cases
        var modified = false

        for i in 0..<cases.count {
            switch cases[i] {
            case .switchCase(var switchCase):
                let currentCaseIndent = switchCase.leadingTrivia.indentation

                if currentCaseIndent != expectedCaseIndent {
                    let message: Finding.Message = style == .flush
                        ? .alignCaseWithSwitch : .indentCaseFromSwitch
                    diagnose(message, on: switchCase.label)
                    switchCase = reindentCase(
                        switchCase,
                        caseIndent: expectedCaseIndent,
                        bodyIndent: expectedBodyIndent
                    )
                    modifiedCases[i] = .switchCase(switchCase)
                    modified = true
                }

            case .ifConfigDecl:
                break
            }
        }

        if modified {
            switchExpr.cases = SwitchCaseListSyntax(modifiedCases)
        }

        // Closing brace should align with switch keyword.
        let braceIndent = switchExpr.rightBrace.leadingTrivia.indentation
        if braceIndent != switchIndent {
            switchExpr.rightBrace = reindentToken(
                switchExpr.rightBrace,
                to: switchIndent
            )
            modified = true
        }

        return modified ? ExprSyntax(switchExpr) : visited
    }

    // MARK: - Helpers

    /// Reindent a case label and all its body statements.
    private func reindentCase(
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
            modifiedStmts[j] = stmt.with(
                \.leadingTrivia,
                replaceIndentation(in: stmt.leadingTrivia, with: bodyIndent)
            )
        }
        result.statements = CodeBlockItemListSyntax(modifiedStmts)

        return result
    }

    /// Replace the indentation (spaces/tabs after the last newline) in trivia.
    private func replaceIndentation(in trivia: Trivia, with indent: String) -> Trivia {
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
                case .spaces, .tabs:
                    pieces.remove(at: afterNewline)
                default:
                    break
                }
                if afterNewline < pieces.count {
                    switch pieces[afterNewline] {
                    case .spaces, .tabs: continue
                    default: break
                    }
                }
                break
            }
            if !indent.isEmpty {
                pieces.insert(.spaces(indent.count), at: afterNewline)
            }
        }

        return Trivia(pieces: pieces)
    }

    /// Reindent a single token's leading trivia.
    private func reindentToken(_ token: TokenSyntax, to indent: String) -> TokenSyntax {
        token.with(\.leadingTrivia, replaceIndentation(in: token.leadingTrivia, with: indent))
    }

    /// Determine the single indent unit from the context configuration.
    private func indentUnit(from switchExpr: SwitchExprSyntax) -> String {
        // Use the configured indentation (e.g. 2 spaces, 4 spaces, tab).
        switch context.configuration.indentation {
        case .spaces(let count): return String(repeating: " ", count: count)
        case .tabs(let count): return String(repeating: "\t", count: count)
        }
    }

    /// Returns the indentation string of the line on which `token` resides.
    private func lineIndentation(of token: TokenSyntax) -> String {
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

public struct SwitchCaseIndentationConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
    package static let configProperties: [ConfigProperty] = [
        .init(
            "style",
            .stringEnum(
                description: "How case labels are indented relative to switch: flush (aligned) or indented (one level deeper).",
                values: ["flush", "indented"],
                defaultValue: "flush"
            )
        )
    ]

    public enum Style: String, Codable, Sendable {
        /// Case labels align with the `switch` keyword.
        case flush
        /// Case labels are indented one level from the `switch` keyword.
        case indented
    }

    public var style: Style = .flush

    public init() {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.style = try container.decodeIfPresent(Style.self, forKey: .style) ?? .flush
    }
}

extension Finding.Message {
    fileprivate static let alignCaseWithSwitch: Finding.Message =
        "align 'case' with 'switch' keyword"
    fileprivate static let indentCaseFromSwitch: Finding.Message =
        "indent 'case' one level from 'switch' keyword"
}
